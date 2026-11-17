import { createServer, type IncomingMessage, type Server, type ServerResponse } from "node:http";
import type { CapitalDemoRuntime } from "./market-data/capital-demo-runtime.ts";
import type { CapitalDemoStreamingRuntime, MarketDataStreamQuote } from "./market-data/capital-demo-streaming-runtime.ts";
import { normalizeCapitalHistoricalPrices, validateHistoricalDateRange, type HistoricalPriceResolution } from "./market-data/historical-prices.ts";

const SERVICE_NAME = "atheer-api";
const SERVICE_VERSION = "0.1.0";

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

function sendJson(response: ServerResponse, statusCode: number, payload: unknown): void {
  response.statusCode = statusCode;
  response.setHeader("content-type", "application/json; charset=utf-8");
  response.setHeader("cache-control", "no-store");
  response.end(JSON.stringify(payload));
}

export function createApiServer(
  marketData?: CapitalDemoRuntime,
  marketDataStream?: CapitalDemoStreamingRuntime,
): Server {
  return createServer((request, response) => {
    const url = new URL(request.url ?? "/", "http://127.0.0.1");
    const pathname = url.pathname;

    if (pathname.startsWith("/market-data/")) {
      void handleMarketDataRequest(request, request.method ?? "GET", url, response, marketData, marketDataStream);
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
  method: string,
  url: URL,
  response: ServerResponse,
  runtime: CapitalDemoRuntime | undefined,
  streamRuntime: CapitalDemoStreamingRuntime | undefined,
): Promise<void> {
  const pathname = url.pathname;
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

  if (!runtime) {
    sendJson(response, 503, { error: "market_data_runtime_unavailable" });
    return;
  }

  try {
    if (pathname === "/market-data/connect" && method === "POST") {
      const status = await runtime.connect();
      sendJson(response, status.state === "connected" ? 200 : 503, status);
      return;
    }
    if (pathname === "/market-data/disconnect" && method === "POST") {
      await streamRuntime?.disconnect();
      sendJson(response, 200, await runtime.disconnect());
      return;
    }
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

      let unsubscribe: (() => void) | undefined;
      let keepAlive: ReturnType<typeof setInterval> | undefined;
      let statusTimer: ReturnType<typeof setInterval> | undefined;
      let closed = false;
      response.on("close", () => {
        closed = true;
        if (keepAlive) clearInterval(keepAlive);
        if (statusTimer) clearInterval(statusTimer);
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

        response.write("event: status\ndata: " + JSON.stringify(streamRuntime.status()) + "\n\n");
        for (const quote of streamRuntime.latest(epics)) {
          response.write("event: quote\ndata: " + JSON.stringify(quote) + "\n\n");
        }
        statusTimer = setInterval(() => {
          if (!response.destroyed) {
            response.write("event: status\ndata: " + JSON.stringify(streamRuntime.status()) + "\n\n");
          }
        }, 5_000);
        keepAlive = setInterval(() => {
          if (!response.destroyed) response.write(": keep-alive\n\n");
        }, 15_000);
      } catch {
        if (!response.destroyed) {
          response.write("event: error\ndata: " + JSON.stringify({ error: "market_data_stream_connection_failed" }) + "\n\n");
          response.end();
        }
        return;
      }
      return;
    }

    if (pathname === "/market-data/history" && method === "GET") {
      const epic = url.searchParams.get("epic") ?? "";
      if (!/^[A-Za-z0-9_.-]{1,64}$/.test(epic)) {
        sendJson(response, 400, { error: "invalid_epic" });
        return;
      }

      const resolution = url.searchParams.get("resolution") ?? "MINUTE";
      const allowedResolutions: readonly HistoricalPriceResolution[] = [
        "MINUTE", "MINUTE_5", "MINUTE_15", "MINUTE_30", "HOUR", "HOUR_4", "DAY", "WEEK",
      ];
      if (!allowedResolutions.includes(resolution as HistoricalPriceResolution)) {
        sendJson(response, 400, { error: "invalid_resolution" });
        return;
      }

      const rawMax = url.searchParams.get("max") ?? "100";
      if (!/^\d+$/.test(rawMax) || Number(rawMax) < 1 || Number(rawMax) > 1000) {
        sendJson(response, 400, { error: "invalid_max" });
        return;
      }

      const from = url.searchParams.get("from") ?? undefined;
      const to = url.searchParams.get("to") ?? undefined;
      if ((from === undefined) !== (to === undefined)) {
        sendJson(response, 400, { error: "incomplete_date_range" });
        return;
      }
      if (from !== undefined && to !== undefined) {
        try {
          validateHistoricalDateRange(from, to);
        } catch {
          sendJson(response, 400, { error: "invalid_date_range" });
          return;
        }
      }

      const max = Number(rawMax);
      const result = await runtime.getPriceHistory(
        epic,
        resolution as HistoricalPriceResolution,
        max,
        from,
        to,
      );
      const batch = normalizeCapitalHistoricalPrices(epic, resolution as HistoricalPriceResolution, result.prices, Date.now());
      sendJson(response, 200, {
        ...batch,
        request: { from: from ?? null, to: to ?? null, max },
        pagination: { limitReached: batch.candles.length === max },
      });
      return;
    }
  } catch (error) {
    const message = error instanceof Error ? error.message : "market_data_request_failed";
    sendJson(response, 502, { error: message });
    return;
  }

  const allowedMethod = pathname === "/market-data/connect" || pathname === "/market-data/disconnect"
    ? "POST"
    : pathname === "/market-data/status" || pathname === "/market-data/markets" || pathname === "/market-data/history" || pathname === "/market-data/stream"
      ? "GET"
      : undefined;
  if (allowedMethod) {
    response.setHeader("allow", allowedMethod);
    sendJson(response, 405, { error: "method_not_allowed" });
    return;
  }
  sendJson(response, 404, { error: "not_found" });
}
