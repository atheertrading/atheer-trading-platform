import assert from "node:assert/strict";
import { test } from "node:test";
import { runBoundedShutdownStep } from "../dist/shutdown.js";

test("bounded shutdown step reports success without diagnostics", async () => {
  const diagnostics = [];
  const completed = await runBoundedShutdownStep(
    "broker_session",
    async () => "disconnected",
    100,
    (message) => diagnostics.push(message),
  );

  assert.equal(completed, true);
  assert.deepEqual(diagnostics, []);
});

test("bounded shutdown step contains failures without exposing provider details", async () => {
  const diagnostics = [];
  const completed = await runBoundedShutdownStep(
    "broker_session",
    async () => { throw new Error("secret-session-token"); },
    100,
    (message) => diagnostics.push(message),
  );

  assert.equal(completed, false);
  assert.deepEqual(diagnostics, ["ATHEER API shutdown broker_session failed."]);
  assert.equal(diagnostics.join(" ").includes("secret-session-token"), false);
});

test("bounded shutdown step times out and records a redacted diagnostic", async () => {
  const diagnostics = [];
  const completed = await runBoundedShutdownStep(
    "market_data_stream",
    () => new Promise(() => {}),
    5,
    (message) => diagnostics.push(message),
  );

  assert.equal(completed, false);
  assert.deepEqual(diagnostics, ["ATHEER API shutdown market_data_stream timed_out."]);
});
