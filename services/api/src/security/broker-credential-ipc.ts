import { Buffer } from "node:buffer";
import { chmod, lstat, stat, unlink } from "node:fs/promises";
import { dirname } from "node:path";
import { createServer, type Socket } from "node:net";
import type { BrokerSessionManager, BrokerSessionStatus } from "../market-data/broker-session-manager.ts";
import { hasValidIPCCapabilityValue } from "./ipc-capability.ts";

const MAX_REQUEST_BYTES = 8 * 1_024;
const MAX_RESPONSE_BYTES = 8 * 1_024;
const SOCKET_PATH_MAX_BYTES = 103;
const SOCKET_MODE = 0o600;
const REQUEST_TIMEOUT_MS = 30_000;

type CredentialPayload = {
  apiKey: string;
  identifier: string;
  password: string;
};

type CredentialIPCRequest = {
  requestId: string;
  capability: string;
  action: "connect" | "disconnect";
  credentials?: CredentialPayload;
};

type CredentialIPCResponse = {
  requestId: string;
  ok: boolean;
  status?: BrokerSessionStatus;
  errorCode?: string;
};

export interface BrokerCredentialIPCServer {
  close(): Promise<void>;
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return value !== null && typeof value === "object" && !Array.isArray(value);
}

function parseRequest(payload: Buffer): CredentialIPCRequest | null {
  let value: unknown;
  try {
    value = JSON.parse(payload.toString("utf8"));
  } catch {
    return null;
  }
  if (!isRecord(value)) return null;

  const allowedKeys = ["requestId", "capability", "action", "credentials"];
  if (Object.keys(value).some((key) => !allowedKeys.includes(key))) return null;

  const requestId = typeof value.requestId === "string" ? value.requestId : "";
  const capability = typeof value.capability === "string" ? value.capability : "";
  const action = value.action;
  if (!/^[A-Za-z0-9_-]{8,64}$/.test(requestId) || !capability) return null;
  if (action !== "connect" && action !== "disconnect") return null;

  if (action === "disconnect") {
    if (Object.prototype.hasOwnProperty.call(value, "credentials")) return null;
    return { requestId, capability, action };
  }

  if (!isRecord(value.credentials)) return null;
  const credentialKeys = ["apiKey", "identifier", "password"];
  if (
    Object.keys(value.credentials).length !== credentialKeys.length ||
    Object.keys(value.credentials).some((key) => !credentialKeys.includes(key))
  ) return null;

  const apiKey = typeof value.credentials.apiKey === "string"
    ? value.credentials.apiKey.trim()
    : "";
  const identifier = typeof value.credentials.identifier === "string"
    ? value.credentials.identifier.trim()
    : "";
  const password = typeof value.credentials.password === "string"
    ? value.credentials.password
    : "";

  if (
    apiKey.length === 0 || apiKey.length > 512 ||
    identifier.length === 0 || identifier.length > 512 ||
    password.trim().length === 0 || password.length > 2_048
  ) return null;

  return {
    requestId,
    capability,
    action,
    credentials: { apiKey, identifier, password },
  };
}

function writeResponse(socket: Socket, response: CredentialIPCResponse): void {
  if (socket.destroyed) return;
  const encoded = Buffer.from(JSON.stringify(response) + "\n", "utf8");
  if (encoded.byteLength > MAX_RESPONSE_BYTES) {
    socket.end(JSON.stringify({
      requestId: response.requestId,
      ok: false,
      errorCode: "response_too_large",
    }) + "\n");
    return;
  }
  socket.end(encoded);
}

async function handleRequest(
  payload: Buffer,
  expectedCapability: Uint8Array,
  manager: Pick<BrokerSessionManager, "connect" | "disconnect">,
  beforeSessionReplacement?: () => Promise<void>,
): Promise<CredentialIPCResponse> {
  const request = parseRequest(payload);
  if (!request) {
    return { requestId: "invalid", ok: false, errorCode: "invalid_request" };
  }
  if (!hasValidIPCCapabilityValue(request.capability, expectedCapability)) {
    if (request.credentials) {
      request.credentials.apiKey = "";
      request.credentials.identifier = "";
      request.credentials.password = "";
    }
    return { requestId: request.requestId, ok: false, errorCode: "unauthorized" };
  }

  if (request.action === "connect") {
    const credentials = request.credentials;
    if (!credentials) {
      return { requestId: request.requestId, ok: false, errorCode: "invalid_request" };
    }
    const managerCredentials = {
      apiKey: credentials.apiKey,
      identifier: credentials.identifier,
      password: credentials.password,
    };
    try {
      const status = await manager.connect(managerCredentials, beforeSessionReplacement);
      return { requestId: request.requestId, ok: true, status };
    } catch {
      return { requestId: request.requestId, ok: false, errorCode: "broker_session_connect_failed" };
    } finally {
      managerCredentials.apiKey = "";
      managerCredentials.identifier = "";
      managerCredentials.password = "";
      credentials.apiKey = "";
      credentials.identifier = "";
      credentials.password = "";
    }
  }

  let streamDisconnectFailed = false;
  try {
    await beforeSessionReplacement?.();
  } catch {
    streamDisconnectFailed = true;
  }

  try {
    const status = await manager.disconnect();
    return {
      requestId: request.requestId,
      ok: !streamDisconnectFailed,
      status,
      ...(streamDisconnectFailed ? { errorCode: "market_data_stream_disconnect_failed" } : {}),
    };
  } catch {
    return { requestId: request.requestId, ok: false, errorCode: "broker_session_disconnect_failed" };
  }
}

