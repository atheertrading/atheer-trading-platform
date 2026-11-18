# ATHEER API — Managed Local Backend

This package contains the local Node.js 24 / TypeScript backend for process health, a backend-owned Capital.com DEMO broker session, and read-only market-data operations. It does not expose order placement, position dealing, account mutation, strategy execution, or LIVE trading.

## Requirements

- Node.js 24.22.3
- npm bundled with Node.js
- Network access to the local loopback interface only

## Setup and commands

From this directory:

    npm ci
    npm run typecheck
    npm test
    npm start

The service binds only to `127.0.0.1`. The default development port is 4100; `PORT=0` allows the operating system to assign an ephemeral port for a supervised application launch. `HOST` is restricted to `127.0.0.1`; do not expose the process on a LAN or public interface.

## Health routes

- `GET /health/live` returns HTTP 200 when the process can answer requests.
- `GET /health/ready` returns HTTP 503 while persistence and the complete broker/trading dependencies are not configured. It reports trading as disabled.

A successful liveness response is not evidence that the trading platform is ready. Readiness is fail-closed and must not be changed to ready until the required dependencies are implemented and independently verified.

## Versioned API contract

The implemented local HTTP interface is described by the OpenAPI 3.1 document at
[`openapi.yaml`](./openapi.yaml). It covers only the verified health, broker-session
status, market search/history, and authenticated SSE routes. It does not define a
credential-submission HTTP route, dealing API, orders, positions, or LIVE operations.
The contract marks the per-process Bearer capability and native request-context
requirements for every broker-sensitive operation.

## Managed broker-session IPC

The backend is the single owner of Capital.com DEMO credentials, REST session tokens, keepalive, and streaming connection information.

- The native parent process creates a private temporary directory with owner-only permissions and supplies the Unix-domain socket path to the child.
- The backend creates the credential socket with owner read/write permissions. The parent-owned directory must remain owner-only.
- A fresh 256-bit per-process capability is delivered through the private child-process stdin bootstrap. It is not placed in command-line arguments or environment variables.
- Credential operations use a bounded, newline-framed Unix-domain socket protocol with a strict operation allowlist (`connect` and `disconnect`), request-size limits, request correlation, and capability validation.
- Broker API key, login identifier, and password are never sent through HTTP, command-line arguments, or environment variables. Credentials and provider session tokens are not returned in IPC responses or logs.
- Broker session connect, replacement, and disconnect transitions are serialized by the backend session manager.
- Shutdown stops accepting credential IPC, drains completed authenticated operations, then releases streaming and broker-session resources. If a shutdown step exceeds its observation deadline, dependent teardown steps are not started; the process hard deadline remains armed.

The capability authenticates the local IPC caller; it does not replace Capital.com authentication, broker-account authorization, or the trading RiskEngine.

## Authenticated market-data routes

The following broker-sensitive HTTP routes require the per-process Bearer capability and the native request context. They are loopback-only and are not general browser-facing endpoints.

- `GET /broker-session/status` — backend-owned Capital.com DEMO session state.
- `GET /market-data/status` — broker-session and stream status.
- `GET /market-data/markets?searchTerm=...` — provider instrument search.
- `GET /market-data/history?epic=...&resolution=MINUTE&max=100` — provider historical price records.
- `GET /market-data/stream?epics=...` — authenticated Server-Sent Events stream for 1–40 validated instrument EPICs.

Health endpoints are separate from the broker-sensitive surface. No broker credential submission, dealing, order, position mutation, or LIVE endpoint is exposed over HTTP.

Every successful broker market-data response is labeled with `provider=capital.com` and `environment=DEMO`. Historical price records are not promoted to normalized OHLC candles unless the relevant market-data contract explicitly defines those semantics.

## Market-data and broker safety

- The Capital.com DEMO REST endpoint and streaming host are fixed and validated; callers cannot select a LIVE base URL or an arbitrary WebSocket endpoint.
- CST and X-SECURITY-TOKEN remain backend-owned and are never returned to the native client.
- No broker credentials, session tokens, account values, quotes, or order state are logged.
- Session expiry or provider authorization failure invalidates or blocks the session according to the broker-session recovery policy.
- The shared REST client applies a process-wide 100 ms request-start budget (10 requests/second); session creation has its own 1-second throttle.
- HTTP 429 responses trigger at most three retries per request. The client honors a numeric or HTTP-date `Retry-After` value (bounded to 60 seconds), or uses exponential full jitter when the header is absent/invalid. The resulting cooldown is shared by all REST requests in the process. Network timeouts and other uncertain transport failures are not automatically retried; future dealing operations must define their own idempotency/reconciliation contract before any retry policy is enabled.
- The stream enforces the provider instrument cap, preserves provider timestamps separately from local receipt time, validates quotes, suppresses duplicate/out-of-order observations, and reports freshness/degraded states.
- No missing broker observations are fabricated or interpolated.
- This service is read-only with respect to trading. It has no OMS submission path or Execution Gateway.

## Runtime and security boundaries

- No runtime npm dependencies are used by this API package; TypeScript is a pinned development dependency.
- TypeScript is compiled to JavaScript before execution; the runtime does not execute TypeScript source.
- The current declaration shim exposes only the Node core interfaces used by this package.
- The backend remains loopback-only. Loopback binding alone is not authentication; broker-sensitive routes require the capability.
- Persistence is not configured in this workstream branch. Readiness must remain not-ready until all required platform dependencies are independently qualified.
- `CAP_ALLOW_TRADING=false` remains enforced. No DEMO dealing, LIVE dealing, production release, or deployment qualification is claimed.
