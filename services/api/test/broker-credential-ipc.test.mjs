import assert from "node:assert/strict";
import { chmod, mkdtemp, stat } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { createConnection } from "node:net";
import { test } from "node:test";
import { createBrokerCredentialIPCServer } from "../dist/security/broker-credential-ipc.js";

const connectedStatus = {
  provider: "capital.com",
  environment: "DEMO",
  state: "connected",
  connectedAtMs: 1_800_000_000_000,
};
const disconnectedStatus = {
  provider: "capital.com",
  environment: "DEMO",
  state: "disconnected",
};

function sendRequest(socketPath, request) {
  return new Promise((resolve, reject) => {
    const socket = createConnection(socketPath);
    let buffer = "";
    socket.once("connect", () => socket.write(JSON.stringify(request) + "\n"));
    socket.on("data", (chunk) => {
      buffer += chunk.toString("utf8");
      const newline = buffer.indexOf("\n");
      if (newline >= 0) {
        socket.end();
        try {
          resolve(JSON.parse(buffer.slice(0, newline)));
        } catch (error) {
          reject(error);
        }
      }
    });
    socket.once("error", reject);
  });
}

async function makeServer(manager, beforeSessionReplacement = async () => {}) {
  const directory = await mkdtemp(join(tmpdir(), "atheer-credential-ipc-"));
  await chmod(directory, 0o700);
  const socketPath = join(directory, "broker.sock");
  const capability = Buffer.alloc(32, 23);
  const server = await createBrokerCredentialIPCServer({
    socketPath,
    expectedCapability: capability,
    manager,
    beforeSessionReplacement,
  });
  return { directory, socketPath, capability, server };
}

test("private Unix-domain IPC authenticates DEMO credentials and never returns them", async () => {
  let capturedCredentials;
  let replacementCallbackCount = 0;
  const manager = {
    async connect(credentials, beforeReplacement) {
      capturedCredentials = { ...credentials };
      assert.equal(typeof beforeReplacement, "function");
      await beforeReplacement();
      return connectedStatus;
    },
    async disconnect() {
      return disconnectedStatus;
    },
  };
  const fixture = await makeServer(manager, async () => { replacementCallbackCount += 1; });
  try {
    const response = await sendRequest(fixture.socketPath, {
      requestId: "request-0001",
      capability: fixture.capability.toString("base64url"),
      action: "connect",
      credentials: {
        apiKey: "synthetic-demo-key",
        identifier: "synthetic.identity",
        password: "synthetic-demo-password",
      },
    });

    assert.equal(response.ok, true);
    assert.deepEqual(response.status, connectedStatus);
    assert.deepEqual(capturedCredentials, {
      apiKey: "synthetic-demo-key",
      identifier: "synthetic.identity",
      password: "synthetic-demo-password",
    });
    assert.equal(replacementCallbackCount, 1);
    const serialized = JSON.stringify(response);
    assert.equal(serialized.includes("synthetic-demo-key"), false);
    assert.equal(serialized.includes("synthetic-demo-password"), false);
    assert.equal(serialized.includes("synthetic.identity"), false);
  } finally {
    await fixture.server.close();
  }
});

test("private Unix-domain IPC rejects an invalid capability before broker access", async () => {
  let connectCount = 0;
  const manager = {
    async connect() {
      connectCount += 1;
      return connectedStatus;
    },
    async disconnect() {
      return disconnectedStatus;
    },
  };
  const fixture = await makeServer(manager);
  try {
    const response = await sendRequest(fixture.socketPath, {
      requestId: "request-0002",
      capability: Buffer.alloc(32, 24).toString("base64url"),
      action: "connect",
      credentials: {
        apiKey: "synthetic-demo-key",
        identifier: "synthetic.identity",
        password: "synthetic-demo-password",
      },
    });
    assert.equal(response.ok, false);
    assert.equal(response.errorCode, "unauthorized");
    assert.equal(connectCount, 0);
  } finally {
    await fixture.server.close();
  }
});

test("private Unix-domain IPC disconnects streaming before releasing the broker session", async () => {
  const order = [];
  const manager = {
    async connect() {
      return connectedStatus;
    },
    async disconnect() {
      order.push("broker");
      return disconnectedStatus;
    },
  };
  const fixture = await makeServer(manager, async () => { order.push("stream"); });
  try {
    const response = await sendRequest(fixture.socketPath, {
      requestId: "request-0003",
      capability: fixture.capability.toString("base64url"),
      action: "disconnect",
    });
    assert.equal(response.ok, true);
    assert.deepEqual(response.status, disconnectedStatus);
    assert.deepEqual(order, ["stream", "broker"]);
  } finally {
    await fixture.server.close();
  }
});

test("private Unix-domain IPC bounds request size and applies private filesystem modes", async () => {
  const manager = {
    async connect() {
      return connectedStatus;
    },
    async disconnect() {
      return disconnectedStatus;
    },
  };
  const fixture = await makeServer(manager);
  try {
    const directoryStats = await stat(fixture.directory);
    const socketStats = await stat(fixture.socketPath);
    assert.equal(directoryStats.mode & 0o777, 0o700);
    assert.equal(socketStats.mode & 0o777, 0o600);

    const response = await sendRequest(fixture.socketPath, {
      requestId: "request-0004",
      capability: fixture.capability.toString("base64url"),
      action: "disconnect",
      padding: "x".repeat(9_000),
    });
    assert.equal(response.ok, false);
    assert.equal(response.errorCode, "request_too_large");
  } finally {
    await fixture.server.close();
  }
});
