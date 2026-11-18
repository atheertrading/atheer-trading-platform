import assert from "node:assert/strict";
import { spawn } from "node:child_process";
import { randomBytes } from "node:crypto";
import { fileURLToPath } from "node:url";
import { test } from "node:test";

const entrypoint = fileURLToPath(new URL("../dist/main.js", import.meta.url));
const workingDirectory = fileURLToPath(new URL("..", import.meta.url));

function waitForReady(child) {
  return new Promise((resolve, reject) => {
    let buffer = "";
    let settled = false;
    const timeout = setTimeout(() => finish(new Error("Backend startup readiness timed out.")), 8_000);

    const finish = (error, port) => {
      if (settled) return;
      settled = true;
      clearTimeout(timeout);
      child.stdout.off("data", onData);
      child.off("error", onError);
      child.off("exit", onExit);
      if (error) reject(error);
      else resolve(port);
    };

    const onData = (chunk) => {
      buffer += chunk.toString("utf8");
      const lines = buffer.split(/\r?\n/);
      buffer = lines.pop() ?? "";
      for (const line of lines) {
        const match = /^ATHEER_BACKEND_READY ([1-9]\d{0,4})$/.exec(line);
        if (match) {
          finish(undefined, Number(match[1]));
          return;
        }
      }
    };

    const onError = (error) => finish(error);
    const onExit = (code, signal) => {
      finish(new Error("Backend exited before readiness (code=" + code + ", signal=" + signal + ")."));
    };

    child.stdout.on("data", onData);
    child.once("error", onError);
    child.once("exit", onExit);
  });
}

async function stopChild(child) {
  if (child.exitCode !== null || child.signalCode !== null) return;
  const exited = new Promise((resolve) => child.once("exit", resolve));
  child.kill("SIGTERM");
  let timeout;
  await Promise.race([
    exited,
    new Promise((resolve) => { timeout = setTimeout(resolve, 3_000); }),
  ]);
  if (timeout) clearTimeout(timeout);
  if (child.exitCode === null && child.signalCode === null) {
    const killed = new Promise((resolve) => child.once("exit", resolve));
    child.kill("SIGKILL");
    await killed;
  }
}

test("managed backend bootstraps over stdin, binds an ephemeral loopback port, and authenticates IPC", async () => {
  const capability = randomBytes(32).toString("base64url");
  const child = spawn(process.execPath, [entrypoint], {
    cwd: workingDirectory,
    env: {
      PATH: process.env.PATH ?? "/usr/bin:/bin",
      NODE_ENV: "test",
      HOST: "127.0.0.1",
      PORT: "0",
      CAP_ALLOW_TRADING: "false",
    },
    stdio: ["pipe", "pipe", "ignore"],
  });

  try {
    const readyPromise = waitForReady(child);
    child.stdin.end(capability + "\n");
    const port = await readyPromise;
    const baseURL = "http://127.0.0.1:" + port;

    const live = await fetch(baseURL + "/health/live");
    assert.equal(live.status, 200);

    const unauthorized = await fetch(baseURL + "/market-data/status");
    assert.equal(unauthorized.status, 401);

    const authenticated = await fetch(baseURL + "/market-data/status", {
      headers: { authorization: "Bearer " + capability },
    });
    assert.equal(authenticated.status, 200);
    const payload = await authenticated.json();
    assert.equal(payload.provider, "capital.com");
    assert.equal(payload.environment, "DEMO");
    assert.equal(payload.state, "not_configured");
    assert.equal(JSON.stringify(payload).includes(capability), false);
  } finally {
    await stopChild(child);
  }
});
