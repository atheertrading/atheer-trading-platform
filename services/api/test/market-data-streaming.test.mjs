import assert from "node:assert/strict";
import { request as httpRequest } from "node:http";
import { after, test } from "node:test";
import { CapitalDemoStreamingRuntime } from "../dist/market-data/capital-demo-streaming-runtime.js";
import { createApiServer } from "../dist/server.js";

class FakeWebSocket {
  readyState = 0;
  sent = [];
  listeners = new Map();

  constructor(url) {
    this.url = url;
    queueMicrotask(() => {
      this.readyState = 1;
      this.emit("open", {});
    });
  }

  addEventListener(type, listener) {
    const listeners = this.listeners.get(type) ?? [];
    listeners.push(listener);
    this.listeners.set(type, listeners);
  }

  removeEventListener(type, listener) {
    const listeners = this.listeners.get(type) ?? [];
    this.listeners.set(type, listeners.filter((candidate) => candidate !== listener));
  }

  send(raw) {
    const message = JSON.parse(raw);
    this.sent.push(message);
    queueMicrotask(() => this.emit("message", {
      data: JSON.stringify({
        status: "OK",
        destination: message.destination,
        correlationId: message.correlationId,
        payload: { subscriptions: {} },
      }),
    }));
  }

  close() {
    if (this.readyState === 3) return;
    this.readyState = 3;
    queueMicrotask(() => this.emit("close", { code: 1000 }));
  }

  emit(type, event) {
    for (const listener of this.listeners.get(type) ?? []) listener(event);
  }

  emitQuote(payload) {
    this.emit("message", {
      data: JSON.stringify({ status: "OK", destination: "quote", payload }),
    });
  }
}

const streamInfo = {
  streamEndpoint: "wss://api-streaming-capital.backend-capital.com/",
  cst: "private-cst",
  securityToken: "private-security-token",
};

const trackedRuntimes = new Set();

function trackRuntime(runtime) {
  trackedRuntimes.add(runtime);
  return runtime;
}

after(async () => {
  await Promise.allSettled(
    Array.from(trackedRuntimes, (runtime) => runtime.disconnect()),
  );
});

function createStreamingRuntime(sockets, now = 1_800_000_000_000) {
  return trackRuntime(new CapitalDemoStreamingRuntime(
    async () => streamInfo,
    (url) => {
      const socket = new FakeWebSocket(url);
      sockets.push(socket);
      return socket;
    },
    () => now,
    () => 125,
  ));
}

test("DEMO stream connects to provider session endpoint and subscribes with server-held tokens", async () => {
  const sockets = [];
  const runtime = createStreamingRuntime(sockets);
  const quotes = [];
  const unsubscribe = await runtime.subscribe(["AAPL"], (quote) => quotes.push(quote));

  assert.equal(sockets.length, 1);
  assert.equal(sockets[0].url, "wss://api-streaming-capital.backend-capital.com/connect");
  assert.equal(sockets[0].sent[0].destination, "marketData.subscribe");
  assert.deepEqual(sockets[0].sent[0].payload.epics, ["AAPL"]);
  assert.equal(sockets[0].sent[0].cst, "private-cst");
  assert.equal(sockets[0].sent[0].securityToken, "private-security-token");
  assert.equal(JSON.stringify(runtime.status()).includes("private-cst"), false);

  sockets[0].emitQuote({
    epic: "AAPL",
    bid: 199.5,
    ofr: 199.6,
    timestamp: 1_800_000_000_000,
  });
  await new Promise((resolve) => setTimeout(resolve, 0));

  assert.equal(quotes.length, 1);
  assert.equal(quotes[0].instrumentId, "AAPL");
  assert.equal(quotes[0].bid, 199.5);
  assert.equal(quotes[0].freshness.state, "fresh");
  assert.equal(quotes[0].receivedAtMonotonicMs, 125);
  assert.equal(runtime.latest(["AAPL"])[0].ask, 199.6);

  unsubscribe();
  await new Promise((resolve) => setTimeout(resolve, 0));
  assert.equal(runtime.status().state, "disconnected");
  await runtime.disconnect();
});

test("stream status never exposes untrusted provider error details", async () => {
  const runtime = new CapitalDemoStreamingRuntime(
    async () => { throw new Error("private-security-token"); },
    () => new FakeWebSocket("wss://api-streaming-capital.backend-capital.com/connect"),
    () => 1_800_000_000_000,
    () => 125,
  );

  await assert.rejects(runtime.subscribe(["AAPL"], () => undefined), /private-security-token/);
  assert.equal(runtime.status().lastError, "Capital.com streaming connection failed.");
  assert.equal(JSON.stringify(runtime.status()).includes("private-security-token"), false);
});

test("stream runtime rejects noncanonical provider WebSocket paths", async () => {
  const runtime = trackRuntime(new CapitalDemoStreamingRuntime(
    async () => ({
      ...streamInfo,
      streamEndpoint: "wss://api-streaming-capital.backend-capital.com/private",
    }),
    () => new FakeWebSocket("wss://api-streaming-capital.backend-capital.com/connect"),
    () => 1_800_000_000_000,
    () => 125,
  ));

  await assert.rejects(
    runtime.subscribe(["AAPL"], () => {}),
    /stream endpoint failed host validation/,
  );
  assert.equal(runtime.status().state, "degraded");
});

