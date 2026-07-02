# GameTank Lua SDK

Write [GameTank](https://gametank.zone/) games in **PICO-8-flavored Lua**.
This SDK compiles a statically-typed Lua dialect to C, builds it with cc65
against a bundled GameTank runtime, and produces a flat 32 KB `.gtr`
cartridge that runs in the
[emulator](https://github.com/clydeshaffer/GameTankEmulator), on
[gametank.zone](https://gametank.zone/), and on real hardware via
[GTFO](https://github.com/clydeshaffer/gtfo).

No interpreter, no VM: your Lua becomes native 65C02 machine code. The
GameTank's 128×128 screen is the same size as PICO-8's, so coordinates,
sprite sheets, and game feel transfer 1:1.

```lua
local angle = 0
local radius = 40

function _update60()
  angle += 0.008
  if (btn(0)) radius -= 1
  if (btn(1)) radius += 1
  radius = mid(8, radius, 58)
end

function _draw()
  cls(1)
  circfill(64, 64, 10, 9)
  circfill(64 + flr(cos(angle) * radius),
           64 + flr(sin(angle) * radius), 5, 8)
end
```

## Requirements

- [Node.js](https://nodejs.org/) 18+ (runs the compiler)
- the cc65 toolchain — either on your `PATH`, or built into the repo with
  `scripts/install_tools.sh`

## Quickstart

```sh
node bin/gtlua.js build examples/orbit/main.lua
```

That produces `examples/orbit/main.gtr` in under 100 ms. Run it in the
GameTank emulator or flash it to a cartridge. `node bin/gtlua.js c
<file.lua>` prints the generated C.

## The PICO-8 contract

Define `_update60()` (60 fps) or `_update()` (30 fps), plus `_draw()`, and
optionally `_init()`. The runtime latches inputs before each update and ends
the frame after `_draw()` (blitter drain, vblank, page flip).

**Numbers are PICO-8 numbers**: 16.16 fixed point, −32768 to 32767.99998,
wrap on overflow, division by zero saturates. `sin`/`cos`/`atan2` use turns
(0..1) with PICO-8's screen-space-inverted sin. Under the hood the compiler
infers which values stay integral and keeps them in fast 16-bit ints — an
optimization, never a semantic change.

**The dialect** keeps PICO-8's syntax: `+=`-style compound assignment,
one-line `if (cond) stmt` / `while (cond) stmt`, `!=`, `\` floor division,
`//` comments, hex/binary literals with fractions (`0x11.4`, `0b101.1`),
button glyphs (`⬅️➡️⬆️⬇️🅾️❎`), and multiple assignment (`x, y = 64, 32`).

## API (v0.2)

| | |
|---|---|
| lifecycle | `_init` `_update` `_update60` `_draw` |
| graphics | `cls` `camera` `color` `pal` `pset` `rect` `rectfill` `circ` `circfill` `line` |
| input | `btn(i,[pl])` `btnp(i,[pl])` — indices 0-3 d-pad, 4=🅾️(GT A), 5=❎(GT B), **6=GT C**, 7=START; `btnp` has PICO-8 auto-repeat |
| math | `flr` `ceil` `abs` `sgn` `sqrt` `min` `max` `mid` `sin` `cos` `atan2` `rnd` `srand` `t`/`time` |
| gametank extras | `gt.rgb(b)` — raw palette byte (the GameTank has 256 colors; 0-15 are mapped to the PICO-8 palette), `gt.border(c)`, `gt.ticks()` |

Colors are PICO-8 indices (0 black, 7 white, 8 red, 12 blue, …), mapped to
the closest GameTank palette entries; `pal(c0,c1)` remaps, `gt.rgb()`
unlocks the full 256.

Coming next (see [PICO8.md](PICO8.md) for the full roadmap): tables as
capacity-bounded sequences with `add/del/all/foreach`, `spr`/`sspr` sprites
on GRAM sheets, `map`/`mget`/`fget`, `sfx`/`music` on the audio coprocessor,
then `print` and strings.

## Not-Lua walls (loud, never silent)

Conditions must be boolean (`if x ~= 0 then`, not `if x then` — Lua calls 0
truthy, C doesn't, gtlua refuses to guess). No `nil`, closures, metatables,
coroutines, or `goto`. Every unsupported feature is a compile-time error
that says what to write instead.

## Repo layout

`compiler/` Lua→C compiler (plain JS ESM) · `sdk/` the C/asm runtime
(register protocols, fixed-point core, math tables, interrupt handlers,
cc65 startup/linker files) · `bin/gtlua.js` CLI · `examples/` ·
`test/` (`npm test`) · [SPEC.md](SPEC.md) language reference ·
[PICO8.md](PICO8.md) design doc · [PROVENANCE.md](PROVENANCE.md).

## License

MIT. `sdk/` hardware files adapted from
[clydeshaffer/gametank_sdk](https://github.com/clydeshaffer/gametank_sdk) (MIT).
