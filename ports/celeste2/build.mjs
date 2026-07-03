#!/usr/bin/env node
// celeste2 FLASH2M build driver.
//
// The stock `bin/gtlua.js` re-targets a 2 MB FLASH2M cart automatically, but
// its bank solver seeds the whole _update-reachable subgraph into bank 0 and
// then nudges a few large functions out on overflow. Celeste 2's update path
// is ~25 KB — larger than one 16 KB bank — so that seed never converges.
//
// This driver reuses gtlua's compiler + the cc65 toolchain but replaces the
// placement solver with a greedy bin-packer that balances all four bins
// (b0/b1/b2/fixed) by measured function size, honouring:
//   * the sprite sheet (8 KB) pinned to BANK2,
//   * the fixed bank's ~12 KB runtime reservation,
//   * callbacks staying in a code bank (main() selects the bank first).
//
// It is deliberately scoped to ports/celeste2 (my ownership boundary); it does
// NOT modify the SDK or gtlua.js. The convergence gap it exposes when a slice
// is too big is reported honestly and drives the --levels slice size.
//
// Usage: node ports/celeste2/build.mjs [-o out.gtr] [--sheet sheet.bin]
//                                      [--levels N]   (info only; run gen.mjs)

import { spawnSync } from "node:child_process";
import { existsSync, mkdirSync, readFileSync, writeFileSync, statSync } from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { compile, formatDiagnostics } from "../../compiler/index.js";

const HERE = path.dirname(fileURLToPath(import.meta.url));
const REPO = path.resolve(HERE, "..", "..");
const SDK = path.join(REPO, "sdk");
const BANK_SIZE = 0x4000;
const FLASH_SIZE = 0x200000;
const BANK_MARGIN = 320;

function fail(m) { console.error(m); process.exit(1); }

function findToolchain() {
  const home = process.env.GTLUA_CC65_HOME || path.join(REPO, "tools", "cc65");
  if (existsSync(path.join(home, "bin", "cc65"))) {
    return {
      cc65: path.join(home, "bin", "cc65"),
      ca65: path.join(home, "bin", "ca65"),
      ld65: path.join(home, "bin", "ld65"),
      lib: path.join(home, "lib", "none.lib"),
      asminc: path.join(home, "asminc"),
    };
  }
  fail("cc65 not found under tools/cc65 (run scripts/install_tools.sh)");
}

function run(cmd, args) {
  const r = spawnSync(cmd, args, { encoding: "utf8" });
  if (r.error) fail(`${cmd}: ${r.error.message}`);
  if (r.status !== 0) {
    process.stderr.write((r.stdout || "") + (r.stderr || ""));
    fail(`${path.basename(cmd)} failed (exit ${r.status})`);
  }
  if (r.stderr) process.stderr.write(r.stderr);
  return r;
}

function runLink(cmd, args) {
  const r = spawnSync(cmd, args, { encoding: "utf8" });
  if (r.error) fail(`${cmd}: ${r.error.message}`);
  const text = `${r.stdout ?? ""}${r.stderr ?? ""}`;
  if (r.status === 0) return { ok: true, overflows: [], text };
  const overflows = [];
  const re = /Segment '?‘?([A-Z0-9]+)'?’? overflows memory area '?‘?\w+'?’? by (\d+) bytes/g;
  let m;
  while ((m = re.exec(text)) !== null) overflows.push({ segment: m[1], bytes: Number(m[2]) });
  if (!overflows.length) { process.stderr.write(text); fail(`${path.basename(cmd)} failed (exit ${r.status})`); }
  return { ok: false, overflows, text };
}

function compileLua(entry, opts = {}) {
  const source = readFileSync(entry, "utf8");
  const result = compile(source, path.basename(entry), opts);
  const warns = result.diagnostics.filter((d) => d.severity === "warning");
  if (warns.length) console.error(formatDiagnostics(warns));
  if (!result.ok) {
    console.error(formatDiagnostics(result.diagnostics.filter((d) => d.severity === "error")));
    process.exit(1);
  }
  return result;
}

