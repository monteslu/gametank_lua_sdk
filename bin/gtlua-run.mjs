// gtlua-run.mjs - play a .gtr in a window via the shared romdev SDL host.
//
// Thin shim over romdev-core-runner (the one SDL host in the ecosystem). It
// loads the bundled GameTank core and maps the keyboard to the GameTank pad:
//   arrows = d-pad, Z = A (RETRO_A), X = B (RETRO_B), C = C (RETRO_Y),
//   Enter = START, RShift = SELECT.
// If @kmamal/sdl isn't installed the runner throws { code:"SDL_UNAVAILABLE" };
// we re-throw so the CLI can fall back to an external emulator.

import { runRom as runRomInWindow } from "romdev-core-runner";
import * as core from "romdev-core-gametank";

// Keyboard -> libretro RetroPad bit (see romdev-core-runner bitToName).
const keyMap = { up: 4, down: 5, left: 6, right: 7, z: 8, x: 0, c: 1, return: 3, rshift: 2 };
// Gamepad: bottom = A, right = B, left/top = C, so a pad matches the keys.
const buttonMap = { dpadUp: 4, dpadDown: 5, dpadLeft: 6, dpadRight: 7, a: 8, b: 0, x: 1, y: 1, back: 2, guide: 2, start: 3 };

export async function runRom(romPath, opts = {}) {
  const session = await runRomInWindow(romPath, { core, keyMap, buttonMap, scale: 4, ...opts });
  await session.closed;
}
