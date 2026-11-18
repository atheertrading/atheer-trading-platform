import assert from "node:assert/strict";
import { after, before, test } from "node:test";
import { createApiServer } from "../src/server.ts";

let server;
let baseUrl;
let marketCalls;
let historyCalls;

before(async () => {
  marketCalls = [];
  historyCalls = [];
  const runtime = {
    async getMarkets(searchTerm) {
      marketCalls.push(searchTerm);
      return { markets: [{ epic: "EURUSD" }] };
    },
    async getPriceHistory(epic, resolution, max) {
      historyCalls.push({ epic, resolution, max });
      return { prices: [] };
    },
  };
  server = createApiServer(runtime);
  await new Promise((resolve, reject) => {
    server.once("error", reject);
    server.listen(0, "127.0.0.1", resolve);
  });
  const address = server.address();
  assert.ok(address && typeof address === "object");
  baseUrl = `http://127.0.0.1:${address.port}`;
});

after(async () => {
  if (server?.listening) {
    await new Promise((resolve, reject) => server.close((error) => error ? reject(error) : resolve()));
  }
});

test("market search validates trimmed input at the HTTP boundary", async () => {
  const invalidTerms = [undefined, "", "   ", "A".repeat(101)];
  for (const term of invalidTerms) {
    const query = term === undefined ? "" : `?searchTerm=${encodeURIComponent(term)}`;
    const response = await fetch(`${baseUrl}/market-data/markets${query}`);
    assert.equal(response.status, 400);
    assert.deepEqual(await response.json(), { error: "invalid_search_term" });
  }
  assert.deepEqual(marketCalls, []);

  for (const term of ["A", "A".repeat(100)]) {
    const response = await fetch(`${baseUrl}/market-data/markets?searchTerm=${encodeURIComponent(term)}`);
    assert.equal(response.status, 200);
    assert.deepEqual(await response.json(), {
      provider: "capital.com",
      environment: "DEMO",
      markets: [{ epic: "EURUSD" }],
    });
  }
  assert.deepEqual(marketCalls, ["A", "A".repeat(100)]);
});

test("historical market requests reject malformed EPICs before provider invocation", async () => {
  const invalidEpics = [undefined, "", "   ", "EUR/USD", "A".repeat(65)];
  for (const epic of invalidEpics) {
    const query = epic === undefined ? "" : `?epic=${encodeURIComponent(epic)}`;
    const response = await fetch(`${baseUrl}/market-data/history${query}`);
    assert.equal(response.status, 400);
    assert.deepEqual(await response.json(), { error: "invalid_epic" });
  }
  assert.deepEqual(historyCalls, []);

  const response = await fetch(`${baseUrl}/market-data/history?epic=%20EURUSD%20&resolution=HOUR&max=25`);
  assert.equal(response.status, 200);
  assert.deepEqual(await response.json(), {
    provider: "capital.com",
    environment: "DEMO",
    prices: [],
  });
  assert.deepEqual(historyCalls, [{ epic: "EURUSD", resolution: "HOUR", max: 25 }]);
});
