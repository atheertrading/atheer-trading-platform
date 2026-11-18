import {
  createServer,
  type IncomingMessage,
  type Server,
  type ServerResponse,
} from "node:http";
import type { CapitalDemoCredentials } from "./market-data/capital-demo-client.ts";
import type { BrokerSessionManager } from "./market-data/broker-session-manager.ts";
import type {
  CapitalDemoStreamingRuntime,
  MarketDataStreamQuote,
} from "./market-data/capital-demo-streaming-runtime.ts";
import { CapitalDemoApiError } from "./market-data/capital-demo-client.ts";
import { hasValidIPCCapability } from "./security/ipc-capability.ts";

const SERVICE_NAME = "atheer-api";
const SERVICE_VERSION = "0.1.0";
const MAX_CREDENTIAL_BODY_BYTES = 8_192;

interface LiveHealthResponse {
  readonly status: "ok";
  readonly service: string;
  readonly version: string;
  readonly timestamp: string;
}
interface ReadinessResponse {
  readonly status: "not_ready";
  readonly service: string;
  readonly timestamp: string;
  readonly dependencies: {
    readonly persistence: "not_configured";
    readonly broker: "not_configured";
  };
  readonly trading: {
    readonly enabled: false;
    readonly status: "disabled";
  };
}
class RequestBodyError extends Error {
  constructor(
    readonly statusCode: number,
    readonly errorCode: string,
  ) {
    super(errorCode);
  }
}

function sendJson(response: ServerResponse, statusCode: number, payload: unknown): void {
  response.statusCode = statusCode;
  response.setHeader("content-type", "application/json; charset=utf-8");
  response.setHeader("cache-control", "no-store");
  response.setHeader("pragma", "no-cache");
  response.end(JSON.stringify(payload));
}

function hasSafeNativeRequestContext(request: IncomingMessage): boolean {
  const origin = request.headers.origin;
  const fetchSite = request.headers["sec-fetch-site"];
  return origin === undefined && (fetchSite === undefined || fetchSite === "none");
}

function headerValue(value: string | string[] | undefined): string | undefined {
  return typeof value === "string" ? value : undefined;
}

function brokerSessionResponseStatus(
  status: ReturnType<BrokerSessionManager["status"]>,
): number {
  if (status.state === "connected") return 200;
  if (
    status.lastError?.includes("HTTP 401") ||
    status.lastError?.includes("HTTP 403") ||
    status.lastError?.includes("rejected or expired")
  ) return 401;
  if (
    status.lastError?.includes("HTTP 429") ||
    status.lastError?.includes("rate-limited")
  ) return 429;
  return 503;
}


async function readBrokerCredentials(request: IncomingMessage): Promise<CapitalDemoCredentials> {
  const contentType = headerValue(request.headers["content-type"]);
  if (contentType?.split(";")[0]?.trim().toLowerCase() !== "application/json") {
    throw new RequestBodyError(415, "unsupported_media_type");
  }

  const contentLength = headerValue(request.headers["content-length"]);
  if (contentLength !== undefined) {
    if (!/^\d+$/.test(contentLength)) {
      throw new RequestBodyError(400, "invalid_content_length");
    }
    if (Number(contentLength) > MAX_CREDENTIAL_BODY_BYTES) {
      throw new RequestBodyError(413, "payload_too_large");
    }
  }

  const decoder = new TextDecoder();
  let body = "";
  let totalBytes = 0;
  for await (const chunk of request) {
    totalBytes += chunk.byteLength;
    if (totalBytes > MAX_CREDENTIAL_BODY_BYTES) {
      throw new RequestBodyError(413, "payload_too_large");
    }
    body += decoder.decode(chunk, { stream: true });
  }
  body += decoder.decode();

  let parsed: unknown;
  try {
    parsed = JSON.parse(body);
  } catch {
    body = "";
    throw new RequestBodyError(400, "invalid_json");
  }
  body = "";

  if (parsed === null || typeof parsed !== "object" || Array.isArray(parsed)) {
    throw new RequestBodyError(400, "invalid_credentials_payload");
  }

  const payload = parsed as Record<string, unknown>;
  const allowedKeys = ["apiKey", "identifier", "password"];
  const keys = Object.keys(payload);
  if (keys.length !== allowedKeys.length || keys.some((key) => !allowedKeys.includes(key))) {
    throw new RequestBodyError(400, "invalid_credentials_payload");
  }

  const apiKey = typeof payload.apiKey === "string" ? payload.apiKey.trim() : "";
  const identifier = typeof payload.identifier === "string" ? payload.identifier.trim() : "";
  const password = typeof payload.password === "string" ? payload.password : "";
  if (
    apiKey.length === 0 || apiKey.length > 512 ||
    identifier.length === 0 || identifier.length > 512 ||
    password.length === 0 || password.length > 2_048
  ) {
    throw new RequestBodyError(400, "invalid_credentials_payload");
  }

  return { apiKey, identifier, password };
}

