// profile-cart.mjs - whole-game phase profiler on the GT_PROFILE core.
//
// Runs a FINISHED .gtr that the game has instrumented with gt.mark(1..N)
// phase markers, collects the marker ring, and reports the median cycle
// delta between consecutive marks (per phase id pair), plus per-frame
// totals. Complements the per-call microbench (run.mjs): this answers
// "where does MY game's frame go?".
//
//   node bench/profile-cart.mjs game.gtr [frames] [--labels a,b,c,...]
//
// Marks wrap per frame: mark(1) starts a frame's sequence; the delta from
// mark k to mark k+1 is phase k. The gap from the LAST mark back to the
// next frame's mark(1) is the tail (draw drain + vsync idle) and is
// reported separately.
import { readFileSync } from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const SDK = path.dirname(path.dirname(fileURLToPath(import.meta.url)));
const CORE = process.env.GT_BENCH_CORE ||
  path.join(SDK, "..", "gametank-libretro", "gametank_libretro_prof.js");
const MARK_ADDR = 0x1000;

const [cart, framesArg, ...rest] = process.argv.slice(2);
if (!cart) { console.error("usage: profile-cart.mjs game.gtr [frames] [--labels a,b,...]"); process.exit(1); }
const frames = parseInt(framesArg || "400", 10);
const li = rest.indexOf("--labels");
const labels = li !== -1 ? rest[li + 1].split(",") : [];

const MOD = (await import(CORE)).default;
const M = await MOD();
const envCb = M.addFunction((cmd) => {
  const id = (cmd >>> 0) & 0xff;
  return (id === 10 || id === 3 || id === 27) ? 1 : 0;
}, "iii");
M._retro_set_environment(envCb);
M._retro_set_video_refresh(M.addFunction(() => {}, "viiii"));
M._retro_set_input_poll(M.addFunction(() => {}, "v"));
M._retro_set_input_state(M.addFunction(() => 0, "iiiii"));
M._retro_set_audio_sample(M.addFunction(() => {}, "vii"));
M._retro_set_audio_sample_batch(M.addFunction((ptr, n) => n, "iii"));
M._retro_init();
M._gt_marker_config(MARK_ADDR);
const rom = readFileSync(cart);
const p = M._malloc(rom.length); M.HEAPU8.set(rom, p);
const info = M._malloc(16);
M.HEAP32[(info >> 2)] = 0; M.HEAP32[(info >> 2) + 1] = p;
M.HEAP32[(info >> 2) + 2] = rom.length; M.HEAP32[(info >> 2) + 3] = 0;
if (!M._retro_load_game(info)) throw new Error("load failed");
M._gt_marker_config(MARK_ADDR);
for (let i = 0; i < frames; i++) M._retro_run();

const n = M._gt_marker_count();
const marks = [];
for (let i = 0; i < n; i++) {
  const lo = M._gt_marker_cyc_lo(i) >>> 0, hi = M._gt_marker_cyc_hi(i) >>> 0;
  marks.push({ v: M._gt_marker_value(i), c: hi * 4294967296 + lo });
}
if (!marks.length) { console.error("no marks recorded - is the cart instrumented and the core GT_PROFILE?"); process.exit(1); }

const phases = new Map();   // "k->k+1" -> [deltas]
const totals = [];          // mark1 .. last-mark spans
const tails = [];           // last mark -> next mark1
let frameStart = null, prev = null;
for (const m of marks) {
  if (m.v === 1) {
    if (prev && frameStart != null) { totals.push(prev.c - frameStart.c); tails.push(m.c - prev.c); }
    frameStart = m;
  } else if (prev && m.v === prev.v + 1) {
    const key = `${prev.v}->${m.v}`;
    if (!phases.has(key)) phases.set(key, []);
    phases.get(key).push(m.c - prev.c);
  }
  prev = m;
}
const med = (a) => { const s = [...a].sort((x, y) => x - y); return s.length ? s[s.length >> 1] : 0; };
console.log(`marks: ${marks.length}, frames measured: ${totals.length}`);
let sum = 0;
for (const [key, ds] of [...phases.entries()].sort()) {
  const k = parseInt(key, 10);
  const name = labels[k - 1] ? ` ${labels[k - 1]}` : "";
  const m = med(ds);
  sum += m;
  console.log(`phase ${key}${name}: median ${m} cyc (n=${ds.length}, max ${Math.max(...ds)})`);
}
console.log(`sum of phase medians: ${sum} cyc (frame budget ~59660)`);
console.log(`measured span median: ${med(totals)} cyc; tail (drain+idle): ${med(tails)} cyc`);
