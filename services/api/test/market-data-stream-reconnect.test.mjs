import assert from "node:assert/strict";
import { test } from "node:test";
import { CapitalDemoStreamingRuntime } from "../dist/market-data/capital-demo-streaming-runtime.js";

class FakeWebSocket {
  static CONNECTING = 0;
  static OPEN = 1;
  static CLOSING = 2;
  static CLOSED = 3;

  readyState = FakeWebSocket.CONNECTING;
  listeners = new Map();

  addEventListener(type, listener) {
    const values = this.listeners.get(type) ?? [];
    values.push(listener);
    this.listeners.set(type, values);
  }

  removeEventListener(type, listener) {
    this.listeners.set(type, (this.listeners.get(type) ?? []).filter((item) => item !== listener));
  }

  dispatch(type, event = {}) {
    for (const listener of [...(this.listeners.get(type) ?? [])]) listener(event);
  }

  open() {
    this.readyState = FakeWebSocket.OPEN;
    this.dispatch("open");
  }

  send(payload) {
    const request = JSON.parse(payload);
    queueMicrotask(() => this.dispatch("message", {
      data: JSON.stringify({ correlationId: request.correlationId, status: "OK" }),
    }));
  }

  close() {
    if (this.readyState === FakeWebSocket.CLOSED) return;
    this.readyState = FakeWebSocket.CLOSED;
    this.dispatch("close", { code: 1000 });
  }

  interrupt() {
    this.readyState = FakeWebSocket.CLOSED;
    this.dispatch("close", { code: 1006 });
  }
}

test("market-data stream reconnect uses deterministic exponential full jitter", async () => {
  const originalWebSocket = globalThis.WebSocket;
  const originalSetTimeout = globalThis.setTimeout;
  const nativeSetTimeout = originalSetTimeout.bind(globalThis);
  const sockets = [];
  let reconnectDelayMs;

  globalThis.WebSocket = FakeWebSocket;
  try {
    const runtime = new CapitalDemoStreamingRuntime(
      async () => ({
        streamEndpoint: "wss://api-streaming-capital.backend-capital.com/connect",
        cst: "synthetic-cst",
        securityToken: "synthetic-security-token",
      }),
      () => {
        const socket = new FakeWebSocket();
        sockets.push(socket);
        return socket;
      },
      () => 1_800_000_000_000,
      () => 0,
      () => 0.25,
    );

    const subscriptionPromise = runtime.subscribe(["AAPL"], () => undefined);
    await new Promise((resolve) => setImmediate(resolve));
    assert.equal(sockets.length, 1);
    sockets[0].open();
    await subscriptionPromise;
    assert.equal(runtime.status().state, "connected");

    globalThis.setTimeout = (callback, delay, ...args) => {
      reconnectDelayMs = delay;
      return nativeSetTimeout(callback, 60_000, ...args);
    };

    sockets[0].interrupt();

    assert.equal(runtime.status().state, "degraded");
    assert.equal(reconnectDelayMs, 250);
    assert.equal(sockets.length, 1);

    await runtime.disconnect();
  } finally {
    globalThis.setTimeout = originalSetTimeout;
    globalThis.WebSocket = originalWebSocket;
  }
});