export function createApiServer(
  marketData: BrokerSessionManager | undefined,
  ipcCapability: Uint8Array | undefined,
  marketDataStream?: CapitalDemoStreamingRuntime,
): Server {
  return createServer((request, response) => {
    const url = new URL(request.url ?? "/", "http://127.0.0.1");
    const pathname = url.pathname;

    if (pathname.startsWith("/market-data/") || pathname.startsWith("/broker-session/")) {
      if (
        !hasValidIPCCapability(request, ipcCapability) ||
        !hasSafeNativeRequestContext(request)
      ) {
        sendJson(response, 401, { error: "unauthorized" });
        return;
      }
      void handleMarketDataRequest(
        request,
        url,
        response,
        marketData,
        marketDataStream,
      );
      return;
    }

    const knownRoute = pathname === "/health/live" || pathname === "/health/ready";
    if (!knownRoute) {
      sendJson(response, 404, { error: "not_found" });
      return;
    }
    if (request.method !== "GET") {
      response.setHeader("allow", "GET");
      sendJson(response, 405, { error: "method_not_allowed" });
      return;
    }
    if (pathname === "/health/live") {
      const payload: LiveHealthResponse = {
        status: "ok",
        service: SERVICE_NAME,
        version: SERVICE_VERSION,
        timestamp: new Date().toISOString(),
      };
      sendJson(response, 200, payload);
      return;
    }
    const payload: ReadinessResponse = {
      status: "not_ready",
      service: SERVICE_NAME,
      timestamp: new Date().toISOString(),
      dependencies: { persistence: "not_configured", broker: "not_configured" },
      trading: { enabled: false, status: "disabled" },
    };
    sendJson(response, 503, payload);
  });
}

