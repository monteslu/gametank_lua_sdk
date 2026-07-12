#!/usr/bin/env node
// celeste2 port data generator.
//
// Reads the extracted Celeste Classic 2 cart (carts/celeste2-extract/cart.bin,
// CC-BY-NC-SA 4.0 by ExOK - see ../LICENSE) and produces everything the
// single-file gtlua port needs:
//
//   1. px9-decompresses the 8 level maps (stored at cart offset 0x1000 +
//      level.offset - the same data the cart's own goto_level() decodes into
//      RAM at 0x4300), re-compresses each with a tiny LZSS whose window is
//      the decoded map itself (zero decoder RAM), and emits the byte streams
//      as gtlua `d16(...)` data-call code spliced into ../main.lua between
//      the GENERATED markers. Decoding happens in place: the stream is
//      staged in the tail of the map buffer and consumed just ahead of the
//      write pointer (this script simulates every level and refuses to emit
//      if the pointers would ever collide).
//   2. Extracts the sprite-flag table (cart 0x3000-0x307F, tiles 0-127) into
//      RLE fill calls.
//   3. Builds sheet.bin: the cart gfx top half (the real art) plus mirrored
//      copies of the sprites the game draws flipped, written into bottom-half
//      cells at (n + 128) - in the cart those rows hold the px9 level data,
//      i.e. they are free cells for a port. gtlua spr() has no flip args, so
//      flips become extra cells.
//   4. --debug: renders each level to gen/build-debug/levelN.pgm.
//
// Usage: node ports/celeste2/gen/gen.mjs [--debug]
import { readFileSync, writeFileSync, mkdirSync } from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const HERE = path.dirname(fileURLToPath(import.meta.url));
const REPO = path.resolve(HERE, "..", "..", "..");
const PORT = path.resolve(HERE, "..");
const cart = readFileSync(path.join(REPO, "carts", "celeste2-extract", "cart.bin"));
const DEBUG = process.argv.includes("--debug");

// --levels N  - emit only the first N level loaders (a build "slice"). The
// full cart has 8 rooms; the GameTank's 3-bank FLASH2M budget can only hold
// the game logic plus a few level loaders (each ld_dat_N is executable code,
// not RODATA - see PORT_NOTES.md), so ship the largest coherent slice.
const lvlArgIdx = process.argv.indexOf("--levels");
const SHIP = lvlArgIdx !== -1 ? Number(process.argv[lvlArgIdx + 1]) : 8;

// map = array(BUF_INTS), 2 tiles per int. Computed below from the SHIPPED
// levels: the buffer must hold the biggest decoded room at the front AND stage
// that room's LZ stream at the tail without the in-place decode colliding.
// Sizing it to the slice (not the full-game 2048) reclaims scarce work RAM -
// a 1-room slice (96x16 = 768 ints) needs far less than a 128x32 room (2048).
let BUF_INTS = 0;                // set after the levels are decoded
const FLIPPED = [2, 3, 4, 5, 36, 37]; // sprites drawn with flip in the cart

// level table (offsets/dims mirror the cart's `levels`)
const LEVELS = [
  { offset: 0,    w: 96,  h: 16 },
  { offset: 343,  w: 32,  h: 32 },
  { offset: 679,  w: 128, h: 22 },
  { offset: 1313, w: 128, h: 32 },
  { offset: 2411, w: 128, h: 16 },
  { offset: 2645, w: 128, h: 16 },
  { offset: 2880, w: 128, h: 16 },
  { offset: 3079, w: 16,  h: 62 },
].slice(0, SHIP);

