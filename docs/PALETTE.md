# GameTank colors, and the PICO-8 → GameTank conversion

## The GameTank palette is the source of truth

A GameTank color is a **byte, 0–255**. That's the whole color interface — the
official SDK (Clyde Shaffer's `gametank_sdk`) draws with raw color bytes
(`BG_COLOR 32`, logo fades like `25, 57, 90, …`), and each byte's on-screen RGB
is defined by the emulator's palette table (`vendor/gametank_palette.h`).

The reference emulator (GameTankEmulator) ships **four** byte→RGB conversions and
defaults to **CAPTURE** ("Unscaled Capture" — measured from real hardware via a
capture card). This was a deliberate choice: commit `a7cc86a` (Dec 2024) *"make
unscaled the default"*, switching from SCALED. So:

- **CAPTURE is THE official, hardware-accurate GameTank palette.** gtlua follows
  it. Our `compiler/gt_palette.js` is the CAPTURE table, regenerated from the core.
- The other three (LEGACY/"Flawed Theory", SCALED/"Full Contrast", HDMI) are
  alternate looks. Our libretro core exposes all four via the `gametank_palette`
  core option (default `capture`); native carts render in CAPTURE like current
  upstream.

**Settled by Clyde Shaffer directly (Discord, 2026-07-11):** the pink hearts in
Cubicle Knight on the gametank.zone web emulator are **an OLD ROM with an unfixed
palette bug** — "I still gotta backport the palette fix from the Cubicle Knight |
A Very Hard Game combo cartridge." So pink is a stale-build artifact, NOT the
intended/official look; the accurate CAPTURE color for that index is purple. The
ROM itself cannot select a palette (no hardware register — a game only writes
color BYTES 0-255 via `DMA_Color`; the byte→RGB mapping is a viewer-side emulator
setting). CAPTURE is correct; don't re-litigate this.

**CAPTURE is muted** compared to a vivid modern palette — that's what real
GameTank hardware looks like, not a bug.

## Porting PICO-8: convert the 16 colors, don't transplant them

PICO-8 has a fixed 16-color palette; GameTank has ~200 muted colors on a
different gamut. **We do NOT try to reproduce PICO-8's colors** — we map each
PICO-8 index to the **nearest GameTank byte**, accepting it's a lossy match
(same class of divergence as sprites, audio, and fixed-point — see
`AUDIO_ARCHITECTURE.md`). gtlua does this automatically: a `color(n)` /
`pset(x,y,n)` with a PICO-8 index 0–15 is routed through `P8_PALETTE`
(`compiler/builtins.js`) to the GameTank byte below. Use `gt.rgb(byte)` to reach
a raw GameTank color directly.

### The conversion table

| # | PICO-8 name | PICO-8 hex | GameTank byte | GameTank hex (CAPTURE) | note |
|---|---|---|---|---|---|
| 0  | black       | `#000000` | `0x00` | `#1a1a1a` | GT has no pure black; 0x00 is the darkest neutral |
| 1  | dark-blue   | `#1d2b53` | `0xA9` | `#1f334a` | close |
| 2  | dark-purple | `#7e2553` | `0x5A` | `#8e3348` | close |
| 3  | dark-green  | `#008751` | `0xDB` | `#17725d` | close |
| 4  | brown       | `#ab5236` | `0x33` | `#805924` | moved off the red row to read as brown |
| 5  | dark-gray   | `#5f574f` | `0x03` | `#5d5d5d` | neutral ramp |
| 6  | light-gray  | `#c2c3c7` | `0x06` | `#a1a1a1` | neutral ramp |
| 7  | white       | `#fff1e8` | `0x07` | `#b9b9b9` | **GT has no true white** — 0x07 is the brightest neutral (~185 gray) |
| 8  | red         | `#ff004d` | `0x5B` | `#a64a5e` | GT's reds are muted/pinkish |
| 9  | orange      | `#ffa300` | `0x3E` | `#d69b4b` | muted orange |
| 10 | yellow      | `#ffec27` | `0x1F` | `#b9c541` | yellow-green row (GT yellow is olive) |
| 11 | green       | `#00e436` | `0xFE` | `#70b94f` | muted green |
| 12 | blue        | `#29adff` | `0xBE` | `#70a8f4` | light blue |
| 13 | indigo      | `#83769c` | `0x8C` | `#75719b` | close |
| 14 | pink        | `#ff77a8` | `0x5E` | `#ea8ca2` | close |
| 15 | peach       | `#ffccaa` | `0x2F` | `#cbb79f` | close |

**Biggest compromises to expect when porting:**
- **No pure white or pure black** — GameTank's neutral ramp tops out around a
  light gray and bottoms at a dark gray. High-contrast PICO-8 art loses some punch.
- **Muted primaries** — GameTank red/green/yellow are desaturated vs PICO-8's
  vivid ones; a port reads as a softer, more pastel version of the original.
- These are hand-tuned picks (not pure nearest-RGB): a few colors were nudged to
  avoid collapsing onto the same GameTank color row (brown off red, yellow onto
  the yellow-green row). Regenerate with the nearest-match tool if the palette
  table ever changes (`compiler/gt_palette.js` header).

This is fine and expected: **a GameTank port re-creates a PICO-8 game on
different hardware — it copies the art, gameplay and structure, and re-colors to
the platform's palette.** Document any per-game color surprises in the port's
`PORT_NOTES.md`.

See also: `AUDIO_ARCHITECTURE.md` (the same "re-voice, don't transplant" logic
for sound), and the core's `gametank_palette` option for the alternate looks.
