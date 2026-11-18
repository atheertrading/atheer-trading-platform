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

  assert.equal(completed, "succeeded");
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

  assert.equal(completed, "failed");
  assert.deepEqual(diagnostics, ["ATHEER API shutdown broker_session failed."]);
  assert.equal(diagnostics.join(" ").includes("secret-session-token"), false);
});

test("bounded shutdown step reports a timeout without claiming its action was cancelled", async () => {
  const diagnostics = [];
  let releaseAction;
  let actionSettled = false;
  const action = new Promise((resolve) => {
    releaseAction = () => {
      actionSettled = true;
      resolve();
    };
  });

  const outcome = await runBoundedShutdownStep(
    "market_data_stream",
    () => action,
    5,
    (message) => diagnostics.push(message),
  );

  assert.equal(outcome, "timed_out");
  assert.equal(actionSettled, false);
  assert.deepEqual(diagnostics, ["ATHEER API shutdown market_data_stream timed_out."]);

  releaseAction();
  await action;
  assert.equal(actionSettled, true);
});
