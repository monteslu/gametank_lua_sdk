#!/usr/bin/env node
// Extract a PICO-8 .p8.png cart (one cart byte per pixel, packed into the
// low 2 bits of A,R,G,B). Dumps the raw 0x8000 cart image plus the
// uncompressed __gfx__ sheet (0x0000-0x1FFF, 4bpp) as a PGM for inspection.
// Code section (0x4300+, pxa-compressed) is dumped raw; decompressor next.
// Usage: node scripts/p8extract.mjs cart.p8.png outdir
import { readFileSync, writeFileSync, mkdirSync } from "node:fs";
import zlib from "node:zlib";
import path from "node:path";

const [png, outdir] = process.argv.slice(2);
mkdirSync(outdir, { recursive: true });
const buf = readFileSync(png);

// minimal PNG decode: find IDAT chunks, inflate, un-filter (needs libpng-free
// path). Cheat: use sharp/canvas if present; else decode via zlib + filters.
function decodePNG(b) {
  let pos = 8;
  let w = 0, h = 0, idat = [];
  while (pos < b.length) {
    const len = b.readUInt32BE(pos);
    const type = b.toString("ascii", pos + 4, pos + 8);
    const data = b.subarray(pos + 8, pos + 8 + len);
    if (type === "IHDR") { w = data.readUInt32BE(0); h = data.readUInt32BE(4); }
    if (type === "IDAT") idat.push(data);
    pos += 12 + len;
  }
  const raw = zlib.inflateSync(Buffer.concat(idat));
  const stride = w * 4;
  const out = Buffer.alloc(w * h * 4);
  let prev = Buffer.alloc(stride);
  for (let y = 0; y < h; y++) {
    const f = raw[y * (stride + 1)];
    const line = raw.subarray(y * (stride + 1) + 1, (y + 1) * (stride + 1));
    const cur = Buffer.alloc(stride);
    for (let x = 0; x < stride; x++) {
      const a = x >= 4 ? cur[x - 4] : 0;
      const bx = prev[x];
      const c = x >= 4 ? prev[x - 4] : 0;
      let v = line[x];
      if (f === 1) v += a;
      else if (f === 2) v += bx;
      else if (f === 3) v += (a + bx) >> 1;
      else if (f === 4) {
        const p = a + bx - c, pa = Math.abs(p - a), pb = Math.abs(p - bx), pc = Math.abs(p - c);
        v += (pa <= pb && pa <= pc) ? a : (pb <= pc ? bx : c);
      }
      cur[x] = v & 0xFF;
    }
    cur.copy(out, y * stride);
    prev = cur;
  }
  return { w, h, rgba: out };
}

const { w, h, rgba } = decodePNG(buf);
console.log(`png ${w}x${h}`);
const cart = Buffer.alloc(0x8020);
for (let i = 0; i < cart.length && i < w * h; i++) {
  const o = i * 4;
  const r = rgba[o], g = rgba[o + 1], b2 = rgba[o + 2], a = rgba[o + 3];
  cart[i] = ((a & 3) << 6) | ((r & 3) << 4) | ((g & 3) << 2) | (b2 & 3);
}
writeFileSync(path.join(outdir, "cart.bin"), cart);

// __gfx__: 0x0000-0x1FFF, 4bpp, two pixels per byte (low nibble first),
// 128x128 sheet. Emit PGM (values 0-15) for eyeballing + gfx.bin.
writeFileSync(path.join(outdir, "gfx.bin"), cart.subarray(0, 0x2000));
const pgm = [`P2`, `128 128`, `15`];
for (let y = 0; y < 128; y++) {
  const row = [];
  for (let x = 0; x < 128; x++) {
    const byte = cart[(y * 128 + x) >> 1];
    row.push((x & 1) ? (byte >> 4) : (byte & 15));
  }
  pgm.push(row.join(" "));
}
writeFileSync(path.join(outdir, "gfx.pgm"), pgm.join("\n"));
writeFileSync(path.join(outdir, "code.bin"), cart.subarray(0x4300, 0x8000));
console.log("wrote cart.bin, gfx.bin, gfx.pgm, code.bin (code is pxa-compressed)");