// exact per-function byte size from a linked .map (Size= per segment chunk is
// per-object, not per-function; we instead measure from the .s proc bodies,
// same heuristic gtlua uses but tuned: ~2.05 bytes per non-comment line).
function functionSizes(sPath) {
  const sizes = new Map();
  let name = null, count = 0;
  for (const ln of readFileSync(sPath, "utf8").split("\n")) {
    const m = ln.match(/^\.proc\s+_gtl_(\w+)/);
    if (m) { name = m[1]; count = 0; continue; }
    if (ln.startsWith(".endproc")) { if (name) sizes.set(name, Math.round(count * 2.05)); name = null; continue; }
    if (name && ln.trim() && !ln.startsWith(";")) count++;
  }
  return sizes;
}

function makeSheetC(sheetPath) {
  if (!sheetPath) return `void gt_sheet_init(void) {}\n`;
  const raw = readFileSync(sheetPath);
  if (raw.length !== 8192) fail(`--sheet expects 8192 bytes (got ${raw.length})`);
  return `#include "gt_api.h"\n#pragma rodata-name ("SHEET")\n` +
    `static const unsigned char sheet_data[8192] = {${Array.from(raw).join(",")}};\n` +
    `#pragma rodata-name ("RODATA")\n` +
    `void gt_sheet_init(void) { gt_bank(2); gt_sheet_load(sheet_data); }\n`;
}

// ---- greedy placement -------------------------------------------------------
// Callbacks are pinned to a code bank (never fixed). Everything else is packed
// largest-first into the emptiest eligible bin. Fixed gets only functions that
// are hot on BOTH the update and draw paths (calling them cross-bank would
// double-stub a hot leaf) up to its small reservation.
const CALLBACKS = new Set(["_update", "_update60", "_draw", "_init"]);

function reachable(cg, roots) {
  const seen = new Set(), st = roots.filter((r) => cg.has(r));
  while (st.length) { const n = st.pop(); if (seen.has(n)) continue; seen.add(n); for (const c of cg.get(n) ?? []) st.push(c); }
  return seen;
}

