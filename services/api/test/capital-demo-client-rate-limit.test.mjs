import assert from "node:assert/strict";
import { test } from "node:test";
import { CapitalDemoApiError, CapitalDemoClient } from "../dist/market-data/capital-demo-client.js";

const session = {
  cst: "synthetic-cst",
  securityToken: "synthetic-security-token",
  createdAtMs: 1_800_000_000_000,
  environment: "DEMO",
};

function successfulMarkets() {
  return new Response(JSON.stringify({
    markets: [{ epic: "EURUSD", instrumentName: "EUR/USD" }],
  }), {
    status: 200,
    headers: { "content-type": "application/json" },
  });
}

test("Capital.com REST client honors Retry-After seconds before retrying", async () => {
  let requestCount = 0;
  let monotonicNow = 0;
  const waits = [];
  const client = new CapitalDemoClient(async () => {
    requestCount += 1;
    if (requestCount === 1) {
      return new Response(null, {
        status: 429,
        headers: { "Retry-After": "2" },
      });
    }
    return successfulMarkets();
  }, () => 1_800_000_000_000, {
    requestIntervalMs: 100,
    monotonicNow: () => monotonicNow,
    sleep: async (milliseconds) => {
      waits.push(milliseconds);
      monotonicNow += milliseconds;
    },
    random: () => 0.5,
  });

  const result = await client.getMarkets(session, "EURUSD");
  assert.equal(result.markets[0].epic, "EURUSD");
  assert.equal(requestCount, 2);
  assert.deepEqual(waits, [2_000]);
});

test("Capital.com REST client accepts HTTP-date Retry-After values", async () => {
  let requestCount = 0;
  let wallClockNow = 1_800_000_000_000;
  let monotonicNow = 0;
  const waits = [];
  const retryAt = new Date(wallClockNow + 2_000).toUTCString();
  const client = new CapitalDemoClient(async () => {
    requestCount += 1;
    return requestCount === 1
      ? new Response(null, { status: 429, headers: { "Retry-After": retryAt } })
      : successfulMarkets();
  }, () => wallClockNow, {
    requestIntervalMs: 100,
    monotonicNow: () => monotonicNow,
    sleep: async (milliseconds) => {
      waits.push(milliseconds);
      monotonicNow += milliseconds;
      wallClockNow += milliseconds;
    },
    random: () => 0.5,
  });

  await client.getMarkets(session, "EURUSD");
  assert.equal(requestCount, 2);
  assert.deepEqual(waits, [2_000]);
});

test("Capital.com REST client applies deterministic jitter when Retry-After is absent", async () => {
  let requestCount = 0;
  let monotonicNow = 0;
  const waits = [];
  const client = new CapitalDemoClient(async () => {
    requestCount += 1;
    return requestCount === 1
      ? new Response(null, { status: 429 })
      : successfulMarkets();
  }, () => 1_800_000_000_000, {
    requestIntervalMs: 100,
    monotonicNow: () => monotonicNow,
    sleep: async (milliseconds) => {
      waits.push(milliseconds);
      monotonicNow += milliseconds;
    },
    random: () => 0.5,
  });

  await client.getMarkets(session, "EURUSD");
  assert.equal(requestCount, 2);
  assert.deepEqual(waits, [250]);
});

test("Capital.com REST client bounds 429 retries and does not retry other failures", async () => {
  let rateLimitedRequests = 0;
  let monotonicNow = 0;
  const waits = [];
  const client = new CapitalDemoClient(async () => {
    rateLimitedRequests += 1;
    return new Response(null, { status: 429 });
  }, () => 1_800_000_000_000, {
    requestIntervalMs: 100,
    monotonicNow: () => monotonicNow,
    sleep: async (milliseconds) => {
      waits.push(milliseconds);
      monotonicNow += milliseconds;
    },
    random: () => 1,
  });

  await assert.rejects(client.getMarkets(session, "EURUSD"), (error) => {
    assert.ok(error instanceof CapitalDemoApiError);
    assert.equal(error.statusCode, 429);
    return true;
  });
  assert.equal(rateLimitedRequests, 4);
  assert.deepEqual(waits, [500, 1_000, 2_000]);

  let unavailableRequests = 0;
  const unavailable = new CapitalDemoClient(async () => {
    unavailableRequests += 1;
    return new Response(null, { status: 503 });
  });
  await assert.rejects(unavailable.getMarkets(session, "EURUSD"), { statusCode: 503 });
  assert.equal(unavailableRequests, 1);
});
