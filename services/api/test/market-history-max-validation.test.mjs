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

test("market history accepts bounded decimal integer max values", async () => {
  for (const max of [1, 12, 1000]) {
    const response = await fetch(`${baseUrl}/market-data/history?epic=EURUSD&resolution=HOUR&max=${max}`);
    assert.equal(response.status, 200);
  }
  assert.deepEqual(historyCalls, [
    { epic: "EURUSD", resolution: "HOUR", max: 1 },
    { epic: "EURUSD", resolution: "HOUR", max: 12 },
    { epic: "EURUSD", resolution: "HOUR", max: 1000 },
  ]);
});

test("market history rejects malformed and out-of-range max values before provider invocation", async () => {
  for (const max of ["abc", "1.5", "1e2", "-1", "", "0", "1001", "9007199254740992"]) {
    const response = await fetch(`${baseUrl}/market-data/history?epic=EURUSD&resolution=HOUR&max=${encodeURIComponent(max)}`);
    assert.equal(response.status, 400, `expected max=${JSON.stringify(max)} to be rejected`);
    assert.deepEqual(await response.json(), { error: "invalid_max" });
  }
  assert.equal(historyCalls.length, 3);
});
