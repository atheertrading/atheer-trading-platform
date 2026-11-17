import assert from "node:assert/strict";
import { test } from "node:test";
import { CapitalDemoApiError } from "../dist/market-data/capital-demo-client.js";
import { CapitalDemoRuntime } from "../dist/market-data/capital-demo-runtime.js";

const credentials = { apiKey: "demo-key", identifier: "demo-user", password: "demo-password" };
const session = {
  cst: "demo-cst",
  securityToken: "demo-security-token",
  createdAtMs: 1_800_000_000_000,
  environment: "DEMO",
};

test("concurrent connect requests share one provider session creation", async () => {
  let starts = 0;
  const client = {
    async startSession() {
      starts += 1;
      return session;
    },
    async endSession() {},
  };
  const runtime = new CapitalDemoRuntime(client, credentials);
  const [first, second] = await Promise.all([runtime.connect(), runtime.connect()]);
  assert.equal(starts, 1);
  assert.equal(first.state, "connected");
  assert.equal(second.state, "connected");
});

test("disconnect during authentication invalidates and closes the late session", async () => {
  let resolveSession;
  let ended = 0;
  const client = {
    startSession() {
      return new Promise((resolve) => { resolveSession = resolve; });
    },
    async endSession() { ended += 1; },
  };
  const runtime = new CapitalDemoRuntime(client, credentials);
  const connecting = runtime.connect();
  const disconnecting = runtime.disconnect();
  resolveSession(session);
  await disconnecting;
  await connecting;
  assert.equal(ended, 1);
  assert.equal(runtime.status().state, "disconnected");
});

test("expired provider session is invalidated and cannot continue serving market data", async () => {
  const client = {
    async startSession() { return session; },
    async endSession() {},
    async getMarkets() { throw new CapitalDemoApiError("unauthorized", 401); },
  };
  const runtime = new CapitalDemoRuntime(client, credentials);
  await runtime.connect();
  await assert.rejects(runtime.getMarkets("Apple"), /unauthorized/);
  assert.equal(runtime.status().state, "disconnected");
  await assert.rejects(runtime.getMarkets("Apple"), /not connected/);
});