// ---- px9 decompressor (zep's px9_decomp, integer re-implementation) --------
// The cart keeps a 16.16 bit cache with the next stream bit at the fraction
// LSB; integer-wise that's just "cache holds cacheBits bits, LSB first".
function px9Decode(src) {
  let pos = src, cache = 0, cacheBits = 0;
  const getval = (bits) => {
    if (cacheBits < 16) {
      cache += (cart[pos] | (cart[pos + 1] << 8)) * 2 ** cacheBits;
      cacheBits += 16;
      pos += 2;
    }
    const val = cache % 2 ** bits;
    cache = Math.floor(cache / 2 ** bits);
    cacheBits -= bits;
    return val;
  };
  const gnp = (n) => {
    let bits = 0, vv;
    do { bits += 1; vv = getval(bits); n += vv; } while (vv === 2 ** bits - 1);
    return n;
  };
  const mtf = (l, val) => { l.splice(l.indexOf(val), 1); l.unshift(val); };

  const w = gnp(1), h = gnp(0) + 1, eb = gnp(1);
  const el = [], pr = new Map(), n = gnp(1);
  for (let i = 0; i < n; i++) el.push(getval(eb));
  const out = [];
  let splen = 0, predict = false;
  for (let y = 0; y < h; y++) {
    for (let x = 0; x < w; x++) {
      splen -= 1;
      if (splen < 1) { splen = gnp(1); predict = !predict; }
      const a = y > 0 ? out[(y - 1) * w + x] : 0;
      let l = pr.get(a);
      if (!l) { l = [...el]; pr.set(a, l); }
      const v = predict ? l[0] : l[gnp(2) - 1];
      mtf(l, v); mtf(el, v);
      out.push(v);
    }
  }
  return { w, h, out };
}

// ---- LZSS re-encoder ---------------------------------------------------------
// Token stream (bytes): 0x00-0x7F literal tile; match = two bytes
// [1 dd lllll][dddddddd]: len = lllll+3 (3-34), dist = ddDDDDDDDD+1 (1-1024).
// The window is the decoded output itself, so the gtlua decoder needs no
// state beyond the map buffer.
function lzEncode(data) {
  const out = [];
  let p = 0;
  while (p < data.length) {
    let bestLen = 0, bestDist = 0;
    const maxD = Math.min(p, 1024);
    for (let d = 1; d <= maxD; d++) {
      let l = 0;
      while (p + l < data.length && data[p + l] === data[p + l - d] && l < 34) l++;
      if (l > bestLen) { bestLen = l; bestDist = d; }
    }
    if (bestLen >= 3) {
      const dm = bestDist - 1;
      out.push(0x80 | ((dm >> 8) << 5) | (bestLen - 3), dm & 0xff);
      p += bestLen;
    } else {
      if (data[p] > 0x7f) throw new Error(`tile ${data[p]} exceeds literal space`);
      out.push(data[p]);
      p += 1;
    }
  }
  return out;
}

function lzDecode(enc) {
  const dec = [];
  for (let j = 0; j < enc.length; ) {
    const t = enc[j];
    if (t & 0x80) {
      const len = (t & 0x1f) + 3;
      const d = ((((t >> 5) & 3) << 8) | enc[j + 1]) + 1;
      j += 2;
      for (let k = 0; k < len; k++) dec.push(dec[dec.length - d]);
    } else { dec.push(t); j++; }
  }
  return dec;
}

// exact simulation of the in-place decode: staging byte j lives in map int
// S + (j >> 1); the int holding the next UNREAD byte must always be strictly
// above the int last written. Token bytes are consumed before their output
// is written (the gtlua decoder does the same).
function overlapSafe(enc, S) {
  let p = 0, j = 0;
  while (j < enc.length) {
    const t = enc[j];
    j += (t & 0x80) ? 2 : 1;
    p += (t & 0x80) ? (t & 0x1f) + 3 : 1;
    if (S + (j >> 1) <= (p - 1) >> 1) return false;
  }
  return true;
}

// First pass: decode + LZ-encode every shipped level, and size BUF_INTS to the
// tightest buffer that holds the biggest room AND stages its stream safely.
const decoded = LEVELS.map((lv, i) => {
  const d = px9Decode(0x1000 + lv.offset);
  if (d.w !== lv.w || d.h !== lv.h) {
    throw new Error(`level ${i + 1} decode mismatch: got ${d.w}x${d.h}, want ${lv.w}x${lv.h}`);
  }
  const enc = lzEncode(d.out);
  const rt = lzDecode(enc);
  if (rt.length !== d.out.length || rt.some((v, k) => v !== d.out[k])) {
    throw new Error(`level ${i + 1} LZSS round-trip failed`);
  }
  const mapInts = Math.ceil((lv.w * lv.h) / 2);   // decoded tiles, packed
  const streamInts = Math.ceil(enc.length / 2);   // staged LZ bytes, packed
  // The stream sits at the tail; the front holds the growing decoded map.
  // A buffer of `mapInts + streamInts` always separates them; the overlap
  // check then confirms the in-place decode never reads past the write head.
  return { ...lv, tiles: d.out, enc, mapInts, streamInts };
});
BUF_INTS = Math.max(...decoded.map((d) => d.mapInts + d.streamInts));

