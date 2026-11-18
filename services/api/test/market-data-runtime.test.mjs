import assert from "node:assert/strict";
import { after, before, test } from "node:test";
import { CapitalDemoRuntime, createCapitalDemoRuntime } from "../dist/market-data/capital-demo-runtime.js";
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

const serverClient = createMockClient();
const serverRuntime = new CapitalDemoRuntime(serverClient, {
  apiKey: "demo-key",
  identifier: "demo-user",
  password: "demo-password",
});
const server = createApiServer(serverRuntime);
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

test("market-data status is truthful and never returns provider session tokens", async () => {
  const response = await fetch(baseUrl + "/market-data/status");
  const payload = await response.json();
  assert.equal(response.status, 200);
  assert.equal(payload.environment, "DEMO");
  assert.equal(payload.state, "disconnected");
  assert.equal(JSON.stringify(payload).includes("secret-cst"), false);
});

test("loopback market-data routes connect and return DEMO market results only", async () => {
  const connect = await fetch(baseUrl + "/market-data/connect", { method: "POST" });
  assert.equal(connect.status, 200);
  const markets = await fetch(baseUrl + "/market-data/markets?searchTerm=Apple");
  const payload = await markets.json();
  assert.equal(markets.status, 200);
  assert.equal(payload.environment, "DEMO");
  assert.equal(payload.markets[0].epic, "AAPL");
  assert.equal(JSON.stringify(payload).includes("secret-cst"), false);
  const disconnect = await fetch(baseUrl + "/market-data/disconnect", { method: "POST" });
  assert.equal(disconnect.status, 200);
  assert.equal((await disconnect.json()).state, "disconnected");
});

test("market-data routes reject wrong methods and invalid resolutions", async () => {
  const wrongMethod = await fetch(baseUrl + "/market-data/connect");
  assert.equal(wrongMethod.status, 405);
  assert.equal(wrongMethod.headers.get("allow"), "POST");
  const invalidResolution = await fetch(baseUrl + "/market-data/history?epic=AAPL&resolution=INVALID");
  assert.equal(invalidResolution.status, 400);
});
