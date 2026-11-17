import { createServer, type Server, type ServerResponse } from "node:http";
import type { CapitalDemoRuntime } from "./market-data/capital-demo-runtime.ts";

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

export function createApiServer(marketData?: CapitalDemoRuntime): Server {
  return createServer((request, response) => {
    const url = new URL(request.url ?? "/", "http://127.0.0.1");
    const pathname = url.pathname;

    if (pathname.startsWith("/market-data/")) {
      void handleMarketDataRequest(request.method ?? "GET", url, response, marketData);
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
  method: string,
  url: URL,
  response: ServerResponse,
  runtime: CapitalDemoRuntime | undefined,
): Promise<void> {
  const pathname = url.pathname;
  if (pathname === "/market-data/status" && method === "GET") {
    sendJson(response, 200, runtime?.status() ?? {
      provider: "capital.com",
      environment: "DEMO",
      state: "not_configured",
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
    if (pathname === "/market-data/history" && method === "GET") {
      const epic = url.searchParams.get("epic") ?? "";
      const resolution = url.searchParams.get("resolution") ?? "MINUTE";
      const allowedResolutions = ["MINUTE", "MINUTE_5", "MINUTE_15", "MINUTE_30", "HOUR", "HOUR_4", "DAY", "WEEK"];
      if (!allowedResolutions.includes(resolution)) {
        sendJson(response, 400, { error: "invalid_resolution" });
        return;
      }
      const rawMax = url.searchParams.get("max") ?? "100";
      if (!/^\\d+$/.test(rawMax)) {
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
    const message = error instanceof Error ? error.message : "market_data_request_failed";
    sendJson(response, 502, { error: message });
    return;
  }

  const allowedMethod = pathname === "/market-data/connect" || pathname === "/market-data/disconnect"
    ? "POST"
    : pathname === "/market-data/status" || pathname === "/market-data/markets" || pathname === "/market-data/history"
      ? "GET"
      : undefined;
  if (allowedMethod) {
    response.setHeader("allow", allowedMethod);
    sendJson(response, 405, { error: "method_not_allowed" });
    return;
  }
  sendJson(response, 404, { error: "not_found" });
}