async function handleMarketDataRequest(
  request: IncomingMessage,
  url: URL,
  response: ServerResponse,
  runtime: BrokerSessionManager | undefined,
  streamRuntime: CapitalDemoStreamingRuntime | undefined,
): Promise<void> {
  const method = request.method ?? "GET";
  const pathname = url.pathname;

  if (pathname === "/broker-session/status" && method === "GET") {
    sendJson(response, 200, runtime?.status() ?? {
      provider: "capital.com",
      environment: "DEMO",
      state: "not_configured",
    });
    return;
  }

  if (pathname === "/broker-session/connect" && method === "POST") {
    if (!runtime) {
      sendJson(response, 503, { error: "broker_session_manager_unavailable" });
      return;
    }
    try {
      const credentials = await readBrokerCredentials(request);
      const status = await runtime.connect(credentials, async () => {
        await streamRuntime?.disconnect();
      });
      sendJson(response, brokerSessionResponseStatus(status), status);
    } catch (error) {
      if (error instanceof RequestBodyError) {
        sendJson(response, error.statusCode, { error: error.errorCode });
        return;
      }
      sendJson(response, 502, { error: "broker_session_connect_failed" });
    }
    return;
  }

  if (pathname === "/broker-session/disconnect" && method === "POST") {
    if (!runtime) {
      sendJson(response, 503, { error: "broker_session_manager_unavailable" });
      return;
    }
    try {
      await streamRuntime?.disconnect();
      sendJson(response, 200, await runtime.disconnect());
    } catch {
      sendJson(response, 502, { error: "broker_session_disconnect_failed" });
    }
    return;
  }

  if (pathname === "/market-data/status" && method === "GET") {
    sendJson(response, 200, {
      ...(runtime?.status() ?? {
        provider: "capital.com",
        environment: "DEMO",
        state: "not_configured",
      }),
      streaming: streamRuntime?.status() ?? {
        provider: "capital.com",
        environment: "DEMO",
        state: "disconnected",
        activeInstrumentCount: 0,
        invalidQuoteCount: 0,
        outOfOrderQuoteCount: 0,
        duplicateQuoteCount: 0,
      },
    });
    return;
  }

  if (pathname === "/market-data/stream" && method === "GET") {
    if (!streamRuntime) {
      sendJson(response, 503, { error: "market_data_stream_unavailable" });
      return;
    }

    const rawEpics = url.searchParams.get("epics") ?? "";
    const epics = rawEpics.split(",").map((epic) => epic.trim()).filter(Boolean);
    if (
      epics.length === 0 ||
      epics.length > 40 ||
      epics.some((epic) => !/^[A-Za-z0-9_.-]{1,64}$/.test(epic))
    ) {
      sendJson(response, 400, { error: "invalid_stream_instruments" });
      return;
    }

    response.writeHead(200, {
      "content-type": "text/event-stream; charset=utf-8",
      "cache-control": "no-cache, no-store",
      connection: "keep-alive",
      "x-accel-buffering": "no",
    });
    response.write("event: status\ndata: " + JSON.stringify(streamRuntime.status()) + "\n\n");

    let unsubscribe: (() => void) | undefined;
    let keepAlive: ReturnType<typeof setInterval> | undefined;
    let closed = false;
    response.on("close", () => {
      closed = true;
      if (keepAlive) clearInterval(keepAlive);
      unsubscribe?.();
    });

    try {
      unsubscribe = await streamRuntime.subscribe(epics, (quote: MarketDataStreamQuote) => {
        if (!response.destroyed) {
          response.write("event: quote\ndata: " + JSON.stringify(quote) + "\n\n");
        }
      });
      if (closed) {
        unsubscribe();
        return;
      }
      for (const quote of streamRuntime.latest(epics)) {
        response.write("event: quote\ndata: " + JSON.stringify(quote) + "\n\n");
      }
      keepAlive = setInterval(() => {
        if (!response.destroyed) response.write(": keep-alive\n\n");
      }, 15_000);
    } catch {
      if (!response.destroyed) {
        response.write(
          "event: error\ndata: " +
            JSON.stringify({ error: "market_data_stream_connection_failed" }) +
            "\n\n",
        );
        response.end();
      }
    }
    return;
  }

  if (!runtime) {
    sendJson(response, 503, { error: "broker_session_manager_unavailable" });
    return;
  }

  try {
    if (pathname === "/market-data/markets" && method === "GET") {
      const searchTerm = url.searchParams.get("searchTerm") ?? "";
      const result = await runtime.getMarkets(searchTerm);
      sendJson(response, 200, {
        provider: "capital.com",
        environment: "DEMO",
        ...result,
      });
      return;
    }
    if (pathname === "/market-data/history" && method === "GET") {
      const epic = url.searchParams.get("epic") ?? "";
      const resolution = url.searchParams.get("resolution") ?? "MINUTE";
      const allowedResolutions = [
        "MINUTE",
        "MINUTE_5",
        "MINUTE_15",
        "MINUTE_30",
        "HOUR",
        "HOUR_4",
        "DAY",
        "WEEK",
      ];
      if (!allowedResolutions.includes(resolution)) {
        sendJson(response, 400, { error: "invalid_resolution" });
        return;
      }
      const rawMax = url.searchParams.get("max") ?? "100";
      if (!/^\d+$/.test(rawMax)) {
        sendJson(response, 400, { error: "invalid_max" });
        return;
      }
      const result = await runtime.getPriceHistory(
        epic,
        resolution as "MINUTE" | "MINUTE_5" | "MINUTE_15" | "MINUTE_30" | "HOUR" | "HOUR_4" | "DAY" | "WEEK",
        Number(rawMax),
      );
      sendJson(response, 200, {
        provider: "capital.com",
        environment: "DEMO",
        ...result,
      });
      return;
    }
  } catch (error) {
    const message = error instanceof CapitalDemoApiError
      ? error.message
      : "market_data_request_failed";
    sendJson(response, 502, { error: message });
    return;
  }

  const allowedMethod = pathname === "/broker-session/connect" ||
      pathname === "/broker-session/disconnect"
    ? "POST"
    : pathname === "/broker-session/status" ||
      pathname === "/market-data/status" ||
      pathname === "/market-data/markets" ||
      pathname === "/market-data/history" ||
      pathname === "/market-data/stream"
      ? "GET"
      : undefined;
  if (allowedMethod) {
    response.setHeader("allow", allowedMethod);
    sendJson(response, 405, { error: "method_not_allowed" });
    return;
  }
  sendJson(response, 404, { error: "not_found" });
}
