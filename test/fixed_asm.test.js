// fixed_asm.test.js - semantic regression gate for the hand-asm 16.16 core.
//
// The hand-written 65C02 gt_fmul / gt_fdiv in sdk/gt_fixed_asm.s must be
// bit-for-bit identical to the C reference in sdk/gt_fixed.c (PICO-8
// semantics). Bit-exactness is *proven on the emulator* by a 1300+ vector
// ROM (see the "emulator vector gate" note below), so this file's job is to
// lock down the reference model those vectors are generated from - if someone
// changes the intended semantics, these host-side reference checks change too
// and the mismatch is caught before a ROM is ever built.
//
// The two closed forms below are the ones the asm implements, each verified
// equal to the exact C algorithm across the full edge + random vector set:
//   fmul(a,b) = neg( (|a| * |b|) >> 16 )            truncated to 32 bits
//   fdiv(a,b) = neg( floor((|a| << 16) / |b|) )     truncated to 32 bits
//               with /0 -> a<0 ? 0x80000001 : 0x7FFFFFFF   (P8 manual)
//
// Emulator vector gate (run manually against a build, not in `node --test`):
//   a ROM calls gt_fmul/gt_fdiv on ~1300 vectors (edges + /0 + random +
//   gameplay-range) and writes pass/fail counts to RAM; the harness reads
//   them back. Last run: 644/644 mul, 649/649 div, 0 fail.

import { test } from "node:test";
import assert from "node:assert/strict";

const M32 = (1n << 32n) - 1n;
const M64 = (1n << 64n) - 1n;

function s32(x) {
  x &= M32;
  return x >= 0x80000000n ? x - (1n << 32n) : x;
}

// --- exact C reference (transliteration of sdk/gt_fixed.c) --------------------
function refFmulC(aS, bS) {
  const a = s32(aS), b = s32(bS);
  let neg = 0n;
  let ua, ub;
  if (a < 0n) { ua = (-a) & M32; neg ^= 1n; } else ua = a & M32;
  if (b < 0n) { ub = (-b) & M32; neg ^= 1n; } else ub = b & M32;
  const ah = ua >> 16n, al = ua & 0xFFFFn;
  const bh = ub >> 16n, bl = ub & 0xFFFFn;
  let res = ((ah * bh) & M32) << 16n & M32;   // ((ah*bh)<<16) as 32-bit
  res = (res + ((ah * bl) & M32)) & M32;
  res = (res + ((al * bh) & M32)) & M32;
  res = (res + (((al * bl) & M32) >> 16n)) & M32;
  return neg ? (-res) & M32 : res;
}
function refFdivC(aS, bS) {
  const a = s32(aS), b = s32(bS);
  if (b === 0n) return a < 0n ? 0x80000001n : 0x7FFFFFFFn;
  let neg = 0n, ua, ub;
  if (a < 0n) { ua = (-a) & M32; neg ^= 1n; } else ua = a & M32;
  if (b < 0n) { ub = (-b) & M32; neg ^= 1n; } else ub = b & M32;
  let q = 0n, r = 0n;
  for (let i = 0n; i < 48n; ++i) {
    r = (r << 1n) & M64;
    if (i < 32n) r |= (ua >> (31n - i)) & 1n;
    q = (q << 1n) & M64;
    if (r >= ub) { r -= ub; q |= 1n; }
  }
  q &= M32;
  return neg ? (-q) & M32 : q;
}

// --- closed forms the asm implements -----------------------------------------
function asmFmul(aS, bS) {
  const a = s32(aS), b = s32(bS);
  const neg = (a < 0n) !== (b < 0n);
  const ua = a < 0n ? (-a) & M32 : a & M32;
  const ub = b < 0n ? (-b) & M32 : b & M32;
  let res = ((ua * ub) >> 16n) & M32;
  return neg ? (-res) & M32 : res;
}
function asmFdiv(aS, bS) {
  const a = s32(aS), b = s32(bS);
  if (b === 0n) return a < 0n ? 0x80000001n : 0x7FFFFFFFn;
  const neg = (a < 0n) !== (b < 0n);
  const ua = a < 0n ? (-a) & M32 : a & M32;
  const ub = b < 0n ? (-b) & M32 : b & M32;
  let q = ((ua << 16n) / ub) & M32;
  return neg ? (-q) & M32 : q;
}

// deterministic PRNG (xorshift32)
function makeRng(seed) {
  let s = seed >>> 0;
  return () => {
    s ^= s << 13; s >>>= 0;
    s ^= s >>> 17;
    s ^= s << 5; s >>>= 0;
    return BigInt(s >>> 0);
  };
}

const EDGES = [
  0n, 1n, 0xFFFFFFFFn, 0x00010000n, 0xFFFF0000n, 0x7FFFFFFFn, 0x80000000n,
  0x00008000n, 0xFFFF8000n, 0x00018000n, 0x00028000n, 2n, 0xFFFFFFFEn, 3n,
  0x000186A0n, 0x00030000n, 0xFFFD0000n, 0xABCDEF01n, 0x0000FFFFn, 0x80000001n,
  0x40000000n, 0xC0000000n,
];

test("asm fmul closed form == exact C reference (edges)", () => {
  for (const a of EDGES) for (const b of EDGES) {
    assert.equal(asmFmul(a, b), refFmulC(a, b),
      `fmul(0x${a.toString(16)}, 0x${b.toString(16)})`);
  }
});

test("asm fdiv closed form == exact C reference (edges, incl /0)", () => {
  for (const a of EDGES) for (const b of EDGES) {
    assert.equal(asmFdiv(a, b), refFdivC(a, b),
      `fdiv(0x${a.toString(16)}, 0x${b.toString(16)})`);
  }
});

test("asm == C reference over 5000 random 32-bit vectors", () => {
  const rng = makeRng(0x2468ace0);
  for (let i = 0; i < 5000; i++) {
    const a = rng(), b = rng();
    assert.equal(asmFmul(a, b), refFmulC(a, b),
      `fmul(0x${a.toString(16)}, 0x${b.toString(16)})`);
    assert.equal(asmFdiv(a, b), refFdivC(a, b),
      `fdiv(0x${a.toString(16)}, 0x${b.toString(16)})`);
  }
});

test("PICO-8 divide-by-zero saturation edge", () => {
  // manual: 1/0 -> +max, -1/0 -> most-negative-ish (0x80000001)
  assert.equal(asmFdiv(0x00010000n, 0n), 0x7FFFFFFFn);   //  1 / 0
  assert.equal(asmFdiv(0xFFFF0000n, 0n), 0x80000001n);   // -1 / 0
  assert.equal(asmFdiv(0n, 0n), 0x7FFFFFFFn);            //  0 / 0 -> +max
});

test("known 16.16 results (spot checks)", () => {
  assert.equal(asmFmul(0x00018000n, 0x00020000n), 0x00030000n); // 1.5 * 2 = 3
  assert.equal(asmFmul(0xFFFF0000n, 0x00020000n), 0xFFFE0000n); // -1 * 2 = -2
  assert.equal(asmFdiv(0x00030000n, 0x00020000n), 0x00018000n); // 3 / 2 = 1.5
  assert.equal(asmFdiv(0xFFFD0000n, 0x00020000n), 0xFFFE8000n); // -3 / 2 = -1.5
});
