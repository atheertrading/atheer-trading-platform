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

test("market history accepts a decimal integer max and forwards its numeric value", async () => {
  const response = await fetch(`${baseUrl}/market-data/history?epic=EURUSD&resolution=HOUR&max=12`);
  assert.equal(response.status, 200);
  assert.deepEqual(historyCalls, [{ epic: "EURUSD", resolution: "HOUR", max: 12 }]);
});

test("market history rejects non-integer max values before calling the provider", async () => {
  for (const max of ["abc", "1.5", "1e2", "-1", ""]) {
    const response = await fetch(`${baseUrl}/market-data/history?epic=EURUSD&resolution=HOUR&max=${encodeURIComponent(max)}`);
    assert.equal(response.status, 400, `expected max=${JSON.stringify(max)} to be rejected`);
    assert.deepEqual(await response.json(), { error: "invalid_max" });
  }
  assert.equal(historyCalls.length, 1);
});
