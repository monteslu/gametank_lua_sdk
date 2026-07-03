#!/usr/bin/env node
// combo-pool banked build driver.
//
// Why this exists (see PORT_NOTES.md "SDK findings"): the port needs the
// 2 MB FLASH2M target (the game + 8 KB sheet outgrow the 32 KB cart), and
// it uses gt.note audio. bin/gtlua.js's banked path can't link audio games
// yet: gt_audio.c's 4 KB ACP firmware blob lands in the FIXED bank's
// RODATA, which overflows the 16 KB fixed window ("RODATA over by ~2881").
// The workaround: compile gt_audio.c with the firmware include wrapped in
// #pragma rodata-name("SHEET") so the blob rides in bank 2 next to the
// sprite sheet. main() calls gt_sheet_init() (which selects bank 2) right
// before gt_audio_init(), so the firmware is mapped in exactly when the
// one-time upload runs. Everything else mirrors bin/gtlua.js.
//
//   node ports/combo-pool/build.mjs
//
// Once the SDK's banked build handles audio, delete this file and use:
//   node bin/gtlua.js build ports/combo-pool/main.lua \
//     --sheet carts/combo-pool-extract/gfx.bin

import { spawnSync } from "node:child_process";
import { existsSync, mkdirSync, readFileSync, writeFileSync, statSync } from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const HERE = path.dirname(fileURLToPath(import.meta.url));
const REPO = path.dirname(path.dirname(HERE));
const SDK = path.join(REPO, "sdk");
const ENTRY = path.join(HERE, "main.lua");
const SHEET = path.join(REPO, "carts", "combo-pool-extract", "gfx.bin");

const { compile, formatDiagnostics } = await import(REPO + "/compiler/index.js");

const BANK_SIZE = 0x4000;
const FLASH_SIZE = 0x200000;

// hand placement: update+physics+audio in bank 0, all drawing in bank 1,
// init/bake + menus' draw in bank 2 (with the sheet + ACP firmware).
// Cross-bank edges (rare, cold): main->callbacks via gt_bank, stubs for
// _init->reset_game, update_game->reset_game restart, menu draw calls.
const PLACEMENT = {
  _update: "b0",
  update_mainmenu: "b1",
  update_intromenu: "b0",
  update_game: "b0",
  update_audio: "b0",
  playfx: "b0",
  update_grid: "b0",
  col_balls: "b0",
  do_coll: "b0",
  bomb: "b0",
  new_ball: "b0",
  new_part: "b0",
  new_text: "b0",
  reset_game: "b0",

  _draw: "b1",
  draw_game: "b1",
  draw_panel: "b1",
  draw_dbar: "b1",
  draw_boldline: "b1",
  print_score: "b1",
  draw_ball_spr: "b1",
  draw_ball_blink: "b1",
  draw_ball_plain: "b1",

  _init: "b2",
  bake_sprites: "b2",
  bake_ball_at: "b2",
  bake_circfill: "b2",
  bake_span: "b2",
  draw_mainmenu: "b1",
  draw_intromenu: "b1",
};

function fail(msg) { console.error(msg); process.exit(1); }

function run(cmd, args) {
  const r = spawnSync(cmd, args, { encoding: "utf8" });
  if (r.error) fail(`${cmd}: ${r.error.message}`);
  if (r.status !== 0) {
    if (r.stdout) process.stderr.write(r.stdout);
    if (r.stderr) process.stderr.write(r.stderr);
    fail(`${path.basename(cmd)} failed (exit ${r.status})`);
  }
  if (r.stderr) process.stderr.write(r.stderr);
  return r;
}

const tcHome = process.env.GTLUA_CC65_HOME ?? path.join(REPO, "tools", "cc65");
const tc = {
  cc65: path.join(tcHome, "bin", "cc65"),
  ca65: path.join(tcHome, "bin", "ca65"),
  ld65: path.join(tcHome, "bin", "ld65"),
  lib: path.join(tcHome, "lib", "none.lib"),
  asminc: path.join(tcHome, "asminc"),
};
if (!existsSync(tc.cc65)) fail("cc65 not found — run scripts/install_tools.sh");

const buildDir = path.join(HERE, "build");
mkdirSync(buildDir, { recursive: true });
const B = (f) => path.join(buildDir, f);