test("stream disconnect waits for the WebSocket close handshake before returning", async () => {
  const sockets = [];
  const runtime = createStreamingRuntime(sockets);
  const unsubscribe = await runtime.subscribe(["WTI"], () => undefined);
  unsubscribe();
  await new Promise((resolve) => setTimeout(resolve, 0));
  await runtime.subscribe(["WTI"], () => undefined);

  const socket = sockets[sockets.length - 1];
  const originalClose = socket.close.bind(socket);
  let closeConfirmed = false;
  socket.close = (...args) => {
    setTimeout(() => {
      originalClose(...args);
      closeConfirmed = true;
    }, 25);
  };

  await runtime.disconnect();
  assert.equal(closeConfirmed, true);
  assert.equal(runtime.status().state, "disconnected");
});

test("stream rejects invalid, duplicate, and over-capacity instrument subscriptions", async () => {
  const sockets = [];
  const runtime = createStreamingRuntime(sockets);
  await assert.rejects(runtime.subscribe([""], () => undefined), /1–40 valid/);
  await assert.rejects(runtime.subscribe(["BAD/EPIC"], () => undefined), /1–40 valid/);

  const forty = Array.from({ length: 40 }, (_, index) => "EPIC" + index);
  const unsubscribe = await runtime.subscribe(forty, () => undefined);
  await assert.rejects(runtime.subscribe(["EPIC40"], () => undefined), /limited to 40/);
  assert.equal(runtime.status().activeInstrumentCount, 40);
  unsubscribe();
  await runtime.disconnect();
});

test("stream ignores duplicate and out-of-order quotes while preserving valid updates", async () => {
  const sockets = [];
  const runtime = createStreamingRuntime(sockets);
  const quotes = [];
  const unsubscribe = await runtime.subscribe(["GOLD"], (quote) => quotes.push(quote));
  const first = {
    epic: "GOLD",
    bid: 2000,
    ofr: 2000.5,
    timestamp: 1_800_000_000_000,
  };

  sockets[0].emitQuote(first);
  sockets[0].emitQuote(first);
  sockets[0].emitQuote({ ...first, bid: 1999, ofr: 1999.5, timestamp: 1_799_999_999_999 });
  sockets[0].emitQuote({ ...first, bid: 2001, ofr: 2001.5, timestamp: 1_800_000_000_100 });
  await new Promise((resolve) => setTimeout(resolve, 0));

  assert.equal(quotes.length, 2);
  assert.equal(runtime.status().duplicateQuoteCount, 1);
  assert.equal(runtime.status().outOfOrderQuoteCount, 1);
  assert.equal(runtime.latest(["GOLD"])[0].bid, 2001);

  unsubscribe();
  await runtime.disconnect();
});

test("stream automatically reconnects and restores active subscriptions after interruption", async () => {
  const sockets = [];
  const runtime = createStreamingRuntime(sockets);
  const unsubscribe = await runtime.subscribe(["OIL_CRUDE"], () => undefined);

  sockets[0].close();
  await new Promise((resolve) => setTimeout(resolve, 0));

  assert.equal(runtime.status().state, "degraded");
  assert.equal(runtime.status().activeInstrumentCount, 0);

  await new Promise((resolve) => setTimeout(resolve, 1_100));

  assert.equal(sockets.length, 2);
  assert.equal(runtime.status().state, "connected");
  assert.equal(runtime.status().activeInstrumentCount, 1);
  assert.equal(sockets[1].sent[0].destination, "marketData.subscribe");
  assert.deepEqual(sockets[1].sent[0].payload.epics, ["OIL_CRUDE"]);

  unsubscribe();
  await runtime.disconnect();
});


test("market-data API requires capability auth and rejects browser-origin requests", async () => {
  const ipcCapability = Buffer.alloc(32, 0x42);
  const capabilityToken = ipcCapability.toString("base64url");
  const server = createApiServer(undefined, ipcCapability);
  await new Promise((resolve, reject) => {
    server.once("error", reject);
    server.listen(0, "127.0.0.1", resolve);
  });
  const address = server.address();
  assert.ok(address && typeof address !== "string");
  const endpoint = "http://127.0.0.1:" + address.port + "/market-data/status";

  const unidentified = await fetch(endpoint);
  assert.equal(unidentified.status, 401);
  assert.deepEqual(await unidentified.json(), { error: "unauthorized" });

  const crossOrigin = await fetch(endpoint, {
    headers: {
      authorization: "Bearer " + capabilityToken,
      Origin: "https://attacker.example",
    },
  });
  assert.equal(crossOrigin.status, 401);

  const crossSite = await fetch(endpoint, {
    headers: {
      authorization: "Bearer " + capabilityToken,
      "Sec-Fetch-Site": "cross-site",
    },
  });
  assert.equal(crossSite.status, 401);

  const trustedNativeClient = await fetch(endpoint, {
    headers: { authorization: "Bearer " + capabilityToken },
  });
  assert.equal(trustedNativeClient.status, 200);
  assert.equal((await trustedNativeClient.json()).state, "not_configured");

  const serverClosed = new Promise((resolve, reject) => server.close((error) => error ? reject(error) : resolve()));
  server.closeAllConnections();
  await serverClosed;
});

