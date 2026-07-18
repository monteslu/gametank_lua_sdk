// gtlua compiler entry - binds gtlua's identity + builtins to the shared
// luacretro front-end. (The compiler itself lives in the luacretro package;
// this SDK owns the GameTank builtins + runtime + build pipeline.)

import { compile as core, formatDiagnostics } from "luacretro";
import { BUILTINS, GT_MEMBERS, CALLBACKS, P8_PALETTE } from "./builtins.js";
import { nearestColorByte } from "./gt_palette.js";

// The GameTank target descriptor. luacretro is platform-agnostic: THIS SDK
// tells it how GameTank's C runtime is named + shaped. caps = compiler
// behaviors; harness = the frame-loop symbol schema.
const TARGET = {
  caps: {
    zpFastcall: true, zpUserFn: true, fixedZp: true,
    banked: true, nativeDiv: false, colorBake: true, framebuffer: true,
    prefix: "gt", finalRename: true,
  },
  harness: {
    signature: "void main(void)",
    init: ["gt_init", "gt_sheet_init"],
    onAudio: "gt_audio_init", onMusic: "gt_music_init", onFps30: "gt_fps30",
    loopTop: ["gt_update_inputs"], frameEnd: "gt_endframe",
    fps30Style: "runtime", returns: false, includes: ["gt_api.h"],
  },
};

export function compile(source, file = "main.lua", opts = {}) {
  return core(source, file, {
    sdkName: "gtlua",
    builtins: BUILTINS,
    members: GT_MEMBERS,
    callbacks: CALLBACKS,
    p8Palette: P8_PALETTE,
    nearestColorByte,
    ...opts,
    target: TARGET,   // the SDK OWNS its target - not overridable by callers
  });
}

export { formatDiagnostics };
