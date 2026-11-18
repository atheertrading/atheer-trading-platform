import {
  createServer,
  type IncomingMessage,
  type Server,
  type ServerResponse,
} from "node:http";
import type { BrokerSessionManager } from "./market-data/broker-session-manager.ts";
import type {
  CapitalDemoStreamingRuntime,
  MarketDataStreamQuote,
} from "./market-data/capital-demo-streaming-runtime.ts";
import { CapitalDemoApiError } from "./market-data/capital-demo-client.ts";
import { hasValidIPCCapability } from "./security/ipc-capability.ts";

const SERVICE_NAME = "atheer-api";
const SERVICE_VERSION = "0.1.0";
const MAX_SEARCH_TERM_LENGTH = 100;
const MAX_HISTORY_RECORDS = 1_000;
const ALLOWED_HISTORY_RESOLUTIONS = [
  "MINUTE",
  "MINUTE_5",
  "MINUTE_15",
  "MINUTE_30",
  "HOUR",
  "HOUR_4",
  "DAY",
  "WEEK",
] as const;
type HistoryResolution = typeof ALLOWED_HISTORY_RESOLUTIONS[number];

function isValidEpic(value: string): boolean {
  return /^[A-Za-z0-9_.-]{1,64}$/.test(value);
}

function isSessionUnavailable(runtime: BrokerSessionManager): boolean {
  const state = runtime.status().state;
  return state === "not_configured" ||
    state === "disconnected" ||
    state === "connecting" ||
    state === "degraded" ||
    state === "error";
}

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
    readonly broker: "not_configured" | "disconnected" | "connecting" | "connected" | "degraded" | "error";
  };
  readonly trading: {
    readonly enabled: false;
    readonly status: "disabled";
  };
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
      dependencies: {
        persistence: "not_configured",
        broker: marketData?.status().state ?? "not_configured",
      },
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
      // Publish the confirmed provider subscription state, not only the
      // pre-subscription state sent when the SSE connection was opened.
      response.write("event: status\ndata: " + JSON.stringify(streamRuntime.status()) + "\n\n");
      for (const quote of streamRuntime.latest(epics)) {
        response.write("event: quote\ndata: " + JSON.stringify(quote) + "\n\n");
      }
      keepAlive = setInterval(() => {
        if (!response.destroyed) {
          response.write(": keep-alive\n\n");
          // Provider WebSocket reconnects happen behind this stable local SSE
          // connection; periodic status events keep the native UI truthful.
          response.write("event: status\ndata: " + JSON.stringify(streamRuntime.status()) + "\n\n");
        }
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

  const isMarketSearch = pathname === "/market-data/markets";
  const isMarketHistory = pathname === "/market-data/history";
  const allowedMethod = pathname === "/broker-session/status" ||
      pathname === "/market-data/status" ||
      pathname === "/market-data/markets" ||
      pathname === "/market-data/history" ||
      pathname === "/market-data/stream"
      ? "GET"
      : undefined;

  if (!isMarketSearch && !isMarketHistory) {
    if (allowedMethod) {
      response.setHeader("allow", allowedMethod);
      sendJson(response, 405, { error: "method_not_allowed" });
    } else {
      sendJson(response, 404, { error: "not_found" });
    }
    return;
  }

  if (method !== "GET") {
    response.setHeader("allow", "GET");
    sendJson(response, 405, { error: "method_not_allowed" });
    return;
  }

  let searchTerm: string | undefined;
  let epic: string | undefined;
  let resolution: HistoryResolution | undefined;
  let max: number | undefined;

  if (isMarketSearch) {
    searchTerm = (url.searchParams.get("searchTerm") ?? "").trim();
    if (searchTerm.length < 1 || searchTerm.length > MAX_SEARCH_TERM_LENGTH) {
      sendJson(response, 400, { error: "invalid_search_term" });
      return;
    }
  } else {
    epic = (url.searchParams.get("epic") ?? "").trim();
    if (!isValidEpic(epic)) {
      sendJson(response, 400, { error: "invalid_epic" });
      return;
    }

    const rawResolution = url.searchParams.get("resolution") ?? "MINUTE";
    if (!ALLOWED_HISTORY_RESOLUTIONS.includes(rawResolution as HistoryResolution)) {
      sendJson(response, 400, { error: "invalid_resolution" });
      return;
    }
    resolution = rawResolution as HistoryResolution;

    const rawMax = url.searchParams.get("max") ?? "100";
    max = Number(rawMax);
    if (
      !/^\d+$/.test(rawMax) ||
      !Number.isSafeInteger(max) ||
      max < 1 ||
      max > MAX_HISTORY_RECORDS
    ) {
      sendJson(response, 400, { error: "invalid_max" });
      return;
    }
  }

  if (!runtime || isSessionUnavailable(runtime)) {
    sendJson(response, 503, { error: "broker_session_unavailable" });
    return;
  }

  try {
    if (isMarketSearch) {
      const result = await runtime.getMarkets(searchTerm!);
      sendJson(response, 200, {
        provider: "capital.com",
        environment: "DEMO",
        ...result,
      });
      return;
    }

    const result = await runtime.getPriceHistory(epic!, resolution!, max!);
    sendJson(response, 200, {
      provider: "capital.com",
      environment: "DEMO",
      ...result,
    });
  } catch (error) {
    const message = error instanceof CapitalDemoApiError
      ? error.message
      : "market_data_request_failed";
    sendJson(response, 502, { error: message });
  }

}
