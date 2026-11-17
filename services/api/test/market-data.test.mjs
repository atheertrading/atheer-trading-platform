import assert from "node:assert/strict";
import { test } from "node:test";
import {
  evaluateQuoteFreshness,
  normalizeCapitalQuote,
} from "../dist/market-data/contracts.js";
import {
  CapitalDemoClient,
  CapitalDemoApiError,
} from "../dist/market-data/capital-demo-client.js";

const demoBase = "https://demo-api-capital.backend-capital.com/api/v1";

function response(body, status = 200, headers = {}) {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      "content-type": "application/json",
      ...headers,
    },
  });
}

test("normalizes a provider quote without replacing provider time with receive time", () => {
  const quote = normalizeCapitalQuote({
    epic: "AAPL",
    bid: 199.5,
    ofr: 199.6,
    timestamp: 1_800_000_000_000,
  }, 1_800_000_000_025);

  assert.equal(quote.provider, "capital.com");
  assert.equal(quote.environment, "DEMO");
  assert.equal(quote.instrumentId, "AAPL");
  assert.equal(quote.providerTimestampMs, 1_800_000_000_000);
  assert.equal(quote.receivedAtMs, 1_800_000_000_025);
});

test("rejects malformed or crossed provider quotes", () => {
  assert.throws(() => normalizeCapitalQuote({
    epic: "AAPL", bid: 200, ofr: 199, timestamp: 1_800_000_000_000,
  }, 1_800_000_000_010), /invalid ask/);
  assert.throws(() => normalizeCapitalQuote({
    epic: "AAPL", bid: 200, ofr: 201, timestamp: "now",
  }, 1_800_000_000_010), /provider timestamp/);
});

test("stale and future-dated quotes block automated decisions", () => {
  const quote = normalizeCapitalQuote({
    epic: "AAPL", bid: 199, ofr: 200, timestamp: 1_800_000_000_000,
  }, 1_800_000_000_010);
  const policy = { maximumAgeMs: 5_000, maximumFutureSkewMs: 250 };

  assert.equal(evaluateQuoteFreshness(quote, 1_800_000_004_000, policy).automatedDecisionsAllowed, true);
  const stale = evaluateQuoteFreshness(quote, 1_800_000_006_000, policy);
  assert.equal(stale.state, "stale");
  assert.equal(stale.automatedDecisionsAllowed, false);
  const future = evaluateQuoteFreshness(quote, 1_799_999_999_000, policy);
  assert.equal(future.state, "invalid");
  assert.equal(future.automatedDecisionsAllowed, false);
});

test("freshness evaluator rejects forged or malformed quote objects", () => {
  const malformed = {
    provider: "capital.com",
    environment: "DEMO",
    instrumentId: "AAPL",
    bid: 100,
    ask: 101,
    providerTimestampMs: Number.NaN,
    receivedAtMs: 1_800_000_000_000,
  };
  const result = evaluateQuoteFreshness(malformed, 1_800_000_000_100, {
    maximumAgeMs: 5_000,
    maximumFutureSkewMs: 250,
  });
  assert.equal(result.state, "invalid");
  assert.equal(result.automatedDecisionsAllowed, false);
  assert.equal(result.reason, "invalid_quote");
});

test("Capital DEMO session uses only the official DEMO host and returns session headers", async () => {
  const calls = [];
  const client = new CapitalDemoClient(async (url, init) => {
    calls.push({ url: String(url), init });
    return response({ status: "SUCCESS" }, 200, {
      CST: "demo-cst",
      "X-SECURITY-TOKEN": "demo-security-token",
    });
  }, () => 1_800_000_000_000);

  const session = await client.startSession({
    apiKey: "demo-api-key",
    identifier: "demo-user",
    password: "demo-password",
  });

  assert.equal(calls[0].url, demoBase + "/session");
  assert.equal(calls[0].init.method, "POST");
  assert.equal(session.environment, "DEMO");
  assert.equal(session.cst, "demo-cst");
  assert.equal(session.securityToken, "demo-security-token");
  const body = JSON.parse(calls[0].init.body);
  assert.equal(body.encryptedPassword, false);
});