function place(callGraph, sizes, sheetBytes, fixedReserve, capAdjust = {}) {
  const names = [...callGraph.keys()];
  const cap = {
    b0: BANK_SIZE - BANK_MARGIN - (capAdjust.b0 ?? 0),
    b1: BANK_SIZE - BANK_MARGIN - (capAdjust.b1 ?? 0),
    b2: BANK_SIZE - BANK_MARGIN - sheetBytes - (capAdjust.b2 ?? 0),
    fixed: fixedReserve,
  };
  const used = { b0: 0, b1: 0, b2: 0, fixed: 0 };
  const placement = {};

  // undirected neighbour map (caller<->callee) — co-locating neighbours in one
  // bank removes a cross-bank stub, and each stub is ~40 bytes of FIXED-bank
  // code. Minimising stubs is what keeps the SDK runtime + stubs under 16 KB.
  const nbr = new Map(names.map((n) => [n, new Map()]));
  for (const [a, cs] of callGraph) {
    for (const b of cs) {
      if (!nbr.has(a) || !nbr.has(b)) continue;
      nbr.get(a).set(b, (nbr.get(a).get(b) ?? 0) + 1);
      nbr.get(b).set(a, (nbr.get(b).get(a) ?? 0) + 1);
    }
  }

  // callbacks pinned: update path -> b0, draw/init path -> b1 (main() sets the
  // bank before invoking the callback, so a callback must be IN a code bank).
  const pin = { _update: "b0", _update60: "b0", _draw: "b1", _init: "b1" };
  for (const [cb, bin] of Object.entries(pin)) {
    if (callGraph.has(cb)) { placement[cb] = bin; used[bin] += sizes.get(cb) ?? 0; }
  }

  // Fixed-bank leaf pinning. A far-call stub is ~STUB_BYTES of FIXED-bank code.
  // A leaf (calls nothing) reached from callers that end up in K distinct banks
  // pays (K) stubs if it lives in a bank, or ZERO if it lives in the fixed bank
  // (which every bank can call directly). So pin a leaf to fixed when it is hot
  // across banks and small enough that (stubs saved * STUB_BYTES) > its size —
  // this strictly SHRINKS the fixed bank, buying headroom against SDK drift.
  // Use the update-vs-draw reachability split as the bank proxy (matches the
  // callback pinning): a leaf reached from BOTH paths would stub on one side.
  const STUB_BYTES = 40;
  const Aset = reachable(callGraph, ["_update", "_update60"]);
  const Dset = reachable(callGraph, ["_draw", "_init"]);
  const callerCount = new Map(names.map((n) => [n, 0]));
  for (const [, cs] of callGraph) for (const c of cs) if (callerCount.has(c)) callerCount.set(c, callerCount.get(c) + 1);
  for (const n of names) {
    if (n in placement) continue;
    if ((callGraph.get(n)?.size ?? 0) !== 0) continue;      // leaves only
    const bothPaths = Aset.has(n) && Dset.has(n);
    const callers = callerCount.get(n) ?? 0;
    // stubs avoided ~ min(callers, bothPaths?2:1) — a both-path leaf always
    // stubs on one side; a many-caller leaf stubs from each foreign bank.
    const stubsAvoided = bothPaths ? 2 : (callers >= 3 ? 1 : 0);
    const size = sizes.get(n) ?? 0;
    // strict: pin only when it clearly SHRINKS fixed. A both-path leaf ALWAYS
    // stubs on one side, so pinning removes that stub AND its second banked
    // copy — net win when the leaf is smaller than the stub it deletes.
    if (stubsAvoided >= 2 && size <= STUB_BYTES) {
      placement[n] = "fixed"; used.fixed += size;
    }
  }

  // Affinity: co-locate the one-shot LOAD/RESTART chain in ONE bank so its many
  // internal edges don't each burn a fixed-bank stub. This is the cold, run-once
  // level-setup path (load_level -> ld_dat/lz_unpack/load_meta -> restart_level
  // -> clear_pools + the *_add spawners + p_spawn; fl_data -> fr). Prefer b2 (the
  // sheet-shared bank) — its spare room is otherwise hard to use, and keeping the
  // whole chain together turns ~8 fixed-bank stubs into intra-bank calls.
  const LOADER = names.filter((n) =>
    /^(ld_dat|d16|d1|lz_unpack|fl_data|fr|load_meta|load_level|restart_level|clear_pools|p_spawn|hold_add|crumb_add|berry_add|bridge_add|spawn_add)$/.test(n)
    || /^ld_dat_\d+$/.test(n));
  const loaderSize = LOADER.reduce((a, n) => a + (sizes.get(n) ?? 0), 0);
  const lb = ["b2", "b1", "b0"].find((b) => used[b] + loaderSize <= cap[b]);
  if (lb) for (const n of LOADER) { placement[n] = lb; used[lb] += sizes.get(n) ?? 0; }

  // BFS order from the callbacks so each function is considered right after its
  // caller — then place it in the bank holding the most of its already-placed
  // neighbours (fewest new stubs), breaking ties toward the emptiest bank.
  const order = [];
  const seen = new Set(Object.keys(placement));
  const q = ["_update", "_update60", "_draw", "_init"].filter((c) => callGraph.has(c));
  while (q.length) {
    const n = q.shift();
    for (const c of callGraph.get(n) ?? []) {
      if (!seen.has(c)) { seen.add(c); order.push(c); q.push(c); }
    }
  }
  for (const n of names) if (!seen.has(n)) order.push(n); // unreachable leftovers

  // callers map: who calls n (to detect single-caller functions).
  const callers = new Map(names.map((n) => [n, new Set()]));
  for (const [a, cs] of callGraph) for (const b of cs) if (callers.has(b)) callers.get(b).add(a);

  for (const n of order) {
    if (n in placement) continue;
    const s = sizes.get(n) ?? 0;
    const fits = ["b0", "b1", "b2"].filter((b) => used[b] + s <= cap[b]);
    let target;
    if (fits.length) {
      // score each fitting bank by neighbour weight already there; tie-break by
      // emptiness (prefer the bank with more free room so we don't wedge b2).
      const score = (b) => {
        let w = 0;
        for (const [m, cnt] of nbr.get(n)) if (placement[m] === b) w += cnt;
        return w;
      };
      // single-caller affinity: a function reached from exactly one placed
      // caller pays a stub ONLY on that edge — co-locating it removes the stub
      // outright. Prefer the caller's bank whenever it fits.
      const solo = [...callers.get(n)].filter((c) => placement[c]);
      const soloBank = (callers.get(n).size === 1 && solo.length === 1) ? placement[solo[0]] : null;
      if (soloBank && fits.includes(soloBank)) {
        target = soloBank;
      } else {
        target = fits.sort((x, y) => (score(y) - score(x)) || ((cap[y] - used[y]) - (cap[x] - used[x])))[0];
      }
    } else if (used.fixed + s <= cap.fixed) {
      target = "fixed";
    } else {
      target = ["b0", "b1"].sort((x, y) => used[x] - used[y])[0]; // honest spill
    }
    placement[n] = target; used[target] += s;
  }

  // final rebalance: if a code bank is over its (feedback-adjusted) capacity,
  // shove its SMALL leaf functions into whichever bank still has room (b2 the
  // scarce bank first, so the 16 KB banks keep their headroom). Small leaves
  // add at most one stub each and close tiny (~100 B) overflows cleanly.
  const CB = new Set(Object.keys(pin));
  for (const src of ["b1", "b0", "b2"]) {
    let iter = 0;
    while (used[src] > cap[src] && iter++ < 64) {
      const movable = names
        .filter((n) => placement[n] === src && !CB.has(n))
        .sort((a, b) => (sizes.get(a) ?? 0) - (sizes.get(b) ?? 0));
      let moved = false;
      for (const n of movable) {
        const s = sizes.get(n) ?? 0;
        const dst = ["b2", "b0", "b1"].find((b) => b !== src && used[b] + s <= cap[b]);
        if (dst) { placement[n] = dst; used[dst] += s; used[src] -= s; moved = true; break; }
      }
      if (!moved) break;
    }
  }

  // Stub-minimization pass. A cross-bank call edge (caller bank != callee bank)
  // costs one ~STUB_BYTES trampoline in the FIXED bank — the scarce resource
  // when the SDK runtime grows. Count each non-callback function's distinct
  // "foreign banks" (banks it calls into OR is called from that differ from its
  // own); moving it to the bank it interacts with MOST kills those edges. Greedy
  // hill-climb until no move reduces the total edge count (bounded iterations).
  const CBs = new Set(Object.keys(pin));
  const distinctForeign = (n, bank) => {
    const banksTouched = new Set();
    for (const [m] of nbr.get(n)) if (placement[m] && placement[m] !== bank) banksTouched.add(placement[m]);
    return banksTouched.size;
  };
  for (let pass = 0; pass < 40; pass++) {
    let improved = false;
    // process biggest-edge functions first
    const cand = names
      .filter((n) => !CBs.has(n) && placement[n] !== "fixed")
      .sort((a, b) => distinctForeign(b, placement[b]) - distinctForeign(a, placement[a]));
    for (const n of cand) {
      const s = sizes.get(n) ?? 0;
      const cur = placement[n];
      const curEdges = distinctForeign(n, cur);
      if (curEdges === 0) continue;
      let best = cur, bestEdges = curEdges;
      for (const b of ["b0", "b1", "b2"]) {
        if (b === cur) continue;
        if (used[b] + s > cap[b]) continue;             // must fit
        const e = distinctForeign(n, b);
        if (e < bestEdges) { best = b; bestEdges = e; }
      }
      if (best !== cur) {
        used[cur] -= s; used[best] += s; placement[n] = best; improved = true;
      }
    }
    if (!improved) break;
  }
  return { placement, used, cap };
}

