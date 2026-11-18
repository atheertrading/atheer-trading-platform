# Session 059 — Authenticated Historical Chart Workspace

**Date:** 2026-11-18  
**Workstream:** ATP-CHART-001  
**Branch:** `feat/authenticated-chart-workspace-2026-11-18`  
**Base:** PR #68 branch `feat/authenticated-historical-market-data-2026-11-18`

## Objective

Port the historical chart workspace from the stale PR #43/#44 feature stack into the active authenticated broker/data stack. The macOS client must use the supervised dynamic backend connection and private IPC capability; the previous static-port, unauthenticated history client is not compatible with the current API.

## Implementation

1. Added `MarketHistoryClient` and `URLSessionMarketHistoryClient` using the dynamic `BackendIPCConnection` base URL, bearer IPC capability, `X-ATHEER-LOCAL-CLIENT: macOS`, ephemeral URLSession, disabled cookies/cache, and a 15-second client timeout that exceeds the backend provider request budget.
2. Added strict response decoding for provider/environment, instrument, resolution, Bid/Ask OHLC, timestamp/receipt lineage, raw provider record count, duplicate count, and pagination consistency.
3. Added a `MarketChartViewModel` with request-generation protection, cancellation semantics, explicit unavailable/error states, and receipt-time provenance.
4. Added a Swift Charts candlestick surface with timeframe selection, Bid/Ask selection, manual refresh, duplicate/gap metadata and a visible provider-limit warning.
5. Added a dedicated Charts navigation destination and an Open Chart action from Market Explorer instrument results.
6. Replaced the Command Center chart placeholder with the authenticated historical chart surface when the backend client is available; otherwise it shows an explicit backend-unavailable state.
7. Added decoder, request-builder, view-model and cancellation tests; added Mermaid diagram 11 and architecture documentation.

## Authentication and integrity

- No hard-coded backend port; requests use the supervised `BackendIPCConnection`.
- The private IPC bearer capability and native-client context are mandatory.
- Provider session tokens and credentials remain backend-owned.
- Bid and Ask candles remain separate; no synthetic midpoint.
- Raw provider count is validated before deduplication and is used to validate `pagination.limitReached`.
- Conflicting or malformed candles fail closed.
- Request cancellation is not reported as a provider failure.
- The chart is historical DEMO and read-only; it has no path to RiskEngine, OMS or Execution Gateway.

## Scope boundaries

Not implemented in this increment:
- Persistent Market Watch/watchlist.
- Live candle aggregation or live OHLC updates.
- Technical indicators, drawing tools, replay, alerts or multi-chart layouts.
- User-selectable historical date ranges in the macOS chart controls (the backend endpoint already supports strict UTC bounds).
- Any trading or order execution.

The chart is not a live quote monitor and must not be treated as an executable signal source.

## Files

- `apps/macos/ATHEERTradingPro/Sources/Services/MarketHistoryClient.swift`
- `apps/macos/ATHEERTradingPro/Sources/MarketChartViewModel.swift`
- `apps/macos/ATHEERTradingPro/Sources/MarketChartView.swift`
- `apps/macos/ATHEERTradingPro/Sources/Services/BackendRuntimeViewModel.swift`
- `apps/macos/ATHEERTradingPro/Sources/AppSection.swift`
- `apps/macos/ATHEERTradingPro/Sources/MarketExplorerView.swift`
- `apps/macos/ATHEERTradingPro/Sources/ContentView.swift`
- `apps/macos/ATHEERTradingPro/Sources/WorkspaceHomeView.swift`
- `apps/macos/ATHEERTradingPro/Sources/CommandCenterView.swift`
- `apps/macos/ATHEERTradingPro/Tests/MarketChartTests.swift`
- `docs/architecture/ATP_AUTHENTICATED_HISTORICAL_CHART_WORKSPACE.md`
- `docs/architecture/diagrams/11-authenticated-historical-chart-workspace.mmd`

## Verification status

- Source and test changes committed on the PR #70 branch.
- Hosted exact-head macOS CI and all dependent PR checks are pending.
- No local Xcode build, owner-Mac pull, provider DEMO authentication, or live historical response is claimed.
- The prior local Mac record from 2026-11-17 is historical evidence only and does not qualify this branch.

## Dependency and CI note

PR #66's previous CI run exposed a compile error in the MarketSearch test fixture: the new `BackendIPCConnection` initializer required `credentialSocketURL`. The fixture was corrected on the updated PR #66 head and the same test-only correction was propagated to descendant branches so their exact-head checks include it. The previous PR #66 run remains failed; the updated exact-head rerun and Apple Silicon qualification are pending.

PR #70 is stacked on PR #68, which is stacked on PR #67. The older PR #43/#44 chart branch remains open but is not merge-ready: its original client used a static backend port and omitted the private IPC bearer capability, which would fail against the current API.

## Safety

No broker credentials, provider DEMO session, order placement, risk-policy change or LIVE execution was used. `CAP_ALLOW_TRADING=false` remains unchanged.


## Follow-up review remediation — 2026-11-18

A source-level integration review found that `WorkspaceHomeView` and `CommandCenterView` declared injected dependencies as immutable stored properties with default values. Their call sites supplied those dependencies through synthesized memberwise initializers, which do not expose initialized immutable properties as parameters. Added explicit initializers that accept and assign the backend health model, authenticated history client, selected instrument, and navigation closures.

- `WorkspaceHomeView.swift`: commit `bd12cc67526c71550b31737763b3e05e012da8e3`.
- `CommandCenterView.swift`: commit `484907de2f308231dac89d5e151beee6e95c250a`.
- PR #70 exact head after remediation: `484907de2f308231dac89d5e151beee6e95c250a`.
- Hosted CI was triggered for this exact head; compilation and XCTest results remain pending.
- PR #71 was closed as redundant, preserving its branch and history. Its only test-fixture change is already byte-for-byte present on PR #70 (blob `c1930bbb87d4ba66898f85ed90faed6c4a4efe56`); PR #70 remains based on the PR #68 head.

## Follow-up data-integrity hardening — 2026-11-18

The native historical payload decoder now independently rejects candles whose market timestamp is later than the candle's receipt timestamp. Added a regression test using a deliberately future-dated payload. This duplicates the backend guard at the client trust boundary rather than relying solely on server normalization.

- Native client: `apps/macos/ATHEERTradingPro/Sources/Services/MarketHistoryClient.swift`.
- XCTest: `apps/macos/ATHEERTradingPro/Tests/MarketChartTests.swift`.
- Commits: `68b70ed2404b4672a86dbb91e05b0157da311391`, `b130e4375444deb9c029299fc6564168d51a636d`.
- Exact-head macOS CI and dependent backend checks are required; no build or test pass is claimed.
- The chart remains historical DEMO/read-only. No execution path was added.

## CI failure analysis and regression correction — 2026-11-18

The inherited Intel macOS test run identified a stale error-description assertion in `UnixDomainSocketBrokerCredentialIPCClientTests`. Production returns the security-specific text "The private broker credential request was rejected (...)." The test expected the older text without "private". Updated the assertion to match the actual contract.

The inherited broker authentication URLProtocol fixture also assumed request bodies were always available through `URLRequest.httpBody`. The macOS runner surfaced the body via `httpBodyStream`; the fixture now captures either representation, uses a bounded stream read, and enforces the existing 8 KiB request limit.

- Corrections propagated through PR #66, #67, #68 and #70.
- No production broker transport or execution behavior was changed by these test fixes.
- Exact-head CI reruns are pending; no test pass is claimed.