test("streaming connection details use the session-provided trusted WebSocket endpoint", async () => {
  const calls = [];
  const client = new CapitalDemoClient(async (url, init) => {
    calls.push({ url: String(url), init });
    return response({
      streamEndpoint: "wss://api-streaming-capital.backend-capital.com/",
    });
  });
  const session = {
    cst: "demo-cst",
    securityToken: "demo-security-token",
    createdAtMs: 1_800_000_000_000,
    environment: "DEMO",
  };

  const info = await client.getStreamingConnectionInfo(session);
  assert.equal(calls[0].url, demoBase + "/session");
  assert.equal(calls[0].init.method, "GET");
  assert.equal(calls[0].init.headers.CST, "demo-cst");
  assert.equal(calls[0].init.headers["X-SECURITY-TOKEN"], "demo-security-token");
  assert.equal(info.streamEndpoint, "wss://api-streaming-capital.backend-capital.com/");
  assert.equal(info.cst, "demo-cst");
  assert.equal(info.securityToken, "demo-security-token");
});

test("streaming connection details reject untrusted provider endpoints", async () => {
  const client = new CapitalDemoClient(async () => response({
    streamEndpoint: "wss://attacker.example/connect",
  }));
  await assert.rejects(
    client.getStreamingConnectionInfo({
      cst: "demo-cst",
      securityToken: "demo-security-token",
      createdAtMs: 1_800_000_000_000,
      environment: "DEMO",
    }),
    /untrusted streaming endpoint/,
  );
});

test("market search and history requests carry DEMO session headers", async () => {
  const calls = [];
  const client = new CapitalDemoClient(async (url, init) => {
    calls.push({ url: String(url), init });
    return calls.length === 1
      ? response({ markets: [{ epic: "AAPL", instrumentName: "Apple" }] })
      : response({ prices: [{ snapshotTimeUTC: "2026-11-17T10:00:00Z" }] });
  });
  const session = {
    cst: "demo-cst",
    securityToken: "demo-security-token",
    createdAtMs: 1_800_000_000_000,
    environment: "DEMO",
  };

  const markets = await client.getMarkets(session, "Apple");
  const history = await client.getPriceHistory(session, "AAPL", "MINUTE", 20);

  assert.equal(markets.markets[0].epic, "AAPL");
  assert.equal(history.prices.length, 1);
  assert.ok(calls[0].url.startsWith(demoBase + "/markets?"));
  assert.ok(calls[1].url.startsWith(demoBase + "/prices/AAPL?"));
  assert.equal(calls[0].init.headers.CST, "demo-cst");
  assert.equal(calls[0].init.headers["X-SECURITY-TOKEN"], "demo-security-token");
});

test("Capital DEMO adapter rejects missing credentials and non-DEMO sessions", async () => {
  const client = new CapitalDemoClient(async () => response({}));
  await assert.rejects(
    client.startSession({ apiKey: "", identifier: "demo-user", password: "demo-password" }),
    /credentials are incomplete/,
  );
  await assert.rejects(
    client.getMarkets({
      cst: "cst", securityToken: "token", createdAtMs: 1_800_000_000_000, environment: "LIVE",
    }, "Apple"),
    /valid Capital.com DEMO session/,
  );
});

test("Capital API errors expose status but never echo response bodies", async () => {
  const client = new CapitalDemoClient(async () => new Response("secret-provider-detail", { status: 401 }));
  await assert.rejects(
    client.startSession({ apiKey: "key", identifier: "user", password: "password" }),
    (error) => {
      assert.ok(error instanceof CapitalDemoApiError);
      assert.equal(error.statusCode, 401);
      assert.equal(error.message.includes("secret-provider-detail"), false);
      return true;
    },
  );
});