// 1. lua -> banked C + far-call stubs
const source = readFileSync(ENTRY, "utf8");
const result = compile(source, "main.lua", { banked: true, placement: PLACEMENT });
const warnings = result.diagnostics.filter((d) => d.severity === "warning");
if (warnings.length) console.error(formatDiagnostics(warnings));
if (!result.ok) {
  console.error(formatDiagnostics(result.diagnostics.filter((d) => d.severity === "error")));
  process.exit(1);
}
for (const name of Object.keys(PLACEMENT)) {
  if (!result.callGraph.has(name)) console.error(`placement: no function '${name}' (stale entry?)`);
}
// cc65 defers the string-literal pool to the END of the translation unit,
// AFTER emit.js's #pragma rodata-name pops — so every print() literal
// lands in the fixed bank's RODATA and overflows it. All of this port's
// literals belong to bank-1 (draw) functions, so park the tail pool there.
// (Compiler-integration bug, documented in PORT_NOTES.md.)
writeFileSync(B("main.c"), result.c + '\n#pragma rodata-name ("B1RODATA")\n');
writeFileSync(B("stubs.s"), (result.stubs ?? "; no cross-bank calls\n") + "\n");

// 2. sheet in bank 2 (same shape bin/gtlua.js generates for banked builds).
//
// Perf prep (measured ~2.9K cycles PER spr/blit call — batching is the only
// way to afford the static art): compose multi-cell STRIPS into the blank
// bottom rows of the sheet so the border/lattice/panels each draw with ONE
// wide spr() instead of dozens of calls:
//   row 12 (cells 192-207): bottom border row  [35, 34 x14, 36]
//   row 13 (cells 208-223): top border row     [19, 18 x14, 20]
//   row 14 (cells 224-239): field/weave row A  [17, 1 2 1 2 ..., 33]
//   row 15 (cells 240-255): field/weave row B  [17, 2 1 2 1 ..., 33]
//   rows 4-5 cols 4-10 (base cell 68): the 56x16 HUD panel (corners 66/67/
//   82/83 + the 4px sspr edge strips doubled into full cells)
const raw = readFileSync(SHEET);
if (raw.length !== 8192) fail(`sheet must be 8192 bytes, got ${raw.length}`);

function copyCell(dstCx, dstCy, srcCx, srcCy) {
  for (let y = 0; y < 8; y++) {
    for (let b = 0; b < 4; b++) {
      raw[(dstCy * 8 + y) * 64 + dstCx * 4 + b] = raw[(srcCy * 8 + y) * 64 + srcCx * 4 + b];
    }
  }
}
const cellOf = (tile) => [tile % 16, tile >> 4];
function layRow(dstCy, left, mid, right, altMid) {
  copyCell(0, dstCy, ...cellOf(left));
  for (let c = 1; c <= 14; c++) {
    const t = (altMid !== undefined && c % 2 === 0) ? altMid : mid;
    copyCell(c, dstCy, ...cellOf(t));
  }
  copyCell(15, dstCy, ...cellOf(right));
}
layRow(12, 0x23, 0x22, 0x24);          // bottom border
layRow(13, 0x13, 0x12, 0x14);          // top border
layRow(14, 0x11, 0x01, 0x21, 0x02);    // field row A: 17,[1,2,...],33
layRow(15, 0x11, 0x02, 0x21, 0x01);    // field row B: 17,[2,1,...],33

// HUD panel image at rows 4-5, cols 4-10 (56x16, drawn as spr(68,x,y,7,2))
copyCell(4, 4, ...cellOf(66));
copyCell(10, 4, ...cellOf(67));
copyCell(4, 5, ...cellOf(82));
copyCell(10, 5, ...cellOf(83));
// edge cells: the cart sspr-stretches 4px strips at (24,32) top / (24,40)
// bottom — double them into 8px cells
for (let c = 5; c <= 9; c++) {
  for (let y = 0; y < 8; y++) {
    const topSrc = (32 + y) * 64 + 12;   // px x=24..27 -> 2 bytes
    const botSrc = (40 + y) * 64 + 12;
    for (let half = 0; half < 2; half++) {
      raw[(4 * 8 + y) * 64 + c * 4 + half * 2] = raw[topSrc];
      raw[(4 * 8 + y) * 64 + c * 4 + half * 2 + 1] = raw[topSrc + 1];
      raw[(5 * 8 + y) * 64 + c * 4 + half * 2] = raw[botSrc];
      raw[(5 * 8 + y) * 64 + c * 4 + half * 2 + 1] = raw[botSrc + 1];
    }
  }
}

