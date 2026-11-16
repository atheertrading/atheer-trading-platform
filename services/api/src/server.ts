import { createServer, type Server, type ServerResponse } from "node:http";

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

function sendJson(
  response: ServerResponse,
  statusCode: number,
  payload: LiveHealthResponse | ReadinessResponse | { readonly error: string },
): void {
  response.statusCode = statusCode;
  response.setHeader("content-type", "application/json; charset=utf-8");
  response.setHeader("cache-control", "no-store");
  response.end(JSON.stringify(payload));
}

export function createApiServer(): Server {
  return createServer((request, response) => {
    const pathname = new URL(request.url ?? "/", "http://127.0.0.1").pathname;
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
