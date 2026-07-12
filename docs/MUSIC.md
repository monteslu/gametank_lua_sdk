# Native FM music: `.gtm2` songs

The GameTank has a dedicated audio coprocessor — a **4-operator FM synth** on a
second 65C02. gt-lua plays music on it with the console's own song format,
**`.gtm2`** — the same format Clyde Shaffer's official SDK uses (the one
`midiconvert.js` produces and `music.c` plays). Songs you make for gt-lua are
real GameTank songs.

`.gtm2` is a 4-channel, MIDI-derived event stream. It sits alongside the
PICO-8-style `sfx()`/`music()` path (see [sfx.md](sfx.md)); use whichever fits.

## Playing a song

Embed a `.gtm2` blob with `hexdata` and play it with `song`:

```lua
local tune = hexdata("000104050100023001a...")  -- your .gtm2 bytes as hex

function _init()
  song(tune)          -- play, looping (default)
  -- song(tune, false) -- play once
end
```

`gt.song_stop()` halts playback. `song` pulls in the FM audio runtime
automatically (like `sfx`/`music`).

## Where a `.gtm2` comes from

Two ways to get the bytes:

### From a MIDI (the usual path)

Clyde's official `midiconvert.js` (in the GameTank C SDK) turns a `.mid` into a
`.gtm2`, choosing an FM instrument per channel. Feed the resulting bytes to
`hexdata`. Because gt-lua uses the exact same format, its output plays here
unchanged.

### Hand-authored (small cues, jingles)

`compiler/gtm2.mjs` builds a `.gtm2` from a simple event list — no MIDI needed:

```js
import { encodeGtm2, noteNum } from "gametank-lua-sdk/compiler/gtm2.mjs";
import { writeFileSync } from "node:fs";

const song = {
  instruments: ["PIANO", "BASS", "SNARE", "HORN"],   // one per channel 0..3
  events: [
    { delay: 10, notes: { 0: noteNum("c4") } },      // ch0 plays C4
    { delay: 20, notes: { 0: noteNum("e4") } },
    { delay: 20, notes: { 0: noteNum("g4"), 1: noteNum("c3") } },  // chord across channels
    { delay: 20, notes: { 0: 0 } },                  // note 0 = key off
  ],
};
writeFileSync("tune.gtm2", encodeGtm2(song));
```

Then hex-encode the file into your Lua (`hexdata`). A `parseGtm2` is provided for
reading/round-tripping existing songs.

## The event model

A `.gtm2` is a header plus a linear event stream:

- **Header**: a config byte (bit0 = per-note velocity present) and **four
  instrument indices**, one per FM channel.
- **Events**: each carries a `delay` (frames before it fires) and, for each of
  the four channels that changes, a **note** (1-based MIDI; `0` = key off) and,
  in velocity mode, a velocity. Long gaps split into padding events automatically.

Four channels play at once. `delay` is in frames (≈60/second on NTSC), so timing
is exact and independent of how long your game's frame takes.

## Instruments

The 10 built-in FM voices (by name for the authoring helper, or index):

| # | name | | # | name |
|--:|------|--|--:|------|
| 0 | PIANO  | | 5 | HORN |
| 1 | GUITAR | | 6 | BELL |
| 2 | BASS   | | 7 | BLIP |
| 3 | SNARE  | | 8 | CHIP |
| 4 | SITAR  | | 9 | CHIP2 |

`CHIP` / `CHIP2` are the pitch-exact chiptune voices; the others are voiced
instruments. Pick per channel in the song header.

## Coming from PICO-8

PICO-8 music is a different synth (per-note waveforms), so it's a
re-interpretation, not a copy — `bin/p8sfx.mjs` converts a cart's `__sfx__`/
`__music__` into the FM `sfx`/`music` path (see [sfx.md](sfx.md) and
[PORTING.md](PORTING.md)). `.gtm2` is the other direction: **authoring natively**
for the FM synth (from MIDI or by hand), which is the better fit for music-forward
games. Both play on the same coprocessor.
