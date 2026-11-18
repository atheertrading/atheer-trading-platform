import assert from "node:assert/strict";
import test from "node:test";
import { BrokerSessionManager } from "../dist/market-data/broker-session-manager.js";

function createFakeRuntime(credentials, events, options = {}) {
  let state = "disconnected";
  return {
    credentials,
    usesCredentials(candidate) {
      return candidate.apiKey === credentials.apiKey &&
        candidate.identifier === credentials.identifier &&
        candidate.password === credentials.password;
    },
    isAuthenticationBlockedFor() { return false; },
    status() {
      return {
        provider: "capital.com",
        environment: "DEMO",
        state,
      };
    },
    async connect() {
      events.push("connect:" + credentials.identifier + ":start");
      state = "connecting";
      options.onConnectStart?.();
      if (options.connectGate) await options.connectGate;
      state = "connected";
      events.push("connect:" + credentials.identifier + ":complete");
      return this.status();
    },
    async disconnect() {
      events.push("disconnect:" + credentials.identifier + ":start");
      state = "disconnected";
      events.push("disconnect:" + credentials.identifier + ":complete");
      return this.status();
    },
  };
}

const credentialsA = {
  apiKey: "synthetic-key-a",
  identifier: "synthetic-user-a",
  password: "synthetic-password-a",
};
const credentialsB = {
  apiKey: "synthetic-key-b",
  identifier: "synthetic-user-b",
  password: "synthetic-password-b",
};

test("concurrent connect and disconnect transitions execute in invocation order", async () => {
  const events = [];
  let releaseConnect;
  let signalConnectStarted;
  const connectGate = new Promise((resolve) => { releaseConnect = resolve; });
  const connectStarted = new Promise((resolve) => { signalConnectStarted = resolve; });
  const manager = new BrokerSessionManager(
    (credentials) => createFakeRuntime(credentials, events, {
      connectGate,
      onConnectStart: signalConnectStarted,
    }),
    () => 1_800_000_000_000,
    0,
  );

  const connecting = manager.connect(credentialsA);
  await connectStarted;
  const disconnecting = manager.disconnect();

  await Promise.resolve();
  assert.deepEqual(events, ["connect:synthetic-user-a:start"]);

  releaseConnect();
  const [connected, disconnected] = await Promise.all([connecting, disconnecting]);

  assert.equal(connected.state, "connected");
  assert.equal(disconnected.state, "disconnected");
  assert.deepEqual(events, [
    "connect:synthetic-user-a:start",
    "connect:synthetic-user-a:complete",
    "disconnect:synthetic-user-a:start",
    "disconnect:synthetic-user-a:complete",
  ]);
  assert.equal(manager.status().state, "not_configured");
});

test("credential replacement stops the old session before creating the next runtime", async () => {
  const events = [];
  const manager = new BrokerSessionManager(
    (credentials) => {
      events.push("create:" + credentials.identifier);
      return createFakeRuntime(credentials, events);
    },
    () => 1_800_000_000_000,
    0,
  );

  await manager.connect(credentialsA);
  await manager.connect(credentialsB, async () => {
    events.push("stream:disconnect");
  });

  assert.deepEqual(events, [
    "create:synthetic-user-a",
    "connect:synthetic-user-a:start",
    "connect:synthetic-user-a:complete",
    "stream:disconnect",
    "disconnect:synthetic-user-a:start",
    "disconnect:synthetic-user-a:complete",
    "create:synthetic-user-b",
    "connect:synthetic-user-b:start",
    "connect:synthetic-user-b:complete",
  ]);
  assert.equal(manager.status().state, "connected");
});

test("concurrent replacement requests cannot create overlapping broker runtimes", async () => {
  const events = [];
  const manager = new BrokerSessionManager(
    (credentials) => {
      events.push("create:" + credentials.identifier);
      return createFakeRuntime(credentials, events);
    },
    () => 1_800_000_000_000,
    0,
  );

  await Promise.all([
    manager.connect(credentialsA),
    manager.connect(credentialsB, async () => { events.push("stream:disconnect"); }),
  ]);

  const createA = events.indexOf("create:synthetic-user-a");
  const disconnectA = events.indexOf("disconnect:synthetic-user-a:complete");
  const createB = events.indexOf("create:synthetic-user-b");
  assert.ok(createA >= 0);
  assert.ok(disconnectA > createA);
  assert.ok(createB > disconnectA);
  assert.equal(manager.status().state, "connected");
});

test("disconnect stream teardown stays inside the serialized session transition", async () => {
  const events = [];
  let releaseStream;
  let signalStreamStarted;
  const streamGate = new Promise((resolve) => { releaseStream = resolve; });
  const streamStarted = new Promise((resolve) => { signalStreamStarted = resolve; });
  const manager = new BrokerSessionManager(
    (credentials) => {
      events.push("create:" + credentials.identifier);
      return createFakeRuntime(credentials, events);
    },
    () => 1_800_000_000_000,
    0,
  );

  await manager.connect(credentialsA);
  const disconnecting = manager.disconnect(async () => {
    events.push("stream:disconnect:start");
    signalStreamStarted();
    await streamGate;
    events.push("stream:disconnect:complete");
  });
  await streamStarted;

  const connectingReplacement = manager.connect(credentialsB, async () => {
    events.push("stream:replacement");
  });
  await Promise.resolve();
  assert.deepEqual(events.slice(-1), ["stream:disconnect:start"]);

  releaseStream();
  const [disconnected, connected] = await Promise.all([disconnecting, connectingReplacement]);

  assert.equal(disconnected.state, "disconnected");
  assert.equal(connected.state, "connected");
  assert.deepEqual(events.slice(-7), [
    "stream:disconnect:start",
    "stream:disconnect:complete",
    "disconnect:synthetic-user-a:start",
    "disconnect:synthetic-user-a:complete",
    "create:synthetic-user-b",
    "connect:synthetic-user-b:start",
    "connect:synthetic-user-b:complete",
  ]);
  assert.equal(manager.status().state, "connected");
});
