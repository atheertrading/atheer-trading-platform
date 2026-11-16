# ATHEER API — Local Development Service

This package is the first backend operational slice. It is deliberately limited to process liveness and platform readiness. It does not expose trading, account, market-data, broker, strategy, risk, or order-management APIs.

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
- GET /health/ready returns HTTP 503 while persistence and broker adapters are not configured. It reports trading as disabled.

A successful liveness response is not evidence that the trading platform is ready. Readiness is fail-closed and must not be changed to ready until the required dependencies are implemented and independently verified.

## Runtime and security boundaries

- No runtime npm dependencies are used.
- TypeScript is a pinned development-only dependency.
- The current TypeScript declaration shim exposes only the small Node core HTTP/process surface used by this package; replace it with the standard Node type package when dependency policy is expanded.
- No broker credentials, database credentials, account information, market data, or order state are read or logged.
- No broker connection or trading operation is possible through this service.