test("local SSE endpoint streams normalized quote events and releases subscriptions on close", async () => {
  let released = false;
  let releaseSubscription;
  const releasedPromise = new Promise((resolve) => { releaseSubscription = resolve; });
  const quote = {
    provider: "capital.com",
    environment: "DEMO",
    instrumentId: "AAPL",
    bid: 199.5,
    ask: 199.6,
    providerTimestampMs: 1_800_000_000_000,
    receivedAtMs: 1_800_000_000_000,
    receivedAtMonotonicMs: 100,
    freshness: { state: "fresh", ageMs: 0, automatedDecisionsAllowed: true, reason: "within_policy", maximumAgeMs: 5000 },
  };
  const marketData = {
    status: () => ({ provider: "capital.com", environment: "DEMO", state: "connected" }),
  };
  let streamState = "disconnected";
  let activeInstrumentCount = 0;
  const stream = {
    status: () => ({
      provider: "capital.com",
      environment: "DEMO",
      state: streamState,
      activeInstrumentCount,
      invalidQuoteCount: 0,
      outOfOrderQuoteCount: 0,
      duplicateQuoteCount: 0,
    }),
    latest: () => [],
    async subscribe(epics, callback) {
      assert.deepEqual(epics, ["AAPL"]);
      streamState = "connected";
      activeInstrumentCount = 1;
      setTimeout(() => callback(quote), 5);
      return () => {
        released = true;
        streamState = "disconnected";
        activeInstrumentCount = 0;
        releaseSubscription();
      };
    },
  };
  const ipcCapability = Buffer.alloc(32, 0x43);
  const capabilityToken = ipcCapability.toString("base64url");
  const server = createApiServer(marketData, ipcCapability, stream);
  await new Promise((resolve, reject) => {
    server.once("error", reject);
    server.listen(0, "127.0.0.1", resolve);
  });
  const address = server.address();
  assert.ok(address && typeof address !== "string");

  let body = "";
  await new Promise((resolve, reject) => {
    const client = httpRequest({
      hostname: "127.0.0.1",
      port: address.port,
      path: "/market-data/stream?epics=AAPL",
      method: "GET",
      headers: { authorization: "Bearer " + capabilityToken },
    }, (response) => {
      try {
        assert.equal(response.statusCode, 200);
        assert.ok(response.headers["content-type"].startsWith("text/event-stream"));
      } catch (error) {
        reject(error);
        client.destroy();
        return;
      }
      response.on("data", (chunk) => {
        body += chunk.toString();
        if (body.includes("event: quote")) {
          client.destroy();
          resolve();
        }
      });
      response.on("error", () => undefined);
    });
    client.on("error", (error) => {
      if (body.length === 0) reject(error);
    });
    client.end();
  });

  await Promise.race([
    releasedPromise,
    new Promise((_, reject) => setTimeout(() => reject(new Error("SSE subscription was not released after client disconnect.")), 1_000)),
  ]);
  assert.equal(released, true);
  assert.match(body, /event: status/);
  assert.match(body, /"state":"disconnected"/);
  assert.match(body, /"state":"connected","activeInstrumentCount":1/);
  assert.match(body, /event: quote/);
  assert.match(body, /"instrumentId":"AAPL"/);

  const serverClosed = new Promise((resolve, reject) => server.close((error) => error ? reject(error) : resolve()));
  server.closeAllConnections();
  await serverClosed;
});

test("local SSE endpoint rejects more than forty instrument epics", async () => {
  const marketData = { status: () => ({ provider: "capital.com", environment: "DEMO", state: "connected" }) };
  const stream = {
    status: () => ({ provider: "capital.com", environment: "DEMO", state: "disconnected", activeInstrumentCount: 0 }),
    latest: () => [],
    async subscribe() { throw new Error("Must not subscribe invalid request."); },
  };
  const ipcCapability = Buffer.alloc(32, 0x44);
  const capabilityToken = ipcCapability.toString("base64url");
  const server = createApiServer(marketData, ipcCapability, stream);
  await new Promise((resolve, reject) => {
    server.once("error", reject);
    server.listen(0, "127.0.0.1", resolve);
  });
  const address = server.address();
  assert.ok(address && typeof address !== "string");

  const epics = Array.from({ length: 41 }, (_, index) => "EPIC" + index).join(",");
  const response = await fetch("http://127.0.0.1:" + address.port + "/market-data/stream?epics=" + epics, {
    headers: { authorization: "Bearer " + capabilityToken },
  });
  assert.equal(response.status, 400);
  assert.deepEqual(await response.json(), { error: "invalid_stream_instruments" });

  const serverClosed = new Promise((resolve, reject) => server.close((error) => error ? reject(error) : resolve()));
  server.closeAllConnections();
  await serverClosed;
});