const levels = decoded.map((lv, i) => {
  const S = BUF_INTS - lv.streamInts;
  if (!overlapSafe(lv.enc, S)) {
    throw new Error(`level ${i + 1}: in-place decode would collide at BUF_INTS=${BUF_INTS}`);
  }
  return { ...lv, S };
});

// ---- flags ------------------------------------------------------------------
const flags = Array.from(cart.subarray(0x3000, 0x3080)); // tiles 0-127

// ---- entity census (documents pool sizing; asserts the caps in main.lua) ---
const ENTITY = { 2: "player", 11: "springboard", 13: "checkpoint", 14: "spawner",
  15: "spawner", 19: "crumble", 20: "grapple_pickup", 21: "berry",
  36: "spike_v", 37: "spike_h", 46: "grappler", 62: "snowball", 63: "bridge" };
const CAPS = { springboard: 5, crumble: 20, berry: 6, snowball: 6, bridge: 2, spawner: 5 };
const maxCounts = {};
levels.forEach((lv, i) => {
  const counts = {};
  for (const t of lv.tiles) if (ENTITY[t]) counts[ENTITY[t]] = (counts[ENTITY[t]] ?? 0) + 1;
  for (const [k, v] of Object.entries(counts)) maxCounts[k] = Math.max(maxCounts[k] ?? 0, v);
  console.log(`level ${i + 1} (${lv.w}x${lv.h}, lz ${lv.enc.length}B):`,
    Object.entries(counts).map(([k, v]) => `${k}=${v}`).join(" ") || "(no entities)");
});
for (const [k, cap] of Object.entries(CAPS)) {
  if ((maxCounts[k] ?? 0) > cap) throw new Error(`pool cap ${k}=${cap} < max census ${maxCounts[k]}`);
}

// ---- emit lua ----------------------------------------------------------------
const lua = [];
lua.push("-- Data below is generated by gen/gen.mjs from the CC-BY-NC-SA cart -");
lua.push("-- run `node ports/celeste2/gen/gen.mjs` to regenerate. Do not hand-edit.");
lua.push("");

// flags as RLE runs
{
  const runs = [];
  for (let i = 0; i < flags.length; ) {
    let j = i;
    while (j < flags.length && flags[j] === flags[i]) j++;
    runs.push([j - i, flags[i]]);
    i = j;
  }
  lua.push("function fl_data()");
  for (const [n, v] of runs) lua.push(`  fr(${n}, ${v})`);
  lua.push("end");
  lua.push("");
}

// per-level meta + staged LZ bytes as d16() int calls (little-endian pairs)
const asInt = (lo, hi) => {
  const v = lo | (hi << 8);
  const s = v > 32767 ? v - 65536 : v;
  // the lexer parses -32768 as -(32768), which overflows 16.16 - emit an expr
  return s === -32768 ? "-32767-1" : String(s);
};
levels.forEach((lv, i) => {
  const n = i + 1;
  const ints = [];
  for (let j = 0; j < lv.enc.length; j += 2) {
    ints.push(asInt(lv.enc[j], lv.enc[j + 1] ?? 0));
  }
  lua.push(`function ld_dat_${n}()`);
  // ld_pos is the 1-based map[] index of the next staging int; lz_len in bytes
  lua.push(`  ld_pos = ${lv.S + 1}`);
  lua.push(`  lz_len = ${lv.enc.length}`);
  for (let j = 0; j < ints.length; j += 16) {
    const chunk = ints.slice(j, j + 16);
    if (chunk.length === 16) {
      lua.push(`  d16(${chunk.join(",")})`);
    } else {
      for (const v of chunk) lua.push(`  d1(${v})`);
    }
  }
  lua.push("end");
  lua.push("");
});

lua.push("function ld_dat(n)");
levels.forEach((lv, i) => {
  const kw = i === 0 ? "if" : "elseif";
  lua.push(`  ${kw} n == ${i + 1} then`);
  lua.push(`    lvl_w = ${lv.w} lvl_h = ${lv.h}`);
  lua.push(`    ld_dat_${i + 1}()`);
});
lua.push("  end");
lua.push("end");

