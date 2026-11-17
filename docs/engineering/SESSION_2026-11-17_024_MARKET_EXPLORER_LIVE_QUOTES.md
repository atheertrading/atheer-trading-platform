# Session 2026-11-17 — Market Explorer Live Quote Integration

**Work package:** ATP-MKT-004  
**Branch:** `feat/macos-market-explorer-live-quotes`  
**Base:** PR #34 exact head at branch creation `1378cc9d78151dc58bc548887ff5a3c45594d62b`  
**Status:** IMPLEMENTED IN SOURCE AND TESTS — HOSTED VERIFICATION PENDING

## Scope

Connect the existing native Market Explorer to the backend DEMO SSE quote stream. No new screen or navigation destination is added.

## Implementation

- Added `MarketDataStreamClient` and `URLSessionMarketDataStreamClient` using `URLSession.bytes(for:)` and a line-oriented SSE parser.
- Decode and validate provider DEMO status and quote events; reject malformed, non-DEMO, non-finite, crossed, or untimestamped quote payloads.
- Added explicit instrument selection and a maximum 40-instrument selection limit.
- Streaming requires an explicit Start action; selection alone does not open a provider connection. Stop and Clear Selection actions are available.
- The existing Market Explorer now displays Bid, Ask, provider timestamp, quote age, and ingestion-time quality state only after a real timestamped stream event arrives.
- Displayed values are sourced from the provider quote stream; no synthetic or search-response prices are used.
- The app retries a failed SSE transport with bounded exponential delay while the user-requested stream remains active.
- The SSE route now sends status only after provider subscription succeeds and publishes status snapshots every five seconds.
- The view cancels its SSE task when it disappears and resumes only when streaming had been explicitly requested.

## Files changed

- `apps/macos/ATHEERTradingPro/Sources/Services/MarketDataStreamClient.swift`
- `apps/macos/ATHEERTradingPro/Sources/Services/MarketSearchClient.swift`
- `apps/macos/ATHEERTradingPro/Sources/MarketExplorerView.swift`
- `apps/macos/ATHEERTradingPro/Tests/ATHEERTradingProTests.swift`
- `services/api/src/server.ts`
- `docs/architecture/ATHEER_MARKET_DATA_STREAMING_ARCHITECTURE.md`
- `docs/architecture/diagrams/09-capital-demo-market-data-streaming.mmd`

## Tests added

- SSE parser decodes provider status and quote events.
- Market Explorer does not start a stream from selection alone.
- Explicit Start opens a stream for the selected epic and updates quote state.
- The 40-instrument selection ceiling is enforced.

## Verification

- Hosted macOS Intel and Apple Silicon build/XCTest/Release/Swift CodeQL have not yet run for this branch.
- No local Xcode build or owner-Mac runtime, visual, keyboard/focus, or VoiceOver test was performed.
- No real Capital.com DEMO authentication or quote receipt is claimed.
- No actual quote values are hardcoded or fabricated.

## Safety

- DEMO only; provider tokens remain server-side.
- The stream UI is read-only; no order or dealing action is exposed.
- The ingestion-time freshness flag is displayed as arrival-time quality only and is not an execution permission.
- No quote event is wired into RiskEngine, OMS, or Execution Gateway.
- `CAP_ALLOW_TRADING=false` remains unchanged.
- No LIVE behavior or broker permission changed.

## Next acceptance gates

1. Exact-head macOS Intel and Apple Silicon builds, XCTest, Release, and Swift CodeQL.
2. Inspect compiler warnings, especially strict-concurrency diagnostics.
3. Owner-Mac visual, navigation, keyboard/focus, VoiceOver, and SSE disconnect/reconnect QA.
4. Verify actual Capital.com DEMO authentication and real provider quote timestamps when credentials are available.
5. Implement historical candle normalization, pagination, persistence, gap recovery, and source lineage.
6. Add OHLC streaming and Charting only after historical/live candle contracts are stable.
7. Integrate data-quality assessment with RiskEngine only as a separately reviewed, fail-closed increment.

## Qualification remediation — 2026-11-17

Code review identified and corrected three lifecycle/contract issues before qualification:

- Default URLSession search and stream clients are now constructed inside the MainActor-isolated view-model initializer; the view initializer accepts optional injected dependencies to avoid Swift 5.8 default-argument isolation errors.
- Instrument epics are validated against the backend-compatible [A-Za-z0-9_.-]{1,64} contract before selection.
- Clearing the final selected epic now cancels both the SSE task and the 100 ms presentation throttle; the throttle cannot continue running after the stream becomes ineligible.
- UI column labels are DEMO BID / DEMO ASK, not LIVE BID / LIVE ASK.

Added XCTest coverage for invalid epic rejection and presentation-throttle cleanup. The 100 ms coalescing cadence is presentation-only and does not affect backend ingestion, quote ordering, freshness evaluation, or execution authorization.

Hosted exact-head requalification remains pending. No local Xcode, owner-Mac runtime, real provider authentication, or real quote receipt is claimed.
