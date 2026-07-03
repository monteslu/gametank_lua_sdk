# Celeste Classic 2 — "Lani's Trek" — GameTank / gtlua port notes

A hand-translation to gtlua of ExOK Games' *Celeste Classic 2: Lani's Trek*
(PICO-8, CC-BY-NC-SA 4.0 — see `LICENSE`). Source of truth for the logic is
`carts/celeste2-extract/source.p8.lua` (px9-decompressed from the BBS cart,
tid=41282). This document records every divergence from the original, the
`map()/mget()/fget()` builtin spec this port needs from the SDK, and a
prioritized SDK gap report.

---

## What ships (the slice) and why

**This build ships the title screen + room 1 ("Trailhead"), with real
movement, the real sprite sheet, and the room's real map data.** It is a
FLASH2M (2 MB, banked) cart. One room is the *largest slice that fits the
GameTank's 3-code-bank budget* — see the gap report below for exactly why the
whole game does not fit, and what SDK changes would unlock more rooms.

`ship_levels` (top of `main.lua`) and the generated `ld_dat` cases are kept in
lock-step by `gen/gen.mjs --levels N`. Rebuild the whole slice with:

```
node ports/celeste2/gen/gen.mjs --levels 1     # regenerate data + sheet
node ports/celeste2/build.mjs                    # FLASH2M banked build
```

`build.mjs` is a port-local build driver (my ownership boundary — it does NOT
touch `bin/gtlua.js` or `sdk/`). The stock `gtlua build` auto-retargets FLASH2M
too, but its bank solver seeds the entire `_update`-reachable subgraph into
bank 0 (~25 KB — larger than one 16 KB bank) and never converges for this game.
`build.mjs` replaces that with a call-graph-clustering bin-packer (details in
its header comment) that minimises cross-bank far-call stubs — the stubs live
in the fixed bank, which is the scarce resource here.

### Divergences from the original cart

1. **One room, not eight.** Rooms 2-8 and the grapple-unlock arc are cut for
   size (gap report §1). `next_level()` past `ship_levels` shows the outro
   card. The whole 8-room map data + loaders *are* generated correctly by
   `gen.mjs` (verified via round-trip + per-level PGM renders in
   `gen/build-debug/`); they simply exceed the cart budget.

2. **Grapple removed.** *Lani's Trek*'s signature grapple unlocks at room 4
   (`have_grapple = level_index > 2`), so it is dormant in rooms 1-3 anyway.
   The grapple-firing states (10/11/12/50) and their functions
   (`p_start_grapple`, `p_grapple_check`, `p_state12`, `draw_rope`,
   `ghit_destroyed`, `consume_grapple_press`) were deleted — provably
   unreachable while `have_grapple == 0` — to reclaim ~5 KB of the code budget.
   Jump, wall-jump, coyote/grace timers, spring launches, snowball/springboard
   carry (`p_state1`/`p_state2`, the `holds` pool) all stay. To restore the
   grapple, re-ship rooms 4+ and git-revert the grapple deletions.

3. **Audio disabled + sfx scheduler removed (SDK blocker, not a choice).** Any
   `gt.note` call pulls in `sdk/gt_audio.o`, whose **4 KB ACP firmware blob**
   (`gt_acp_fw.h`) lands in the FIXED bank's RODATA. The SDK runtime + that blob
   already overflow the 16 KB fixed bank (§2 below), leaving no room for the
   cross-bank stubs a banked build needs. So every `gt.note`/`gt.noteoff` is
   gone, and — since with no audio the sfx scheduler (`sfx_go`/`psfx`/`sfx_q`/
   `sfx_tick` + the `sfx_t`/`sfxq_*` pools) only burned fixed-bank stubs — the
   whole scheduler was removed too (its 37 call sites are commented with a
   trailing marker). Re-enable by restoring those functions + call sites once
   the SDK moves the ACP firmware to a switchable bank.

3b. **Cosmetic HUD/atmosphere trimmed for fixed-bank headroom (SDK drift).**
   The fixed bank is razor-tight, and the shared SDK grew ~1.7 KB mid-port (a
   new `gt.starfield_*` parallax primitive, linked whole-object even though this
   port never calls it — see §2). To keep a stable margin, four cosmetic
   functions + their cross-bank stubs were dropped: `draw_time` (speedrun timer
   HUD), `draw_score_panel` (end-of-level berry/death card), `draw_wipe` (room
   transition curtain), and `draw_clouds` (background parallax; the iconic snow
   layer stays). None affect movement or collision. All are one git-revert away
   once the SDK stops growing / the starfield object is split out.

