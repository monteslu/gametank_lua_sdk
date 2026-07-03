# Cherry Bomb — GameTank port notes

A hand-translation of "Cherry Bomb" by Krystman / Lazy Devs Academy
(PICO-8, https://www.lexaloffle.com/bbs/?tid=48986) to the gtlua SDK.
Real game logic, real extracted sprite sheet, real bullet-hell shmup.

Move with the d-pad, shoot with GT B (❎), drop a cherry bomb with GT A (🅾️).
Fly in, survive nine waves, kill the boss.

## How to build

```
node bin/gtlua.js build ports/cherry-bomb/main.lua \
     --sheet carts/cherrybomb-extract/gfx.bin -o ports/cherry-bomb/main.gtr
```

The source is ~1400 lines and its object code plus the 8 KB sprite sheet
overflow a flat 32 KB EEPROM cart, so the build auto-retargets a 2 MB
FLASH2M banked cart (see below).

### Why a banked (2 MB) cart, not a flat 32 KB one

`main.lua` compiles to more code than fits the GameTank's flat 32 KB
window. The `gtlua build` toolchain detects the 32 KB link overflow and
re-targets the **FLASH2M** 2 MB cartridge: a banked `$8000-$BFFF` 16 KB
window plus a fixed `$C000-$FFFF` bank (127). This port was the first real
consumer of that path, so a fair amount of the banking engine
(`sdk/gametank_flash2m.cfg`, `sdk/gt_bank.s`, and the far-call routing in
`compiler/emit.js` + the bank solver in `bin/gtlua.js`) exists because
Cherry Bomb needed it.

How the solver placed this game's 55 functions:

| bin   | count | what lands here                                             |
|-------|-------|-------------------------------------------------------------|
| fixed | 1     | `makestars` (reached from both the update and draw paths)   |
| b0    | 32    | the `_update` path: movement, collisions, spawning, AI      |
| b1    | 18    | the `_draw` path + `_init`                                   |
| b2    | 4     | cold spill (wave/boss setup) + the sprite sheet's rodata    |

Placement rules that matter for correctness *and* speed:

* **Any** placement is correct — every cross-bank call is bridged by a
  generated far-call stub in `stubs.s` that lives in the fixed bank,
  saves A/X around two `gt_bank_raw` bank switches, and forwards the
  cc65 fastcall registers blindly (works for any signature).
* A far-call stub is **expensive** (two 7-bit bit-banged bank switches),
  so the hot per-frame paths are kept stub-free: the `_update` call graph
  is pinned to b0 and the `_draw` call graph to b1, so a helper called
  every frame from within one path is same-bank (a plain `jsr`, no stub).
  Only 12 distinct callees are ever reached through a stub, and every one
  of them is on a **cold** edge (wave spawners `prow`/`spawnwave`, the
  event-driven `explode`/`fire`/`firespread`/`bossfire`/`popfloat`), never
  a per-entity inner loop.
* The sprite sheet (8 KB) is parked in b2, keeping b0/b1 free for code.

## Performance

The frame budget is exact and unforgiving. From the core's timing model:

* main CPU = 315000000/88 = **3,579,545 Hz**
* one vsync = clock/60 = **59,659 cycles**
* a blit costs **width × height cycles** (1 cycle/pixel), charged to the
  CPU as spin-wait in `await_drawing()` — blits serialize on the DMA
* `_update()` (no `_update60`) enables `gt_p8_fps30()`, so `gt_endframe`
  burns **2 vsyncs** per game frame. All of update + draw must finish
  inside that window (**119,318 cycles**) or the frame overruns into a 3rd
  vsync and pacing climbs above 2.0.

Techniques used to fit 2.0:

* `cls()` is issued **first** in `_update`, so its 127×127 (~16 K-cycle)
  clear DMA runs *under* the whole frame's update logic instead of
  stalling draw.
* Positions/velocities are **1/16-pixel ints**, not 16.16 fixed: the
  65C02 does 16-bit int math far cheaper than 32-bit fixed, and 1/16 px is
  invisible on a 128×128 screen. Trig stays real 16.16 (sin/cos), floored.
* The two per-frame **100-star loops** are the largest constant cost.
  `animatestars` hoists its invariant mode test out of the loop (three
  tight loops) and caches `star_y[i]`; `starfield` caches `star_s[i]`.
* Entity pools carry a compiler-maintained **high-water mark** so a
  loop over a 56-slot particle pool scans only the live prefix, not the
  full capacity — a pool that is empty between explosions costs a
  near-zero scan (see the compiler change below).
* Particle sparks are always white, so the spark draw path skips the
  `page_red`/`page_blue` colour-ramp call entirely.

### Measured pacing

<!-- PACING-TABLE -->
_To be filled from a live run: `vsyncs/frame = _gt_ticks Δ / ((_gt_time_acc Δ /1092)/2)`
over a busy-gameplay window. Symbols: `_gt_ticks` and `_gt_time_acc` in
`build/main.lbl`._

| scene                                   | vsyncs/frame |
|-----------------------------------------|--------------|
| gameplay, no fire                       | _pending_    |
| gameplay, holding fire + enemies        | _pending_    |
| boss + heavy particles                  | _pending_    |

## SDK gap report

Things the port had to work around, in priority order:

1. **No `pal()` sprite tinting.** The original flashes enemy/pickup
   silhouettes white via PICO-8 palette tinting. On GameTank the
   framebuffer bytes *are* colours, so the blitter can't recolour a
   sprite. Workaround: at boot we stamp white/pink silhouette copies of
   the real art into free sheet cells (`makesil`/`silrow`/`silcell`) and
   blit those. A future `spr` tint/recolour path would remove ~40 lines
   of boot code and free those sheet cells.
2. **No `cartdata`/`dset`/`dget`.** The high score is per-session only
   (see the `TODO cartdata` markers). Needs a `save_ram` region + a
   persist-on-write hook in the SDK.
3. **No sprite flips.** `spr` has no `flip_x`/`flip_y`. This port never
   needed them (the art is symmetric or pre-mirrored in the sheet), but
   it is a general gap.
4. **Sound is stubbed.** The many `TODO sfx(n)` / `music(n)` markers are
   where the original triggers PICO-8 SFX. The gtlua audio surface is
   `gt.note`/`gt.noteoff`; wiring the real `__sfx__` through
   `scripts/p8sfx.mjs` (per `docs/sfx.md`) is the remaining audio work.

## Gameplay divergences from the original cart

* **Pools are bounded** (PICO-8 tables are not). Capacities:
  enemies 40, bullets 28, enemy-bullets 48, particles 56, shockwaves 12,
  pickups 8, floats 8. An `add()` that overflows drops silently — the
  caps are set well above anything a real wave produces.
* **Modes/missions are ints, not strings** (`MSTART`..`MLOGO`,
  `MI_FLYIN`..`MI_B5`) — gtlua has no strings outside `print`.
* Particle damping is `v*27/32` (0.84375) done in ints vs the original's
  `*0.85`; star drift and easings are shift approximations of the
  original divides (documented inline). All sub-pixel, invisible.
* Trig is a 16.16 table (`sin`/`cos`); the flicker/bob phases match the
  original within a frame.

## Controls (GameTank)

| GameTank      | action        | PICO-8 equiv |
|---------------|---------------|--------------|
| d-pad         | move ship     | ⬅️➡️⬆️⬇️      |
| GT B (❎)     | shoot         | X (btn 5)    |
| GT A (🅾️)     | cherry bomb   | O (btn 4)    |
| GT A / GT B   | start / retry | any key      |
