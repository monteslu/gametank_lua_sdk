// gtlua compiler entry - binds gtlua's identity + builtins to the shared
// luacretro front-end. (The compiler itself lives in the luacretro package;
// this SDK owns the GameTank builtins + runtime + build pipeline.)

import { compile as core, formatDiagnostics } from "luacretro";
import { BUILTINS, GT_MEMBERS, CALLBACKS, P8_PALETTE } from "./builtins.js";
import { nearestColorByte } from "./gt_palette.js";

export function compile(source, file = "main.lua", opts = {}) {
  return core(source, file, {
    target: "gametank",
    sdkName: "gtlua",
    builtins: BUILTINS,
    members: GT_MEMBERS,
    callbacks: CALLBACKS,
    p8Palette: P8_PALETTE,
    nearestColorByte,
    ...opts,
  });
}

export { formatDiagnostics };
