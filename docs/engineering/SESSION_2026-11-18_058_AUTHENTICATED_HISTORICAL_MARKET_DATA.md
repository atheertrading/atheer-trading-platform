# Session 058 — Authenticated Historical DEMO Market Data

**Date:** 2026-11-18  
**Workstream:** ATP-MKT-005  
**Branch:** `feat/authenticated-historical-market-data-2026-11-18`  
**Base:** PR #67 exact head `2b1469263678e69fb87c9e47c6450b87bf821f20`

## Objective

Port the existing historical market-data contract from the stale PR #38/#39 branch stack into the current authenticated broker-session stack without importing the old credential/session implementation or replacing the newer Market Explorer stream integration.

## Implementation

1. Added `historical-prices.ts` with strict UTC date-range conversion, separate Bid/Ask OHLC, timestamp and receipt lineage, positive finite price validation, crossed-side and OHLC validation, duplicate detection, and observed-gap reporting that does not assume a market calendar.
2. Extended `CapitalDemoClient.getPriceHistory` with optional paired UTC `from`/`to` bounds, provider UTC formatting, raw provider record-count validation, and the existing shared REST rate budget.
3. Passed the range through `CapitalDemoRuntime` and the backend-owned `BrokerSessionManager`.
4. Extended the already capability-protected `GET /market-data/history` route to validate epic, resolution, max and UTC range; return normalized candles, request metadata and raw-provider `pagination.limitReached`.
5. Return HTTP 503 when the broker session is not connected, instead of attempting a provider call and reporting a generic gateway error.
6. Added deterministic normalizer, client range, authenticated route, disconnected-session and raw-count-before-deduplication tests.
7. Added the historical-market-data architecture document and Mermaid diagram 10; updated the diagram index.

## Data-integrity rules preserved

- Capital.com DEMO only; no LIVE endpoints or dealing methods.
- Bid and Ask OHLC remain separate; no synthetic mid candles.
- Provider UTC timestamp and local receipt time remain distinct.
- Exact duplicates are removed and counted; conflicting duplicate timestamps fail closed.
- Gaps are observations requiring an authoritative market-session calendar, not assumed missing candles.
- `limitReached` uses the raw provider count before deduplication. No opaque cursor or automatic range partitioning is invented.
- No provider session tokens or credential material are included in the response.
- The endpoint remains behind the private IPC capability and safe native request-context guard.

## Changed source and tests

- `services/api/src/market-data/historical-prices.ts`
- `services/api/src/market-data/capital-demo-client.ts`
- `services/api/src/market-data/capital-demo-runtime.ts`
- `services/api/src/market-data/broker-session-manager.ts`
- `services/api/src/server.ts`
- `services/api/test/historical-prices.test.mjs`
- `services/api/test/market-data.test.mjs`
- `services/api/test/market-data-runtime.test.mjs`
- `docs/architecture/ATHEER_HISTORICAL_MARKET_DATA_ARCHITECTURE.md`
- `docs/architecture/diagrams/10-historical-market-data-normalization.mmd`
- `docs/architecture/diagrams/README.md`

## Commit sequence

- `e1514fe` — add normalized historical candle contract
- `02d4525` — add historical normalizer tests
- `0b6da91` — add strict UTC range support to DEMO history client
- `8ebe382` — pass historical range through broker runtime
- `c06147d` — expose range through broker session manager
- `3333a91` — normalize authenticated historical API responses
- `b4db482` — add authenticated route/pagination tests
- `b9d72fd` — add strict UTC client tests
- `4d3f00b`, `e7b9041` — add and validate historical market-data Mermaid diagram
- `e251c4f`, `559cbb7` — add architecture document and diagram index
- `1407387`, `bd9499c` — enforce and test disconnected broker-session response

## Verification status

- Source and test changes are committed; exact-head hosted backend, repository hygiene, Mermaid and macOS qualification are pending.
- No hosted test pass, owner-Mac build, provider DEMO authentication, or live historical response is claimed.
- The previous local Mac record (2026-11-17) described branch `feat/broker-management-keychain-demo`, commit `0e7f25e`, Xcode 14.3.1 / macOS 13.3 SDK, and 32 unit plus 3 UI tests passing. That is historical evidence only; the local machine's current branch and toolchain state are not accessible from this session. Do not treat it as qualification of this branch.

## Dependency and integration note

PR #68 is stacked on PR #67, which is stacked on PR #66. The older PR #38/#39–#47 chain remains open but is not merge-ready: PR #37 and PR #38 are both non-mergeable, and PR #38's parent branch has diverged (13 commits ahead / 36 behind). The useful historical contract is ported here; the old stack must not be merged wholesale because its Market Explorer files conflict with the authenticated quote-monitor integration.

## Safety

No broker credentials, provider DEMO session, order placement, risk-policy change or LIVE execution was used. Historical data remains read-only and is not wired to RiskEngine or OMS. `CAP_ALLOW_TRADING=false` remains unchanged.

## Follow-up data-integrity hardening — 2026-11-18

A source review identified that historical normalization validated timestamp syntax and receipt lineage but did not reject a provider candle timestamp later than its local receipt time. Added a fail-closed check in `normalizeCandle` and a deterministic regression test. This prevents future-dated provider history from entering normalized history consumers.

- Backend source: `services/api/src/market-data/historical-prices.ts`.
- Backend test: `services/api/test/historical-prices.test.mjs`.
- Commits: `aa425f9af869987367e12c274292bf00733a1559`, `b9f1a719556bc291c4430e7e273f023aa5409eae`.
- Exact-head CI is required; no test pass is claimed here.
- No provider session, broker credentials, orders, or LIVE capability used.
