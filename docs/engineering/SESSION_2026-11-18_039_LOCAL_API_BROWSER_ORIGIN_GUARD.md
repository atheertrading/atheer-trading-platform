# ATP-2026-11-18-039 — Local API Browser-Origin Guard

**Date:** 2026-11-18  
**Repository:** `atheertrading/atheer-trading-platform`  
**Branch:** `feat/capital-demo-market-streaming-qualified`  
**PR:** #37  
**Task:** ATP-SEC-001A

## Finding

The API already binds only to `127.0.0.1`, but the `/market-data/*` routes had no browser-origin or CSRF guard. A web page could attempt to trigger local connect/disconnect or stream requests. Same-origin policy would restrict reading responses, but simple requests could still cause side effects.

## Implementation

- Require `X-ATHEER-LOCAL-CLIENT: macOS` on every `/market-data/*` route.
- Reject any request carrying an `Origin` header.
- Reject `Sec-Fetch-Site` values other than absent or `none`.
- Preserve loopback-only HOST validation.
- Update native Market Search GET requests to send the marker.
- Update SSE integration test to send the marker.
- Add API tests for missing marker, cross-origin Origin, cross-site Fetch Metadata, and accepted native requests.

## Security limitation

The marker is not a secret and does not authenticate arbitrary local processes. It mitigates browser CSRF/cross-origin access only. Production packaging must introduce a per-launch capability token or authenticated local IPC before broker/session controls are exposed beyond this development boundary.

## Commit trail

- `8b409ce17b81ee0ff9fe06bbc688c05755ea219d` — `SECURITY.md`
- `e10b410f5e55fa86285bfaf054b6b7783d2d164f` — `docs/architecture/ATHEER_MARKET_DATA_STREAMING_ARCHITECTURE.md`
- `aaa715d39e760906dd40e07cbbba23b4fbbfb476` — `docs/engineering/TASK_REGISTER.md`
- `d233694b218305d8b509f1ebf9ead7fa5420e957` — `docs/engineering/IMPLEMENTATION_STATUS.md`
- `37266a2593cd9ac02968271ee49af32117ba9a67` — `docs/engineering/ENGINEERING_DECISION_LOG.md`
- `9d57c91711a5d73d1d9877a264b61512f64367f2` — `docs/engineering/PROJECT_CONTINUITY.md`
- `1b640a33cc9532fdc711cabc1645e2e5263cc884` — `docs/engineering/CONVERSATION_INDEX.md`

## Verification

Exact-head hosted CI is pending. No live broker session or credentials were used. No dealing or LIVE capability was added.


## Catalogue / quote authority extension

- `CapitalDemoClient.getMarkets` now allow-lists only epic, instrument name, market status and currency.
- Unvalidated provider `bid`/`offer` fields are stripped from catalogue responses; only normalized streaming events can supply live Bid/Ask.
- Added a regression test proving catalogue bid/offer values are not exposed.
- Added ATP-MKT-006I and EDL-021.
