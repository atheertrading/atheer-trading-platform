# Engineering Session 069 — Backend HTTP Boundary, OpenAPI Contract, and Reconnect Recovery

**Date:** 2026-11-18  
**Assignment:** ATP-TEAM-B-001  
**Workstream:** Team B — Backend Engineering  
**Work packages:** ATP-BRK-002 / ATP-MKT-002 / ATP-API-001  
**Repository:** `atheertrading/atheer-trading-platform`  
**Branch:** `fix/broker-credential-unix-domain-ipc`  
**Pull request:** #66 — private Unix-domain broker credential IPC and managed DEMO session stack  
**Exact PR head at report creation:** `7e5c8b3df80083af0df12c85b723940acb3aa4a7`

## Objective

Continue the secure managed-backend integration by closing the current HTTP contract gaps, improving reconnect behavior, and recording the actual local API surface without inventing future trading endpoints.

## Implemented in this batch

### HTTP market-data validation and availability semantics

Updated `services/api/src/server.ts`:

- Normalize and validate `searchTerm` at the HTTP boundary (1–100 characters after trimming).
- Validate a trimmed Capital.com EPIC against `^[A-Za-z0-9_.-]{1,64}$` before provider invocation.
- Validate historical resolution against the explicit supported enum.
- Validate `max` as a decimal integer and safe integer in the inclusive range 1–1000.
- Return stable HTTP 400 error codes for invalid query parameters before any provider call.
- Return HTTP 503 `broker_session_unavailable` when a syntactically valid search/history request cannot be served because the backend broker session is not configured, disconnected, connecting, degraded, or in error.
- Preserve HTTP 404 for unimplemented routes and HTTP 405 plus `Allow: GET` for wrong methods, independent of broker-session readiness.
- Preserve the rule that broker-sensitive HTTP routes require the per-process Bearer capability and native request context.

### Readiness accuracy

- `GET /health/ready` remains HTTP 503 and trading remains disabled while persistence is not configured.
- The broker dependency field now reflects the actual backend-owned broker-session state rather than always claiming `not_configured`.
- Readiness does not become healthy merely because Capital.com authentication succeeds; persistence and the complete trading dependencies remain unqualified.

### Reconnect recovery

Updated `services/api/src/market-data/capital-demo-streaming-runtime.ts`:

- Use exponential backoff with full jitter for provider WebSocket reconnection.
- Preserve the 1-second initial cap and 30-second maximum cap.
- Inject the random source for deterministic testing.
- Reset the backoff attempt counter after successful stream connection.
- Do not equate a WebSocket interruption with loss of the independent REST broker session.

### Versioned API contract

Added `services/api/openapi.yaml` as an OpenAPI 3.1 description of implemented routes only:

- `GET /health/live`
- `GET /health/ready`
- `GET /broker-session/status`
- `GET /market-data/status`
- `GET /market-data/markets`
- `GET /market-data/history`
- `GET /market-data/stream`

The contract documents the local loopback boundary, per-process Bearer capability, native-request-context condition, query constraints, provider and DEMO labels, opaque historical records, quote provenance/freshness fields, and SSE event types. It deliberately does not define HTTP credential-submission, order, dealing, position-mutation, or LIVE operations. Credential connect/disconnect remains on the private UDS protocol.

Updated `services/api/README.md` to link the contract and describe its current scope.

### Deterministic regression tests

Added or extended:

- `services/api/test/market-data-runtime.test.mjs`: invalid search/EPIC/resolution/max values are rejected before provider access; valid normalized parameters reach the provider; valid requests return 503 when the session is unavailable; readiness reflects a connected broker while remaining not-ready for persistence; browser-originated request contexts are rejected; 404/405 semantics remain stable.
- `services/api/test/market-data-stream-reconnect.test.mjs`: deterministic exponential full-jitter sequence and maximum-backoff behavior.
- `services/api/test/openapi-contract.test.mjs`: exact route inventory, security extension coverage, query parameters, component-reference integrity, and SSE event contract.

## Changed paths in this batch

- `services/api/src/server.ts`
- `services/api/src/market-data/capital-demo-streaming-runtime.ts`
- `services/api/test/market-data-runtime.test.mjs`
- `services/api/test/market-data-stream-reconnect.test.mjs`
- `services/api/openapi.yaml`
- `services/api/test/openapi-contract.test.mjs`
- `services/api/README.md`

Earlier same-branch backend remediation in Session 068 remains part of PR #66:
- Serialized broker-session transitions.
- Authenticated credential IPC request draining before broker teardown.
- Explicit timed-out shutdown outcomes and sequential bounded teardown.
- Matching deterministic tests.

## Verification evidence

At exact PR head `7e5c8b3df80083af0df12c85b723940acb3aa4a7`:

- GitHub CI run `44412675411`:
  - Backend toolchain: **passed** — Node.js 24.22.3 setup, API type-check and full API test command.
  - Repository Hygiene: **passed**.
  - Intel x86_64 macOS: pending at last inspection.
  - Apple Silicon arm64 macOS: pending at last inspection.
- Local Sync Safety run `44412675385`: **passed**.

The backend result is hosted CI evidence for this exact commit. It does not establish owner-Mac runtime, Keychain behavior, real Capital.com DEMO authentication, real-time broker streaming, native UX acceptance, or full PR qualification. No real broker credentials or live provider session were used by these synthetic regression tests.

## Security and trading boundaries

- Broker credentials remain on private UDS IPC, not HTTP.
- The 256-bit process capability remains separate from broker authentication and account authorization.
- Provider credentials and CST/X-SECURITY-TOKEN are not returned to status responses or logs.
- Market-data routes remain read-only and Capital.com DEMO-only.
- Quote freshness exposed by the current stream is a presentation/data-quality contract; it is not silently substituted for the policy-driven RiskEngine thresholds.
- `CAP_ALLOW_TRADING=false` remains enforced.
- No OMS submission, Execution Gateway, DEMO dealing, LIVE dealing, production deployment, or production qualification is claimed.

## Remaining gates

1. Complete exact-head Intel x86_64 and Apple Silicon arm64 macOS build/test/Swift CodeQL jobs.
2. Recheck all required jobs against the newest PR head after any further shared-branch commits.
3. Review native supervisor shutdown and Swift credential IPC lifecycle with the Head of Engineering; those files belong to the macOS workstream.
4. Reconcile the #51 → #52 → #53/#56 → #55 → #64 → #66 branch stack and its dependency qualification. Do not merge the stacked PR independently.
5. Continue the backend trading-core dependency order only after canonical domain and persistence integration: durable intent journal/outbox → RiskEngine policy/context integration → OMS → one Execution Gateway → controlled DEMO dealing and reconciliation.

## Disposition

The backend HTTP-boundary and local API-contract increment is implemented and the exact-head Backend Toolchain and Repository Hygiene checks passed. The parent PR remains Draft and not merge-qualified while architecture jobs and cross-workstream dependency reconciliation remain incomplete.
