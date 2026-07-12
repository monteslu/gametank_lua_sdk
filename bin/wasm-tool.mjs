#!/usr/bin/env node
// wasm-tool.mjs - run ONE cc65-family WASM tool as a subprocess, so the
// synchronous build orchestrator in gtlua.js can drive it via spawnSync exactly
// like a native binary.
//
//   node bin/wasm-tool.mjs <cc65|ca65|ld65> <...toolArgs>
//
// It reads the tool args (the same argv you'd pass native cc65/ca65/ld65),
// runs the WASM tool in-process here, writes any -o outputs back to the host,
// prints the tool's log to stderr, and exits with the tool's status. Running it
// as a subprocess (rather than inline) keeps gtlua.js's build loop synchronous
// AND isolates a WASM abort from the parent build - the parent just sees a
// non-zero exit, same as a native tool failing.

import { runTool } from "../compiler/wasm_toolchain.js";

const [, , tool, ...args] = process.argv;
if (!tool) {
  process.stderr.write("usage: wasm-tool.mjs <cc65|ca65|ld65> <args...>\n");
  process.exit(2);
}

try {
  const r = await runTool(tool, args);
  if (r.stderr) process.stderr.write(r.stderr);
  process.exit(r.status);
} catch (e) {
  process.stderr.write(`wasm-tool ${tool}: ${e?.stack ?? e?.message ?? e}\n`);
  process.exit(1);
}
