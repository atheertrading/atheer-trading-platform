# ATHEER API — Local Development Service

This package contains the first backend operational slice: process health plus a backend-owned Capital.com DEMO market-data adapter. It does not expose order placement, position dealing, account mutation, strategy execution, or LIVE trading.

## Requirements

- Node.js 24.x
- npm bundled with Node.js
- Network access to the local loopback interface only

## Setup and commands

From this directory:

    npm ci
    npm run typecheck
    npm test
    npm start

The service listens on 127.0.0.1:4100 by default. PORT may select another valid TCP port. HOST is intentionally restricted to 127.0.0.1; the service must not be exposed on a LAN or public interface.

## Health routes

- GET /health/live returns HTTP 200 when the process can answer requests.
- GET /health/ready returns HTTP 503 while persistence and the complete broker/trading dependencies are not configured. It reports trading as disabled.

A successful liveness response is not evidence that the trading platform is ready. Readiness is fail-closed and must not be changed to ready until the required dependencies are implemented and independently verified.

## API contract

The versioned OpenAPI 3.1 contract for the routes implemented by this service is
[openapi.yaml](./openapi.yaml). It describes the current local-development service
(version 0.1.0), not a production-ready or externally exposed API. The current HTTP
revision is loopback-bound and does not yet enforce the per-process application capability;
do not expose it beyond 127.0.0.1. The private credential IPC and authenticated managed
runtime work remains a separate integration gate.

## Capital.com DEMO market-data routes

Credentials are read only by the backend process:

- CAPITAL_COM_DEMO_API_KEY
- CAPITAL_COM_DEMO_IDENTIFIER
- CAPITAL_COM_DEMO_PASSWORD

All three values must be present to enable DEMO connection. Supply them through a secure local environment or secret store. Never commit them, put them in a client request, or paste them into GitHub.

- GET /market-data/status — provider/environment/connection state; never returns credentials or session tokens.
- POST /market-data/connect — creates a Capital.com DEMO session using backend-held credentials.
- POST /market-data/disconnect — terminates the current DEMO session.
- GET /market-data/markets?searchTerm=... — searches provider instruments; `searchTerm` must contain 1–100 characters after trimming (otherwise HTTP 400).
- GET /market-data/history?epic=...&resolution=MINUTE&max=100 — retrieves provider historical prices. EPIC must match `[A-Za-z0-9_.-]{1,64}` after trimming; `max` is an integer from 1 through 1000 (default 100). Invalid EPIC, resolution, or `max` values return HTTP 400.

Every successful market-data response is explicitly labeled provider=capital.com and environment=DEMO. Routes are served only by the loopback-bound local API. No trading endpoints exist.

## Market-data safety

- Capital.com DEMO endpoint is fixed in code; callers cannot select a LIVE base URL.
- CST and X-SECURITY-TOKEN remain in backend memory and are never returned by routes.
- No broker credentials, session tokens, account values, quotes, or order state are logged.
- Session expiry or provider connectivity failure invalidates the in-memory session and blocks further market-data reads until reconnect.
- Normalized streaming quote contracts preserve provider time separately from local receipt time.
- Freshness policy must be explicitly supplied by the caller; stale, malformed, future-dated, or invalid-policy quotes fail closed for automated decisions.
- This increment does not yet implement the Capital.com WebSocket stream or qualify the Market Watch as real-time.

## Runtime and security boundaries

- No runtime npm dependencies are used.
- TypeScript is a pinned development-only dependency.
- The current TypeScript declaration shim exposes only the small Node core HTTP/process surface used by this package; replace it with the standard Node type package when dependency policy is expanded.
- TypeScript is compiled to JavaScript before execution; the runtime does not execute TypeScript source.
- No database credentials, account information, or order state are read or logged.
