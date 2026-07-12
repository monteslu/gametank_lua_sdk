# ports/ — PICO-8 games adapted for the GameTank

gtlua adaptations of well-loved PICO-8 games — used to exercise and showcase the
SDK. Each derives from an existing cart, so it carries the original's license and
attribution (per-directory `LICENSE`).

## Featured ports live in their own repos

The polished, playable ports have moved to standalone repositories for clear
attribution (each is a derivative work under its own license, kept separate from
the MIT-licensed SDK):

| Port | Inspired by | Repo |
|---|---|---|
| Combo Pool | NuSan (PICO-8, p8jam2) | `gtlua-ports/combo-pool` |
| newleste | Celeste Classic / CelesteClassic community | `gtlua-ports/newleste` |
| Cherry Bomb | Krystman / Lazy Devs Academy | `gtlua-ports/cherry-bomb` |

Build each from its own directory against a gt-lua checkout — see the repo's
`README.md`.

## In-development ports (here)

Work-in-progress adaptations and demos still living in the SDK tree. Build any of
them with (some need `--num8` or extra flags — see each `PORT_NOTES.md`):

```sh
node bin/gtlua.js build ports/<name>/main.lua --sheet ports/<name>/gfx.gtg
```

`driftmania` · `celeste2` · `just-one-boss` · `ufo-swamp` · `jelpi` ·
`celeste-like` · `celeste`

GameTank buttons: 🅾️ = GT A, ❎ = GT B, and GT C is a bonus button PICO-8 has no
equivalent for (`btn(6)`).

Adaptations of licensed games inherit the original's terms (attribution;
CC-BY-NC-SA where applicable — non-commercial, share-alike). They are showcase
ROMs, not products. The SDK itself stays MIT; these directories are
license-firewalled.
