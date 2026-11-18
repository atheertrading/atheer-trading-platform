# Engineering Session — Capital.com DEMO and Market Data Foundation

**Date:** 2026-11-17  
**Workstream:** ATP-MD-001  
**Branch:** feat/market-data-capital-demo-foundation  
**Pull request:** #25 — https://github.com/atheertrading/atheer-trading-platform/pull/25  
**Base:** PR #24 head e9e7085fc7699da19fe934dfd35274e8c8217922

## Owner-approved objective

Move ATHEER from a presentation-only application toward a data-driven trading application. Preserve Command Center, Workspace, and Navigation Architecture. Complete Capital.com DEMO integration first, then Market Data Architecture and real Market Watch, then charting and trading-domain surfaces. All execution remains disabled and governed by centralized risk controls.

## Source inspection

- Inspected root AGENTS.md and the active PR #24 source tree.
- PR #24 remains open/draft; its Command Center intentionally shows unavailable market/account states and no synthetic financial values.
- The backend before this increment exposed only /health/live and /health/ready; readiness remained HTTP 503 with broker/persistence not configured and trading disabled.
- No Capital.com adapter, market-data service, quote stream, or market-data route existed in the inspected PR #24 tree.
- services/api is Node.js 24 / TypeScript, with dependency-free runtime and Node test runner.

## Official provider documentation reviewed

- https://open-api.capital.com/
- https://help.capitalccuk.com/hc/en-us/articles/6631472131602-Can-I-use-Capital-com-API-on-the-Demo-account

Verified provider facts:
- REST DEMO base URL: https://demo-api-capital.backend-capital.com/.
- Session creation: POST /api/v1/session, API key in X-CAP-API-KEY, login identifier/password in JSON, and encryptedPassword: false for plain API-key password.
- Session response returns CST and X-SECURITY-TOKEN headers; authenticated requests require both.
- Session inactivity timeout is ten minutes; provider documents ping to maintain a session.
- REST market search and price history endpoints are documented.
- WebSocket market quote and OHLC message shapes, maximum 40 epics, and ping behavior are documented. The public API page names the production streaming host but does not explicitly state the DEMO streaming host. A third-party AsyncAPI description advertises a DEMO streaming hostname; it is not treated as authoritative. Confirm the exact DEMO streaming endpoint with Capital.com before hardcoding or qualifying it.
- Capital.com states API keys have trading privileges and does not currently offer read-only API keys. ATHEER must maintain a provider capability boundary and use DEMO credentials only.

## Implemented on the feature branch

- services/api/src/market-data/capital-demo-client.ts
  - Fixed DEMO REST base URL.
  - Session create/terminate and ping.
  - Market search and historical price retrieval.
  - No order, position-dealing, account-mutation, or LIVE methods.
  - Error messages do not echo provider response bodies.
- services/api/src/market-data/capital-demo-runtime.ts
  - Backend-memory session lifecycle.
  - Environment credential loading; all three DEMO values are required.
  - Concurrent connect coalescing and disconnect-during-connect invalidation.
  - Session expiry/auth rejection invalidates the session.
  - Status projection excludes credentials and session tokens.
- services/api/src/market-data/contracts.ts
  - Provider-neutral DEMO quote contract.
  - Provider timestamp and local receive timestamp remain separate.
  - Bid/ask validation and explicit injected freshness policy.
  - Stale, future-dated, invalid-clock, and invalid-policy states block automated decisions.
- services/api/src/server.ts and main.ts
  - Loopback-only routes for DEMO connection status, connect/disconnect, instrument search, and historical prices.
  - Market-data responses identify Capital.com and DEMO.
- Tests:
  - market-data.test.mjs
  - market-data-runtime.test.mjs
  - market-data-runtime-lifecycle.test.mjs
- services/api/README.md documents local setup and market-data routes.
- docs/architecture/CAPITAL_COM_DEMO_AND_MARKET_DATA_FOUNDATION.md records the provider and safety boundary.

## Verification state

- Earlier exact source checkpoint f5a388dbe5b91df7b4cad086ba3504ed7e928bf3: hosted backend typecheck and tests passed, but the later runtime-lifecycle tests were not yet included.
- Exact PR head at the time of this record must be re-read from GitHub before qualification. Do not reuse results from earlier commits as proof for a later head.
- Local Sync Safety checks passed on preceding commits.
- Current exact-head CI, Intel/Apple Silicon macOS build/XCTest, and owner-side app runtime QA are not yet qualified.
- Mocked tests do not prove Capital.com credentials, network access, or a real DEMO session.
- No owner credentials were supplied to this workstream; no real provider authentication has been attempted.

## Explicit gaps / next actions

1. Revalidate exact PR #25 head and wait for exact-head repository, backend, Intel, Apple Silicon, and Local Sync checks.
2. Resolve official Capital.com DEMO WebSocket endpoint with the provider before implementation/qualification.
3. Implement authenticated DEMO streaming, subscription bounds, ping, disconnect detection, reconnect/resubscribe, and recovery.
4. Define authoritative freshness thresholds from approved specification; do not silently adopt historical thresholds.
5. Add integration qualification using owner-provided DEMO credentials in a secure local secret store/environment. Never send credentials through chat or commit them.
6. Only after real streaming evidence, bind Market Watch and Chart Workspace to the normalized provider feed. Until then, both remain explicitly unavailable.
7. Continue Account / Positions / Orders only after broker-authoritative data contracts; keep all dealing methods absent and trading disabled.

## Safety

- CAP_ALLOW_TRADING=false remains unchanged.
- No LIVE endpoint, dealing method, order route, or trading permission was introduced.
- No synthetic market/account data was added.
- No credentials or session tokens were committed or returned to the macOS client.