writeFileSync(B("sheet.c"),
  `#include "gt_api.h"\n` +
  `#pragma rodata-name ("SHEET")\n` +
  `static const unsigned char sheet_data[8192] = {${Array.from(raw).join(",")}};\n` +
  `#pragma rodata-name ("RODATA")\n` +
  `void gt_sheet_init(void) { gt_bank(2); gt_sheet_load(sheet_data); }\n`);

// 3. gt_audio with the firmware blob banked into bank 2 (build-time text
// transform of the unmodified sdk source; pitch_table stays in fixed RODATA
// because gt_note() reads it at runtime from any bank)
const audioSrc = readFileSync(path.join(SDK, "gt_audio.c"), "utf8");
const marker = '#include "gt_acp_fw.h"';
if (!audioSrc.includes(marker)) fail("sdk/gt_audio.c layout changed — update build.mjs");
writeFileSync(B("gt_audio_b2.c"), audioSrc.replace(marker,
  `#pragma rodata-name (push, "SHEET")\n${marker}\n#pragma rodata-name (pop)`));

// 4. compile + assemble
const CFLAGS = ["-t", "none", "-Osr", "--cpu", "65c02", "--codesize", "500",
                "--static-locals", "-I", SDK];
const AFLAGS = ["--cpu", "W65C02"];
if (existsSync(tc.asminc)) AFLAGS.push("-I", tc.asminc);
const cc = (src, dst) => run(tc.cc65, [...CFLAGS, "-o", dst, src]);
const objs = [];
const as = (src, obj) => { run(tc.ca65, [...AFLAGS, "-o", obj, src]); objs.push(obj); };

cc(B("main.c"), B("main.s"));
cc(path.join(SDK, "gt_api.c"), B("gt_api.s"));
cc(path.join(SDK, "gt_fixed.c"), B("gt_fixed.s"));
cc(path.join(SDK, "gt_math.c"), B("gt_math.s"));
cc(B("gt_audio_b2.c"), B("gt_audio.s"));
cc(B("sheet.c"), B("sheet.s"));

as(path.join(SDK, "crt0.s"), B("crt0.o"));
as(path.join(SDK, "vectors.s"), B("vectors.o"));
as(path.join(SDK, "interrupt.s"), B("interrupt.o"));
as(path.join(SDK, "gt_bank.s"), B("gt_bank.o"));
as(B("gt_api.s"), B("gt_api.o"));
as(B("gt_fixed.s"), B("gt_fixed.o"));
as(B("gt_math.s"), B("gt_math.o"));
as(B("gt_audio.s"), B("gt_audio.o"));
as(B("sheet.s"), B("sheet.o"));
as(B("stubs.s"), B("stubs.o"));
as(B("main.s"), B("main.o"));

// 5. link the four 16 KB pieces, then lay them into the 2 MB flash image
run(tc.ld65, [
  "-C", path.join(SDK, "gametank_flash2m.cfg"),
  "-o", B("main.banks"),
  "-m", B("main.map"),
  "-Ln", B("main.lbl"),
  ...objs,
  tc.lib,
]);

const pieces = readFileSync(B("main.banks"));
if (pieces.length !== 4 * BANK_SIZE) fail(`unexpected link output size ${pieces.length}`);
const img = Buffer.alloc(FLASH_SIZE, 0xff);
img.set(pieces.subarray(0 * BANK_SIZE, 1 * BANK_SIZE), 0x000000);
img.set(pieces.subarray(1 * BANK_SIZE, 2 * BANK_SIZE), 0x004000);
img.set(pieces.subarray(2 * BANK_SIZE, 3 * BANK_SIZE), 0x008000);
img.set(pieces.subarray(3 * BANK_SIZE, 4 * BANK_SIZE), FLASH_SIZE - BANK_SIZE);
const gtr = path.join(HERE, "main.gtr");
writeFileSync(gtr, img);
console.log(`${gtr} (${statSync(gtr).size} bytes, FLASH2M)`);