// ---- build ------------------------------------------------------------------
const args = process.argv.slice(2);
const oIdx = args.indexOf("-o");
const outPath = oIdx !== -1 ? args[oIdx + 1] : path.join(HERE, "main.gtr");
const sIdx = args.indexOf("--sheet");
const sheetPath = sIdx !== -1 ? args[sIdx + 1] : path.join(HERE, "sheet.bin");
const entry = path.join(HERE, "main.lua");

const tc = findToolchain();
const buildDir = path.join(HERE, "build");
mkdirSync(buildDir, { recursive: true });
const B = (f) => path.join(buildDir, f);
const CFLAGS = ["-t", "none", "-Osr", "--cpu", "65c02", "--codesize", "500", "--static-locals", "-I", SDK];
const AFLAGS = ["--cpu", "W65C02"];
if (tc.asminc && existsSync(tc.asminc)) AFLAGS.push("-I", tc.asminc);
const cc = (src, dst) => run(tc.cc65, [...CFLAGS, "-o", dst, src]);
const as = (src, obj) => run(tc.ca65, [...AFLAGS, "-o", obj, src]);
const name = "main";

// flat compile once to measure sizes + detect audio
let result = compileLua(entry);
const usesAudio = result.c.includes("gt_audio_init(");
writeFileSync(B(`${name}.c`), result.c);
cc(B(`${name}.c`), B(`${name}.s`));
const sizes = functionSizes(B(`${name}.s`));
const totalCode = [...sizes.values()].reduce((a, b) => a + b, 0);
console.log(`game code ~${totalCode} bytes across ${sizes.size} functions`);

