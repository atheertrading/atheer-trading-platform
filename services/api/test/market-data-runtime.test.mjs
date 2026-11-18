import assert from "node:assert/strict";
import { after, before, test } from "node:test";
import { CapitalDemoRuntime, createCapitalDemoRuntime } from "../dist/market-data/capital-demo-runtime.js";
import { CapitalDemoApiError } from "../dist/market-data/capital-demo-client.js";
import { createApiServer } from "../dist/server.js";

const credentials = {
  CAPITAL_COM_DEMO_API_KEY: "demo-key",
  CAPITAL_COM_DEMO_IDENTIFIER: "demo-user",
  CAPITAL_COM_DEMO_PASSWORD: "demo-password",
};

function createMockClient() {
  const calls = [];
  return {
    calls,
    async startSession(value) {
      calls.push(["connect", value]);
      return {
        cst: "secret-cst",
        securityToken: "secret-security-token",
        createdAtMs: 1_800_000_000_000,
        environment: "DEMO",
      };
    },
    async endSession(session) {
      calls.push(["disconnect", session]);
    },
    async getMarkets(session, searchTerm) {
      calls.push(["markets", session, searchTerm]);
      return { markets: [{ epic: "AAPL" }] };
    },
    async getPriceHistory(session, epic, resolution, max) {
      calls.push(["history", session, epic, resolution, max]);
      return { prices: [] };
    },
    async ping(session) {
      calls.push(["ping", session]);
    },
  };
}

test("runtime reports unconfigured without complete DEMO credentials", async () => {
  const runtime = createCapitalDemoRuntime({
    CAPITAL_COM_DEMO_API_KEY: "demo-key",
    CAPITAL_COM_DEMO_IDENTIFIER: "demo-user",
  }, createMockClient());
  assert.equal(runtime.status().state, "not_configured");
  assert.equal((await runtime.connect()).state, "not_configured");
});

test("runtime connects, reads market data, and disconnects without exposing session tokens", async () => {
  const client = createMockClient();
  const runtime = new CapitalDemoRuntime(client, {
    apiKey: "demo-key",
    identifier: "demo-user",
    password: "demo-password",
  }, () => 1_800_000_000_000);

  assert.equal((await runtime.connect()).state, "connected");
  const markets = await runtime.getMarkets("Apple");
  assert.equal(markets.markets[0].epic, "AAPL");
  const status = runtime.status();
  assert.equal(status.environment, "DEMO");
  assert.equal(status.state, "connected");
  assert.equal(JSON.stringify(status).includes("secret-cst"), false);
  assert.equal(JSON.stringify(status).includes("secret-security-token"), false);
  assert.equal((await runtime.disconnect()).state, "disconnected");
  assert.deepEqual(client.calls.map((call) => call[0]), ["connect", "markets", "disconnect"]);
});

test("session creation is throttled to one attempt per second across reconnects", async () => {
  let now = 1_800_000_000_000;
  const waits = [];
  const client = createMockClient();
  const runtime = new CapitalDemoRuntime(client, {
    apiKey: "demo-key",
    identifier: "demo-user",
    password: "demo-password",
  }, () => now, {
    sessionCreationIntervalMs: 1_000,
    keepaliveIntervalMs: 300_000,
    sleep: async (milliseconds) => {
      waits.push(milliseconds);
      now += milliseconds;
    },
    scheduler: { schedule: () => "timer", cancel: () => {} },
  });

  await runtime.connect();
  await runtime.disconnect();
  await runtime.connect();

  assert.deepEqual(waits, [1_000]);
  assert.equal(client.calls.filter((call) => call[0] === "connect").length, 2);
  await runtime.disconnect();
});

test("REST keepalive is scheduled, renews session activity, and stops on disconnect", async () => {
  const client = createMockClient();
  let scheduledInterval = 0;
  let scheduledTask = null;
  let cancelled = false;
  const scheduler = {
    schedule(task, intervalMs) {
      scheduledTask = task;
      scheduledInterval = intervalMs;
      return "keepalive";
    },
    cancel(handle) {
      assert.equal(handle, "keepalive");
      cancelled = true;
    },
  };
  const runtime = new CapitalDemoRuntime(client, {
    apiKey: "demo-key",
    identifier: "demo-user",
    password: "demo-password",
  }, Date.now, { keepaliveIntervalMs: 300_000, scheduler });

  await runtime.connect();
  assert.equal(scheduledInterval, 300_000);
  assert.equal(typeof scheduledTask, "function");
  await scheduledTask();
  assert.equal(client.calls.filter((call) => call[0] === "ping").length, 1);
  assert.equal(runtime.status().state, "connected");

  await runtime.disconnect();
  assert.equal(cancelled, true);
});

