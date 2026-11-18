import assert from "node:assert/strict";
import { after, before, test } from "node:test";
import { CapitalDemoRuntime, createCapitalDemoRuntime } from "../dist/market-data/capital-demo-runtime.js";
import { BrokerSessionManager } from "../dist/market-data/broker-session-manager.js";
import { CapitalDemoApiError, CapitalDemoClient } from "../dist/market-data/capital-demo-client.js";
import { createApiServer } from "../dist/server.js";

const credentials = {
  CAPITAL_COM_DEMO_API_KEY: "demo-key",
  CAPITAL_COM_DEMO_IDENTIFIER: "demo-user",
  CAPITAL_COM_DEMO_PASSWORD: "demo-password",
};

const trackedRuntimes = new Set();
const trackedManagers = new Set();

function createTrackedRuntime(...args) {
  const runtime = new CapitalDemoRuntime(...args);
  trackedRuntimes.add(runtime);
  return runtime;
}

function createTrackedManager(...args) {
  const manager = new BrokerSessionManager(...args);
  trackedManagers.add(manager);
  return manager;
}

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
    async getPriceHistory(session, epic, resolution, max, from, to) {
      calls.push(["history", session, epic, resolution, max, from, to]);
      const candle = {
        snapshotTimeUTC: "2026-11-17T10:00:00",
        openPrice: { bid: 100, ask: 100.2 },
        highPrice: { bid: 103, ask: 103.2 },
        lowPrice: { bid: 99, ask: 99.2 },
        closePrice: { bid: 102, ask: 102.2 },
        lastTradedVolume: 18,
      };
      return {
        prices: epic === "AAPL-DUPLICATE" ? [{ ...candle }, { ...candle }] : [candle],
      };
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
  const runtime = createTrackedRuntime(client, {
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
  const runtime = createTrackedRuntime(client, {
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
  const runtime = createTrackedRuntime(client, {
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
  const runtime = createTrackedRuntime(client, {
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

test("network timeouts degrade session health without discarding an unconfirmed session", async () => {
  const client = createMockClient();
  let failedOnce = false;
  client.getMarkets = async (session, searchTerm) => {
    client.calls.push(["markets", session, searchTerm]);
    if (!failedOnce) {
      failedOnce = true;
      throw new TypeError("fetch failed");
    }
    return { markets: [{ epic: "AAPL" }] };
  };
  const runtime = createTrackedRuntime(client, {
    apiKey: "demo-key",
    identifier: "demo-user",
    password: "demo-password",
  }, Date.now, {
    scheduler: { schedule: () => "timer", cancel: () => {} },
  });

  await runtime.connect();
  await assert.rejects(runtime.getMarkets("Apple"), /fetch failed/);
  assert.equal(runtime.status().state, "degraded");

  // A successful authenticated keepalive restores the existing session.
  await runtime.connect();
  assert.equal(runtime.status().state, "connected");
  assert.equal((await runtime.getMarkets("Apple")).markets[0].epic, "AAPL");
  assert.equal(client.calls.filter((call) => call[0] === "connect").length, 1);
  assert.equal(client.calls.filter((call) => call[0] === "disconnect").length, 0);
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
  const runtime = createTrackedRuntime(client, {
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
  const runtime = createTrackedRuntime(client, {
    apiKey: "demo-key",
    identifier: "demo-user",
    password: "demo-password",
  });
  await assert.rejects(runtime.connect(), /HTTP 401/);
  assert.equal(runtime.status().state, "error");
  assert.equal(JSON.stringify(runtime.status()).includes("demo-password"), false);
});

test("provider credential rejection blocks automatic session recreation until credentials are explicitly replaced", async () => {
  const client = createMockClient();
  client.startSession = async (value) => {
    client.calls.push(["connect", value]);
    throw new CapitalDemoApiError("authentication rejected HTTP 401", 401);
  };
  const runtime = createTrackedRuntime(client, {
    apiKey: "demo-key",
    identifier: "demo-user",
    password: "demo-password",
  }, Date.now, {
    scheduler: { schedule: () => "timer", cancel: () => {} },
  });

  await assert.rejects(runtime.connect(), /HTTP 401/);
  assert.equal(runtime.status().state, "error");
  await runtime.connect();
  assert.equal(client.calls.filter((call) => call[0] === "connect").length, 1);
});

test("broker session manager preserves creation throttling across account replacement", async () => {
  let now = 1_800_000_000_000;
  let factoryCalls = 0;
  const client = createMockClient();
  const manager = createTrackedManager(
    (value) => {
      factoryCalls += 1;
      return createTrackedRuntime(client, value, () => now);
    },
    () => now,
    10_000,
  );
  const firstCredentials = {
    apiKey: "first-key",
    identifier: "first-user",
    password: "first-password",
  };
  const secondCredentials = {
    apiKey: "second-key",
    identifier: "second-user",
    password: "second-password",
  };

  assert.equal((await manager.connect(firstCredentials)).state, "connected");
  const throttled = await manager.connect(secondCredentials);
  assert.equal(throttled.state, "error");
  assert.match(throttled.lastError, /rate-limited/);
  assert.equal(factoryCalls, 1);
  assert.equal(manager.status().state, "connected");

  now += 10_000;
  assert.equal((await manager.connect(secondCredentials)).state, "connected");
  assert.equal(factoryCalls, 2);
  assert.deepEqual(client.calls.map((call) => call[0]), ["connect", "disconnect", "connect"]);
  await manager.disconnect();
});

test("broker session manager preserves the shared REST request budget across runtime replacement", async () => {
  const waits = [];
  const calls = [];
  let monotonicNow = 0;
  let wallClockNow = 1_800_000_000_000;
  const client = new CapitalDemoClient(async (url, init) => {
    const path = new URL(String(url)).pathname;
    calls.push({ path, method: init?.method ?? "GET" });
    if (path === "/api/v1/session" && init?.method === "POST") {
      return new Response("{}", {
        status: 200,
        headers: { CST: "demo-cst", "X-SECURITY-TOKEN": "demo-security-token" },
      });
    }
    if (path === "/api/v1/session" && init?.method === "DELETE") {
      return new Response(null, { status: 200 });
    }
    return new Response(JSON.stringify({ markets: [] }), {
      status: 200,
      headers: { "Content-Type": "application/json" },
    });
  }, () => wallClockNow, {
    requestIntervalMs: 100,
    monotonicNow: () => monotonicNow,
    sleep: async (milliseconds) => {
      waits.push(milliseconds);
      monotonicNow += milliseconds;
    },
  });
  const manager = createTrackedManager(undefined, () => wallClockNow, 0, client);

  assert.equal((await manager.connect({
    apiKey: "demo-key",
    identifier: "demo-user",
    password: "first-password",
  })).state, "connected");
  await manager.getMarkets("Apple");
  await manager.disconnect();

  wallClockNow += 1_000;
  assert.equal((await manager.connect({
    apiKey: "demo-key",
    identifier: "demo-user",
    password: "second-password",
  })).state, "connected");
  await manager.getMarkets("Apple");
  await manager.disconnect();

  assert.equal(calls.length, 6);
  assert.deepEqual(waits, [100, 100, 100, 100, 100]);
});

test("broker session manager enforces Capital.com one-session-per-second limit", async () => {
  let now = 1_800_000_000_000;
  const client = createMockClient();
  const manager = createTrackedManager(
    (value) => createTrackedRuntime(
      client,
      value,
      () => now,
      { scheduler: { schedule: () => "timer", cancel: () => {} } },
    ),
    () => now,
  );
  const credentials = {
    apiKey: "demo-key",
    identifier: "demo-user",
    password: "demo-password",
  };

  assert.equal((await manager.connect(credentials)).state, "connected");
  now += 999;
  const limited = await manager.connect(credentials);
  assert.equal(limited.state, "error");
  assert.match(limited.lastError, /Retry in 1 second/);
  assert.equal(client.calls.filter((call) => call[0] === "connect").length, 1);

  now += 1;
  assert.equal((await manager.connect(credentials)).state, "connected");
  assert.equal(client.calls.filter((call) => call[0] === "connect").length, 2);
  await manager.disconnect();
});

test("broker session manager permits explicit re-submission of the same rejected credentials", async () => {
  let now = 1_800_000_000_000;
  const client = createMockClient();
  client.startSession = async (value) => {
    client.calls.push(["connect", value]);
    throw new CapitalDemoApiError("authentication rejected HTTP 401", 401);
  };
  const manager = createTrackedManager(
    (value) => createTrackedRuntime(
      client,
      value,
      () => now,
      { scheduler: { schedule: () => "timer", cancel: () => {} } },
    ),
    () => now,
  );
  const rejectedCredentials = {
    apiKey: "demo-key",
    identifier: "demo-user",
    password: "rejected-password",
  };

  assert.equal((await manager.connect(rejectedCredentials)).state, "error");
  now += 1_000;
  const automaticRetry = await manager.connect();
  assert.equal(automaticRetry.state, "error");
  assert.equal(client.calls.filter((call) => call[0] === "connect").length, 1);

  now += 1_000;
  assert.equal((await manager.connect(rejectedCredentials)).state, "error");
  assert.equal(client.calls.filter((call) => call[0] === "connect").length, 2);
});

test("broker session manager releases credential-bearing runtime after provider logout failure", async () => {
  const client = createMockClient();
  client.endSession = async () => {
    throw new Error("provider logout unavailable");
  };
  const manager = createTrackedManager((value) => createTrackedRuntime(
    client,
    value,
    () => 1_800_000_000_000,
    { scheduler: { schedule: () => "timer", cancel: () => {} } },
  ));

  const connected = await manager.connect({
    apiKey: "demo-key",
    identifier: "demo-user",
    password: "demo-password",
  });
  assert.equal(connected.state, "connected");

  await assert.rejects(manager.disconnect(), /provider logout unavailable/);
  assert.equal(manager.status().state, "not_configured");
});

const ipcCapability = Buffer.alloc(32, 7);
const authorization = { authorization: "Bearer " + ipcCapability.toString("base64url") };
const serverClient = createMockClient();
const serverRuntime = createTrackedManager(
  (value) => createTrackedRuntime(
    serverClient,
    value,
    () => 1_800_000_000_000,
  ),
  () => 1_800_000_000_000,
);
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
  await Promise.allSettled([
    ...Array.from(trackedManagers, (manager) => manager.disconnect()),
    ...Array.from(trackedRuntimes, (runtime) => runtime.disconnect()),
  ]);
  const closed = new Promise((resolve, reject) => {
    server.close((error) => (error ? reject(error) : resolve()));
  });
  server.closeAllConnections();
  await closed;
});

test("market-data and broker-session routes reject requests without the private IPC capability", async () => {
  const response = await fetch(baseUrl + "/market-data/status");
  assert.equal(response.status, 401);
  assert.deepEqual(await response.json(), { error: "unauthorized" });
  const invalid = await fetch(baseUrl + "/broker-session/status", { headers: { authorization: "Bearer invalid" } });
  assert.equal(invalid.status, 401);
});

test("broker session status is truthful and never returns provider session tokens", async () => {
  const response = await fetch(baseUrl + "/broker-session/status", { headers: authorization });
  const payload = await response.json();
  assert.equal(response.status, 200);
  assert.equal(payload.environment, "DEMO");
  assert.equal(payload.state, "not_configured");
  assert.equal(JSON.stringify(payload).includes("secret-cst"), false);
});

test("broker credentials and disconnect are not accepted by the HTTP API", async () => {
  for (const [path, body, contentType] of [
    ["/broker-session/connect", JSON.stringify({ apiKey: "demo-key", identifier: "demo-user", password: "demo-password" }), "application/json"],
    ["/broker-session/connect", "{", "application/json"],
    ["/broker-session/connect", JSON.stringify({ apiKey: "demo-key", identifier: "demo-user", password: "demo-password", environment: "LIVE" }), "application/json"],
    ["/broker-session/disconnect", undefined, undefined],
  ]) {
    const headers = { ...authorization };
    if (contentType) headers["content-type"] = contentType;
    const response = await fetch(baseUrl + path, {
      method: "POST",
      headers,
      ...(body === undefined ? {} : { body }),
    });
    assert.equal(response.status, 404);
  }
  assert.equal(serverRuntime.status().state, "not_configured");
});


test("authenticated historical route normalizes candles and preserves raw provider pagination", async () => {
  const from = "2026-11-17T10:00:00Z";
  const to = "2026-11-17T11:00:00Z";

  const incomplete = await fetch(
    baseUrl + "/market-data/history?epic=AAPL&from=" + encodeURIComponent(from),
    { headers: authorization },
  );
  assert.equal(incomplete.status, 400);
  assert.deepEqual(await incomplete.json(), { error: "incomplete_date_range" });

  const invalidDate = await fetch(
    baseUrl + "/market-data/history?epic=AAPL&from=2026-02-31T10%3A00%3A00Z&to=" + encodeURIComponent(to),
    { headers: authorization },
  );
  assert.equal(invalidDate.status, 400);
  assert.deepEqual(await invalidDate.json(), { error: "invalid_date_range" });

  const invalidMax = await fetch(
    baseUrl + "/market-data/history?epic=AAPL&max=1001",
    { headers: authorization },
  );
  assert.equal(invalidMax.status, 400);
  assert.deepEqual(await invalidMax.json(), { error: "invalid_max" });

  const disconnected = await fetch(
    baseUrl + "/market-data/history?epic=AAPL&resolution=MINUTE&max=10",
    { headers: authorization },
  );
  assert.equal(disconnected.status, 503);
  assert.deepEqual(await disconnected.json(), { error: "broker_session_not_connected" });

  await serverRuntime.connect({
    apiKey: "demo-key",
    identifier: "demo-user",
    password: "demo-password",
  });
  const response = await fetch(
    baseUrl + "/market-data/history?epic=AAPL&resolution=MINUTE&max=10&from=" +
      encodeURIComponent(from) + "&to=" + encodeURIComponent(to),
    { headers: authorization },
  );
  const payload = await response.json();

  assert.equal(response.status, 200);
  assert.equal(payload.provider, "capital.com");
  assert.equal(payload.environment, "DEMO");
  assert.equal(payload.instrumentId, "AAPL");
  assert.equal(payload.candles.length, 1);
  assert.deepEqual(payload.candles[0].bid, { open: 100, high: 103, low: 99, close: 102 });
  assert.deepEqual(payload.candles[0].ask, { open: 100.2, high: 103.2, low: 99.2, close: 102.2 });
  assert.equal(payload.candles[0].providerVolumeField, "lastTradedVolume");
  assert.equal(payload.request.from, from);
  assert.equal(payload.request.to, to);
  assert.equal(payload.pagination.limitReached, false);
  assert.equal(JSON.stringify(payload).includes("secret-cst"), false);
  assert.equal(JSON.stringify(payload).includes("secret-security-token"), false);

  const historyCall = serverClient.calls.filter((call) => call[0] === "history").at(-1);
  assert.deepEqual(historyCall.slice(2), ["AAPL", "MINUTE", 10, from, to]);

  const duplicateResponse = await fetch(
    baseUrl + "/market-data/history?epic=AAPL-DUPLICATE&resolution=MINUTE&max=2",
    { headers: authorization },
  );
  const duplicatePayload = await duplicateResponse.json();
  assert.equal(duplicateResponse.status, 200);
  assert.equal(duplicatePayload.candles.length, 1);
  assert.equal(duplicatePayload.quality.duplicateCount, 1);
  assert.equal(duplicatePayload.pagination.limitReached, true);

  await serverRuntime.disconnect();
});

test("HTTP broker credential routes remain absent and market data rejects invalid resolutions", async () => {
  const credentialRoute = await fetch(baseUrl + "/broker-session/connect", { headers: authorization });
  assert.equal(credentialRoute.status, 404);
  const invalidResolution = await fetch(baseUrl + "/market-data/history?epic=AAPL&resolution=INVALID", { headers: authorization });
  assert.equal(invalidResolution.status, 400);
});