// shared SDK objects
cc(path.join(SDK, "gt_api.c"), B("gt_api.s"));
cc(path.join(SDK, "gt_fixed.c"), B("gt_fixed.s"));
cc(path.join(SDK, "gt_math.c"), B("gt_math.s"));
if (usesAudio) cc(path.join(SDK, "gt_audio.c"), B("gt_audio.s"));
writeFileSync(B("sheet.c"), makeSheetC(sheetPath));
cc(B("sheet.c"), B("sheet.s"));
as(path.join(SDK, "crt0.s"), B("crt0.o"));
as(path.join(SDK, "vectors.s"), B("vectors.o"));
as(path.join(SDK, "interrupt.s"), B("interrupt.o"));
as(path.join(SDK, "gt_bank.s"), B("gt_bank.o"));
as(B("gt_api.s"), B("gt_api.o"));
as(B("gt_fixed.s"), B("gt_fixed.o"));
as(B("gt_math.s"), B("gt_math.o"));
if (usesAudio) as(B("gt_audio.s"), B("gt_audio.o"));
as(B("sheet.s"), B("sheet.o"));

const baseObjs = [
  B("crt0.o"), B("vectors.o"), B("interrupt.o"),
  B("gt_api.o"), B("gt_fixed.o"), B("gt_math.o"),
  ...(usesAudio ? [B("gt_audio.o")] : []),
  B("sheet.o"),
];

const sheetBytes = 8192;
// fixed-bank code reserve for game functions. The fixed bank holds crt0 +
// vectors + interrupt + gt_api/fixed/math (+audio) + stubs; measured headroom
// is ~2.5 KB. Start there and shrink if the fixed link overflows.
// Start the fixed game-code reserve LOW: any game function in the fixed bank
// drags its string literals into the (very tight) fixed RODATA. Keeping game
// code out of fixed keeps fixed RODATA at ~SDK-only size. The loop only ever
// shrinks this and grows capAdjust, so the search is monotone (no see-saw).
let fixedReserve = 0;   // only the pinned hot leaves live in fixed; see place()
const capAdjust = { b0: 0, b1: 0, b2: 0 };
let linked = null, lastPlacement = null, lastUsed = null;