test("temporary keepalive failures degrade the session and a successful ping restores it", async () => {
  const client = createMockClient();
  client.ping = async (session) => {
    client.calls.push(["ping", session]);
    throw new CapitalDemoApiError("provider unavailable HTTP 503", 503);
  };
  const runtime = new CapitalDemoRuntime(client, {
    apiKey: "demo-key",
    identifier: "demo-user",
    password: "demo-password",
  }, Date.now, {
    scheduler: { schedule: () => "timer", cancel: () => {} },
  });

  await runtime.connect();
  await assert.rejects(runtime.ping(), /503/);
  assert.equal(runtime.status().state, "degraded");
  assert.match(runtime.status().lastError, /degraded/);

  client.ping = async (session) => { client.calls.push(["ping", session]); };
  await runtime.ping();
  assert.equal(runtime.status().state, "connected");
  assert.equal(runtime.status().lastError, undefined);
  await runtime.disconnect();
});

test("scheduled keepalive contains transient failures and recovers without an unhandled rejection", async () => {
  const client = createMockClient();
  client.ping = async (session) => {
    client.calls.push(["ping", session]);
    throw new CapitalDemoApiError("provider unavailable HTTP 503", 503);
  };
  let scheduledTask = null;
  const scheduler = {
    schedule(task) {
      scheduledTask = task;
      return "keepalive";
    },
    cancel() {},
  };
  const runtime = new CapitalDemoRuntime(client, {
    apiKey: "demo-key",
    identifier: "demo-user",
    password: "demo-password",
  }, Date.now, { scheduler });

  await runtime.connect();
  assert.equal(typeof scheduledTask, "function");

  // Timer callbacks must settle normally; runKeepalive records degraded state.
  await scheduledTask();
  assert.equal(runtime.status().state, "degraded");

  client.ping = async (session) => { client.calls.push(["ping", session]); };
  await scheduledTask();
  assert.equal(runtime.status().state, "connected");
  assert.equal(runtime.status().lastError, undefined);
  await runtime.disconnect();
});

test("runtime marks failed provider authentication as error without leaking credentials", async () => {
  const client = createMockClient();
  client.startSession = async () => { throw new Error("Capital.com DEMO session creation failed with HTTP 401."); };
  const runtime = new CapitalDemoRuntime(client, {
    apiKey: "demo-key",
    identifier: "demo-user",
    password: "demo-password",
  });
  await assert.rejects(runtime.connect(), /HTTP 401/);
  assert.equal(runtime.status().state, "error");
  assert.equal(JSON.stringify(runtime.status()).includes("demo-password"), false);
});

const ipcCapability = Buffer.alloc(32, 7);
const authorization = { authorization: "Bearer " + ipcCapability.toString("base64url") };
const serverClient = createMockClient();
const serverRuntime = new CapitalDemoRuntime(serverClient, {
  apiKey: "demo-key",
  identifier: "demo-user",
  password: "demo-password",
});
const server = createApiServer(serverRuntime, ipcCapability);
let baseUrl;

before(async () => {
  await new Promise((resolve, reject) => {
    server.once("error", reject);
    server.listen(0, "127.0.0.1", resolve);
  });
  const address = server.address();
  assert.ok(address && typeof address !== "string");
  baseUrl = "http://127.0.0.1:" + address.port;
});

after(async () => {
  await new Promise((resolve, reject) => {
    server.close((error) => (error ? reject(error) : resolve()));
  });
});

test("market-data routes reject requests without the private IPC capability", async () => {
  const response = await fetch(baseUrl + "/market-data/status");
  assert.equal(response.status, 401);
  assert.deepEqual(await response.json(), { error: "unauthorized" });
  const invalid = await fetch(baseUrl + "/market-data/status", { headers: { authorization: "Bearer invalid" } });
  assert.equal(invalid.status, 401);
});

test("market-data status is truthful and never returns provider session tokens", async () => {
  const response = await fetch(baseUrl + "/market-data/status", { headers: authorization });
  const payload = await response.json();
  assert.equal(response.status, 200);
  assert.equal(payload.environment, "DEMO");
  assert.equal(payload.state, "disconnected");
  assert.equal(JSON.stringify(payload).includes("secret-cst"), false);
});

test("loopback market-data routes connect and return DEMO market results only", async () => {
  const connect = await fetch(baseUrl + "/market-data/connect", { method: "POST", headers: authorization });
  assert.equal(connect.status, 200);
  const markets = await fetch(baseUrl + "/market-data/markets?searchTerm=Apple", { headers: authorization });
  const payload = await markets.json();
  assert.equal(markets.status, 200);
  assert.equal(payload.environment, "DEMO");
  assert.equal(payload.markets[0].epic, "AAPL");
  assert.equal(JSON.stringify(payload).includes("secret-cst"), false);
  const disconnect = await fetch(baseUrl + "/market-data/disconnect", { method: "POST", headers: authorization });
  assert.equal(disconnect.status, 200);
  assert.equal((await disconnect.json()).state, "disconnected");
});

test("market-data routes reject wrong methods and invalid resolutions", async () => {
  const wrongMethod = await fetch(baseUrl + "/market-data/connect", { headers: authorization });
  assert.equal(wrongMethod.status, 405);
  assert.equal(wrongMethod.headers.get("allow"), "POST");
  const invalidResolution = await fetch(baseUrl + "/market-data/history?epic=AAPL&resolution=INVALID", { headers: authorization });
  assert.equal(invalidResolution.status, 400);
});