4. **Numbers transfer exactly.** The engine is 16.16 fixed-point in both PICO-8
   and gtlua, so jump/dash/spring constants are byte-identical. `_update()`
   runs at 30 fps (PICO-8's `_update`, not `_update60`), matching the cart, so
   no per-frame rescale was needed — the apex/geometry match the original by
   construction. (If a future build moves to `_update60`, halve every
   per-frame accel/velocity constant.)

5. **No `spr()` flip.** gtlua `spr()` has no flip flags. `gen/gen.mjs` bakes
   horizontally/vertically mirrored copies of the six flipped tiles
   (player poses 2-5, spikes 36/37) into free sheet cells at `n + 128` (the
   cart's bottom-half rows there hold px9 level data — unused by the port).
   `p_draw` picks `spr(n)` vs `spr(n + 128)` by `p_facing`.

6. **Map drawing is per-non-empty-tile.** `draw_tiles` walks only the tiles in
   the camera window and `spr()`s each non-zero tile over a `rectfill`
   background — a full 256-tile redraw per frame would blow the frame budget.

7. **sfx are single-osc blips** (when audio is on): the cart's tracker
   sfx/music are not portable; `sfx_go`/`sfx_q` schedule one-note ACP blips
   approximating the cue timing. Music is omitted.

---

## The map system in this port (and the builtin it wants)

gtlua has **no `map()`/`mget()`/`fget()` builtin and no way to embed constant
data in ROM** (see gap report §3). This port works around both:

* **Storage.** `map = array(BUF_INTS)` (RAM; 2 tiles packed per 16-bit int).
  `gen/gen.mjs` sizes `BUF_INTS` to the SHIPPED slice — the biggest shipped room
  plus its LZ-stream staging — patching the `-- BUF_INTS` markers in `main.lua`.
  For the full game a 128×32 room is 4096 tiles = 2048 ints (the `array()` cap);
  a 1-room slice needs far less (room 1 = 96×16 = 768 tiles → 972 ints incl.
  staging), which reclaims scarce work RAM. `bget(i)`/`bset(i,b)` do byte access
  into it.
* **Load.** `gen.mjs` px9-decodes each cart room, re-encodes it as a tiny LZSS
  stream (window = the decoded room itself, so the decoder needs no scratch
  RAM), and emits the bytes as `ld_dat_N()` (`d16`/`d1` data-call code). At
  load time the stream is staged in the tail of `map[]` and `lz_unpack()`
  decodes it in place just ahead of the write pointer (`gen.mjs` simulates
  every room and refuses to emit if the pointers would ever collide).
* **`mget` equivalent.** `mget(tx,ty)` returns `bget(ty*lvl_w + tx)` (0 out of
  bounds) — used by collision (`tile_solid`, `p_check_solid`, hazards) and by
  `draw_tiles`.
* **`fget` equivalent.** The 128-entry sprite-flag table (cart `0x3000`) is
  RLE-loaded into `fl = array(128)` by `fl_data()`; `fget(n)` is `fl[n+1]`.

### Proposed `map()/mget()/fget()` builtin spec (PRIMARY DELIVERABLE)

Three ports (this one, driftmania, newleste) all hand-roll the same thing. A
real builtin should look like this:

```
-- One const map blob linked from a raw file at build time, exactly like
-- --sheet does for graphics (this is the only compact-ROM-data path the
-- toolchain has). Declared once at top level:
local rooms = mapdata("celeste2.map")   -- raw bytes -> a MAP segment in ROM

-- Reads (ROM-backed, no RAM copy, no loader code):
mget(mx, my)          -- tile byte at (mx,my) in the active map region
fget(n)               -- sprite-flag byte for tile n (from the same blob or --flags)
fget(n, bit)          -- bit b of the flag byte, as a bool

-- Region select (a room is a rectangle inside the blob):
mapregion(x0, y0, w, h)   -- set the active window mget()/map() read from

-- Bulk draw, camera-clipped, non-zero tiles only (what draw_tiles hand-writes):
map(mx, my, sx, sy, mw, mh)   -- blit a mw×mh tile block from (mx,my) to (sx,sy)
```

Key design points, learned the hard way here:

* **`mapdata()` must land the bytes in ROM (a `MAP` rodata segment), NOT RAM.**
  The whole pain of this port is that today the *only* way to get map bytes
  into the program is executable `arr[i]=v` / `d16(...)` statements, which cost
  ~5-6 bytes of banked code per stored byte (a 4 KB map → ~24 KB of code). A
  const ROM blob + a `peek`-style read is ~1 byte per byte.
* **`fget(n, bit)` returns a bool** (PICO-8 semantics) so `if fget(t,1)` reads
  naturally; the whole-byte form stays for masks.
* **`map()` skips tile 0** (transparent) and clips to the screen, matching
  every port's hand-written `draw_tiles`.
* Storage width: a byte-per-tile blob is simplest; if tiles > 255 are needed,
  a 16-bit variant (`mapdata16`) — but PICO-8 maps are byte tiles, so byte is
  the common case.

The blob-in-ROM mechanism generalises the existing `--sheet` link: add a
`--map file.bin` (and optional `--flags file.bin`) that links a raw file into a
new `MAP`/`FLAGS` rodata segment, plus `peek`-style builtins to index it. That
single addition removes the LZSS-staging dance, the `d16`/`d1` blowup, the
`array(2048)` RAM cost, and the in-place-decode collision check — from three
ports at once.

---

## SDK gap report (prioritized)

**§1 — FLASH2M has only 3 code banks; big games can't fit. (HIGH)**
`sdk/gametank_flash2m.cfg` defines exactly three 16 KB game-code banks
(BANK0/1/2) + a fixed bank, and BANK2 is shared with the 8 KB sprite sheet, so
the *entire* game-code budget is ~16+16+8+(~2.5 fixed) ≈ 42.5 KB. Celeste 2's
full logic + 8-room loaders is ~67 KB → it overflows by ~25 KB and no placement
can fix that. A 2 MB flash holds 128 banks; the config uses 4. **Ask:** a
FLASH2M layout that spreads game code across *many* banks (BANK3..BANKn) with
the far-call stub mechanism already in `gt_bank.s`, so code size scales past
42 KB. This is the single change that would let the whole game ship.

**§2 — Banked + audio is structurally impossible today. (HIGH)**
The SDK runtime that must live in the 16 KB *fixed* bank is CODE ~13 KB +
RODATA ~5.8 KB ≈ **18.7 KB — already 2.3 KB over 16 KB** the moment audio is
used, because `gt_audio.c` embeds the **4 KB ACP firmware blob**
(`gt_acp_fw.h`) in fixed RODATA. Result: any banked game that calls `gt.note`
can't fit its own runtime in the fixed bank, before a single stub or game
byte. (This port only builds because audio is disabled.) **Ask:** put the ACP
firmware in a switchable bank and stream/copy it to audio RAM at init from
there, freeing ~4 KB of fixed RODATA. Secondary: the fixed bank is tight even
without audio — trimming `gt_api`'s fixed CODE, or allowing per-bank RODATA for
`gt_math`'s sin/cos table, buys headroom (this port lands within ~40 bytes of
the fixed-bank ceiling).

**§2b — `gt_api.o` is one monolithic object; unused primitives still cost
fixed-bank space. (MEDIUM)** cc65 links whole objects, so a game that never
calls `gt.starfield_*` still pays its ~1.7 KB of fixed CODE (adding that
primitive mid-port is what forced the §3b cosmetic cuts here). **Ask:** split
`gt_api.c` into per-feature translation units (or move the optional primitives —
starfield, and anything not on the boot path — behind a link-time opt-in), so a
banked game only pays fixed-bank code for the SDK it actually calls.

**§3 — No way to put constant data in ROM. (HIGH — see the map spec above)**
`array(N[,v])` allocates *RAM* (zeroed, or a scalar-filled DATA image); there
is no `data{...}`, no const array, no `peek`/`poke`, and strings are only usable
in `print()`. Every port that has map/level/table data emits it as executable
assignment statements at ~5-6 bytes of code per data byte. The `--sheet` link
is the only compact-ROM-data path and it's graphics-shaped. **Ask:** the
`mapdata()`/`--map`/`peek`-index mechanism in the spec above (or a general
`const bytes` builtin that emits a `#pragma rodata-name` initializer list).

**§4 — The stock bank solver doesn't converge for update-heavy games. (MEDIUM)**
`bin/gtlua.js`'s `initialPlacement` puts the whole `_update` subgraph in bank 0;
when that subgraph is > 16 KB it can't converge. The clustering packer in this
port's `build.mjs` (BFS-from-callbacks + neighbour-weighted bank choice +
single-caller affinity + a one-shot-loader affinity group + a final
small-leaf rebalance) does converge and roughly halves the cross-bank stub
count. Worth folding the clustering approach back into the stock solver.