for (let attempt = 0; attempt < 16; attempt++) {
  const { placement, used, cap } = place(result.callGraph, sizes, sheetBytes, fixedReserve, capAdjust);
  lastPlacement = placement; lastUsed = used;
  result = compileLua(entry, { banked: true, placement });
  writeFileSync(B(`${name}.c`), result.c);
  cc(B(`${name}.c`), B(`${name}.s`));
  as(B(`${name}.s`), B(`${name}.o`));
  writeFileSync(B("stubs.s"), (result.stubs ?? "; no cross-bank calls\n") + "\n");
  as(B("stubs.s"), B("stubs.o"));

  const flashOut = B(`${name}.banks`);
  const link = runLink(tc.ld65, [
    "-C", path.join(SDK, "gametank_flash2m.cfg"),
    "-o", flashOut, "-m", B(`${name}.map`), "-Ln", B(`${name}.lbl`),
    ...baseObjs, B("gt_bank.o"), B("stubs.o"), B(`${name}.o`), tc.lib,
  ]);
  if (link.ok) { linked = flashOut; break; }

  // react to the real overflow: shrink the offending bin's estimate so the
  // packer moves work elsewhere next round.
  const over = {};
  for (const o of link.overflows) over[o.segment] = (over[o.segment] ?? 0) + o.bytes;
  console.log(`attempt ${attempt}: ` +
    `b0=${used.b0} b1=${used.b1} b2=${used.b2} fixed=${used.fixed} ` +
    `overflow ${link.overflows.map((o) => `${o.segment}+${o.bytes}`).join(",")}`);
  // if fixed overflowed, cut its reserve; the packer will exile its game fns.
  if (over.CODE || over.RODATA) fixedReserve = Math.max(0, fixedReserve - (over.CODE ?? over.RODATA) - 200);
  // if a code bank overflowed, tighten that bank's estimated capacity by the
  // real miss (+64 slack) so the packer routes work off it next round.
  for (const seg of ["B0", "B1", "B2"]) {
    const miss = (over[`${seg}CODE`] ?? 0) + (over[`${seg}RODATA`] ?? 0);
    if (miss) capAdjust[seg.toLowerCase()] += miss + 64;
  }
  // if a code bank overflowed and there's genuinely no room, we can't converge.
  const codeOver = link.overflows.filter((o) => /^B[012]CODE|B[012]RODATA/.test(o.segment));
  if (codeOver.length && attempt >= 8) {
    const gap = codeOver.reduce((a, o) => a + o.bytes, 0);
    fail(`FLASH2M does not fit: code banks over by ~${gap} bytes.\n` +
      `game code ~${totalCode}B needs to drop below the 3-bank+fixed budget.\n` +
      `Reduce the slice: node ports/celeste2/gen/gen.mjs --levels N (fewer rooms).`);
  }
}
if (!linked) fail("FLASH2M bank placement did not converge in 10 attempts");

const pieces = readFileSync(linked);
if (pieces.length !== 4 * BANK_SIZE) fail(`unexpected banked link size ${pieces.length}`);
const img = Buffer.alloc(FLASH_SIZE, 0xff);
img.set(pieces.subarray(0 * BANK_SIZE, 1 * BANK_SIZE), 0x000000);
img.set(pieces.subarray(1 * BANK_SIZE, 2 * BANK_SIZE), 0x004000);
img.set(pieces.subarray(2 * BANK_SIZE, 3 * BANK_SIZE), 0x008000);
img.set(pieces.subarray(3 * BANK_SIZE, 4 * BANK_SIZE), FLASH_SIZE - BANK_SIZE);
writeFileSync(outPath, img);
writeFileSync(B("banks.json"), JSON.stringify(lastPlacement, null, 1));
const counts = { fixed: 0, b0: 0, b1: 0, b2: 0 };
for (const b of Object.values(lastPlacement)) counts[b]++;
console.log(`${outPath} (${statSync(outPath).size} bytes, FLASH2M; ` +
  `b0=${lastUsed.b0} b1=${lastUsed.b1} b2=${lastUsed.b2} fixed=${lastUsed.fixed}; ` +
  `functions fixed:${counts.fixed} b0:${counts.b0} b1:${counts.b1} b2:${counts.b2})`);