/**
 * Creates a private Unix-domain credential channel. The parent creates the
 * containing directory with mode 0700; this server sets the socket to 0600.
 * Every request also carries the 256-bit process capability.
 */
export async function createBrokerCredentialIPCServer(options: {
  socketPath: string;
  expectedCapability: Uint8Array;
  manager: Pick<BrokerSessionManager, "connect" | "disconnect">;
  beforeSessionReplacement?: () => Promise<void>;
}): Promise<BrokerCredentialIPCServer> {
  const { socketPath, expectedCapability, manager, beforeSessionReplacement } = options;
  if (
    !socketPath.startsWith("/") ||
    Buffer.byteLength(socketPath, "utf8") > SOCKET_PATH_MAX_BYTES ||
    expectedCapability.byteLength !== 32
  ) {
    throw new Error("Invalid private broker credential IPC configuration.");
  }

  const directory = await stat(dirname(socketPath));
  if (
    !directory.isDirectory() ||
    (directory.mode & 0o700) !== 0o700 ||
    (directory.mode & 0o077) !== 0
  ) {
    throw new Error("Broker credential IPC directory permissions are not private.");
  }

  try {
    await lstat(socketPath);
    throw new Error("Broker credential IPC socket path already exists.");
  } catch (error) {
    if (isRecord(error) && error.code !== "ENOENT") throw error;
    if (error instanceof Error && error.message.includes("already exists")) throw error;
  }

  const sockets = new Set<Socket>();
  const inFlight = new Map<Socket, Promise<void>>();
  let closing = false;
  const server = createServer((socket) => {
    if (closing) {
      socket.destroy();
      return;
    }
    sockets.add(socket);
    socket.setNoDelay(true);
    socket.setTimeout(REQUEST_TIMEOUT_MS, () => socket.destroy());
    socket.on("close", () => sockets.delete(socket));
    socket.on("error", () => {});

    let buffer = Buffer.alloc(0);
    let handled = false;
    socket.on("data", (chunk: Buffer) => {
      if (closing || handled) {
        buffer.fill(0);
        buffer = Buffer.alloc(0);
        socket.destroy();
        return;
      }
      if (buffer.byteLength + chunk.byteLength > MAX_REQUEST_BYTES) {
        handled = true;
        buffer.fill(0);
        buffer = Buffer.alloc(0);
        writeResponse(socket, { requestId: "invalid", ok: false, errorCode: "request_too_large" });
        return;
      }

      buffer = Buffer.concat([buffer, chunk]);
      const newlineIndex = buffer.indexOf(0x0a);
      if (newlineIndex < 0) return;
      if (newlineIndex !== buffer.byteLength - 1) {
        handled = true;
        buffer.fill(0);
        buffer = Buffer.alloc(0);
        writeResponse(socket, { requestId: "invalid", ok: false, errorCode: "invalid_framing" });
        return;
      }

      handled = true;
      const payload = Buffer.from(buffer.subarray(0, newlineIndex));
      buffer.fill(0);
      buffer = Buffer.alloc(0);
      const operation = handleRequest(payload, expectedCapability, manager, beforeSessionReplacement)
        .then((response) => writeResponse(socket, response))
        .catch(() => writeResponse(socket, {
          requestId: "invalid",
          ok: false,
          errorCode: "broker_session_ipc_failed",
        }));
      inFlight.set(socket, operation);
      void operation.then(
        () => {
          payload.fill(0);
          if (inFlight.get(socket) === operation) inFlight.delete(socket);
        },
        () => {
          payload.fill(0);
          if (inFlight.get(socket) === operation) inFlight.delete(socket);
        },
      );
    });
    socket.on("end", () => {
      if (!handled) socket.destroy();
    });
  });

  await new Promise<void>((resolve, reject) => {
    server.once("error", reject);
    server.listen(socketPath, () => {
      server.removeListener("error", reject);
      resolve();
    });
  });

  try {
    await chmod(socketPath, SOCKET_MODE);
  } catch (error) {
    await new Promise<void>((resolve) => server.close(() => resolve()));
    await unlink(socketPath).catch(() => {});
    throw error;
  }

  let closePromise: Promise<void> | null = null;
  return {
    close: () => {
      if (closePromise) return closePromise;
      closing = true;
      closePromise = (async () => {
        // Stop accepting new clients first. Incomplete requests are discarded;
        // complete authenticated operations are drained before broker teardown.
        const listenerClosed = new Promise<void>((resolve, reject) => {
          server.close((error) => error ? reject(error) : resolve());
        });
        for (const socket of sockets) {
          if (!inFlight.has(socket)) socket.destroy();
        }
        await Promise.all([...inFlight.values()]);
        await listenerClosed;
        await unlink(socketPath).catch(() => {});
      })();
      return closePromise;
    },
  };
}