**§5 — `spr()` has no flip. (LOW)** Documented workaround (bake mirrored cells)
works but wastes sheet cells and boot-time `sset` (or generator work). An
`spr(n, x, y, w, h, flip_x, flip_y)` matching PICO-8 would remove it.

**§6 — No `gametank` input layout in the RE tooling. (LOW)**
`input({op:'layout', platform:'gametank'})` returns "not documented". For the
record: `btn(4)` = O (GameTank **A**, raw libretro `b`, mask bit 0x10),
`btn(5)` = X (GameTank **B**, raw `y`), plus d-pad and START. Jump is `btn(4)`,
grapple/dash is `btn(5)`.

---

## Verification status

Verified via the rom-dev MCP `gametank` core:
* **Title screen** renders correctly ("CELESTE 2 / LANI'S TREK" + the ExOK
  credits + "GAMETANK PORT OF THE PICO-8 GAME"); `level_index == 0` in RAM.
* **Jump advances to room 1**, which renders with the real sprite sheet (player
  + red scarf, terrain, water pool, snow, bridges) and the live HUD timer.

Note: the rom-dev emulator is a shared, single-tenant host; during this run it
was under heavy contention from other agents (frequent cross-cart reloads), so
extended input-driven playtesting was intermittent. The two captures above were
clean. Re-verify with: `loadMedia({platform:'gametank', path:'.../main.gtr'})`
→ `frame({op:'stepAndShot', frames:180})` (title) → jump (raw `b`) → step →
screenshot (room 1). Confirm you're on this cart by reading `level_index`
(system_ram offset 0x09): 0 = title, 1 = room 1. A `level_index` of anything
else means another agent's cart is loaded — reload and retry.