// splice into main.lua between markers
const MAIN = path.join(PORT, "main.lua");
const BEGIN = "-- ===== GENERATED DATA (gen/gen.mjs) =====";
const END = "-- ===== END GENERATED DATA =====";
let src = readFileSync(MAIN, "utf8");
const b = src.indexOf(BEGIN), e = src.indexOf(END);
if (b === -1 || e === -1) throw new Error("main.lua is missing the GENERATED DATA markers");
src = src.slice(0, b + BEGIN.length) + "\n" + lua.join("\n") + "\n" + src.slice(e);
// keep the ship_levels local in lock-step with the emitted level count
src = src.replace(/local ship_levels = \d+/,
  `local ship_levels = ${LEVELS.length}`);
// size the map buffer + the lz_unpack staging pointer to the shipped slice.
// Both carry a trailing `-- BUF_INTS` marker so this rewrite is unambiguous.
if (!/local map = array\(\d+\)\s*--\s*BUF_INTS/.test(src) ||
    !/\(\d+ - \(lz_len \+ 1\) \\ 2\) \* 2\s*--\s*BUF_INTS/.test(src)) {
  throw new Error("main.lua is missing the -- BUF_INTS markers on map/lz_unpack");
}
src = src.replace(/local map = array\(\d+\)(\s*--\s*BUF_INTS)/,
  `local map = array(${BUF_INTS})$1`);
src = src.replace(/\(\d+ - \(lz_len \+ 1\) \\ 2\) \* 2(\s*--\s*BUF_INTS)/,
  `(${BUF_INTS} - (lz_len + 1) \\ 2) * 2$1`);
writeFileSync(MAIN, src);
const dataBytes = levels.reduce((a, lv) => a + lv.enc.length, 0);
console.log(`spliced ${lua.length} generated lines into main.lua ` +
  `(${LEVELS.length} levels, ${dataBytes} LZ bytes total)`);

// ---- sheet.bin ----------------------------------------------------------------
// top half: cart art unchanged. bottom half: zeros + mirrored cells at n+128.
const sheet = Buffer.alloc(8192);
cart.copy(sheet, 0, 0, 0x1000);
const getPix = (x, y) => { // cart gfx pixel (low nibble = left pixel)
  const b2 = cart[(y * 128 + x) >> 1];
  return (x & 1) ? (b2 >> 4) : (b2 & 15);
};
const setPix = (x, y, v) => {
  const idx = (y * 128 + x) >> 1;
  if (x & 1) sheet[idx] = (sheet[idx] & 0x0f) | (v << 4);
  else sheet[idx] = (sheet[idx] & 0xf0) | v;
};
for (const n of FLIPPED) {
  const sx = (n % 16) * 8, sy = (n >> 4) * 8;
  const m = n + 128;
  const dx = (m % 16) * 8, dy = (m >> 4) * 8;
  for (let y = 0; y < 8; y++) {
    for (let x = 0; x < 8; x++) {
      // player/pose sprites flip horizontally; spikes flip on their axis:
      // 36 (floor spike) mirrors vertically, 37 (wall spike) horizontally.
      if (n === 36) setPix(dx + x, dy + y, getPix(sx + x, sy + 7 - y));
      else setPix(dx + x, dy + y, getPix(sx + 7 - x, sy + y));
    }
  }
}
writeFileSync(path.join(PORT, "sheet.bin"), sheet);
console.log(`sheet.bin written (flipped cells: ${FLIPPED.map((n) => n + 128).join(", ")})`);

// ---- debug renders -------------------------------------------------------------
if (DEBUG) {
  const dir = path.join(PORT, "gen", "build-debug");
  mkdirSync(dir, { recursive: true });
  levels.forEach((lv, i) => {
    const W = lv.w * 8, H = lv.h * 8;
    const img = new Uint8Array(W * H);
    for (let ty = 0; ty < lv.h; ty++) {
      for (let tx = 0; tx < lv.w; tx++) {
        const t = lv.tiles[ty * lv.w + tx];
        if (t === 0) continue;
        const sx0 = (t % 16) * 8, sy0 = (t >> 4) * 8;
        for (let y = 0; y < 8; y++) for (let x = 0; x < 8; x++) {
          img[(ty * 8 + y) * W + tx * 8 + x] = getPix(sx0 + x, sy0 + y);
        }
      }
    }
    const pgm = [`P2`, `${W} ${H}`, `15`];
    for (let y = 0; y < H; y++) pgm.push(Array.from(img.subarray(y * W, (y + 1) * W)).join(" "));
    writeFileSync(path.join(dir, `level${i + 1}.pgm`), pgm.join("\n"));
  });
  console.log(`debug renders in ${dir}`);
}
