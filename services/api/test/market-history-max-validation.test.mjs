import assert from "node:assert/strict";
import { after, before, test } from "node:test";
import { createApiServer } from "../src/server.ts";

let server;
let baseUrl;
let historyCalls;

before(async () => {
  historyCalls = [];
  const runtime = {
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

test("market history applies the default and accepts bounded decimal integer max values", async () => {
  const requested = [
    { query: "", expected: 100 },
    { query: "&max=1", expected: 1 },
    { query: "&max=12", expected: 12 },
    { query: "&max=1000", expected: 1000 },
  ];

  for (const item of requested) {
    const response = await fetch(`${baseUrl}/market-data/history?epic=EURUSD&resolution=HOUR${item.query}`);
    assert.equal(response.status, 200);
    assert.deepEqual(await response.json(), {
      provider: "capital.com",
      environment: "DEMO",
      prices: [],
    });
    assert.equal(historyCalls.at(-1)?.max, item.expected);
  }

  assert.deepEqual(historyCalls, requested.map(({ expected }) => ({
    epic: "EURUSD",
    resolution: "HOUR",
    max: expected,
  })));
});

test("market history rejects malformed and out-of-range max values before provider invocation", async () => {
  for (const max of ["abc", "1.5", "1e2", "-1", "", "0", "1001", "9007199254740992"]) {
    const response = await fetch(`${baseUrl}/market-data/history?epic=EURUSD&resolution=HOUR&max=${encodeURIComponent(max)}`);
    assert.equal(response.status, 400, `expected max=${JSON.stringify(max)} to be rejected`);
    assert.deepEqual(await response.json(), { error: "invalid_max" });
  }
  assert.equal(historyCalls.length, 4);
});
