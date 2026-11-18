# ATP-2026-11-18-037 — Market Explorer Boundary Separation

**Date:** 2026-11-18  
**Repository:** `atheertrading/atheer-trading-platform`  
**Branch:** `fix/market-explorer-search-lifecycle`  
**PR:** #33  
**Work package:** ATP-UI-ARCH-001A

## Review finding

PR #33's original Market Explorer placed provider Decodable models, HTTP adapter, and presentation ViewModel in one source file. The ViewModel also constructed the concrete production HTTP client, and the SwiftUI view consumed the provider response model directly.

This was functional but did not satisfy the intended dependency-inversion and presentation-boundary architecture.

## Implementation

- Added `MarketSearchModels.swift` with provider-independent `MarketInstrumentSummary`, `MarketDataBackendStatus`, connection state and application error types.
- Kept provider JSON response DTOs private to `MarketSearchClient.swift`.
- Added explicit DTO-to-semantic-model mapping in `MarketSearchPayloadDecoder`.
- Moved `MarketExplorerViewModel` to `MarketExplorerViewModel.swift`.
- Removed the ViewModel's default concrete client construction; it now requires `MarketSearchClient`.
- Updated `MarketExplorerView` to consume semantic models.
- Updated `ContentView` to select `URLSessionMarketSearchClient` at the application composition root and inject it.
- Added regression coverage for unknown backend connection states and migrated existing provider-mapping and search lifecycle tests to semantic models.

## Preserved invariants

- Capital.com DEMO provider/environment validation remains mandatory.
- Search input remains bounded to 1–100 characters.
- Search remains gated on a connected backend DEMO session.
- Out-of-order search results remain suppressed by generation checks.
- Instrument search results remain metadata only; no bid/ask, streaming or dealing capability was added.

## Commit trail

- `448fc017d8729fe047a6437f0f9c77bb81b53063` — isolate provider DTO mapping in adapter.
- `a4ea2355a7865eec3284605e0a1a4097ef954ded` — define semantic market models.
- `e3cf9c04bb27bd7c3311ce04825a99688514afd5` — split ViewModel.
- `65b53535304117aff11f71aa7f83bd89c5636c43` — update SwiftUI semantic model consumption.
- `4b19bc34fbb7599f42673303a08b4a7ab53e6001` — inject adapter from ContentView composition root.
- `82d67fde50d56bad020e51d455b653e6901c6237` — update XCTest coverage.
- `be90875e2454b059578b286da3bd0aba3332a80a` — `docs/engineering/TASK_REGISTER.md`
- `8597b812429b800b2cb1693576dc2af21b72723b` — `docs/engineering/IMPLEMENTATION_STATUS.md`
- `cc54519dce86c1f95c4a5dce6765237ea9baa5fb` — `docs/engineering/ENGINEERING_DECISION_LOG.md`
- `483e156cb68a74d50f67f358a7f983cd31c84f9c` — `docs/engineering/PROJECT_CONTINUITY.md`
- `5d2da432b9788c55a87abdb0795866a5d6a53503` — `docs/engineering/CONVERSATION_INDEX.md`

## Dependency and verification

- Parent PR #26 current head: `69b15098e879be362926df1630c58cb3f1cd62fd`.
- Comparison of PR #26 current head to PR #33 pre-refactor head `32a8cb90112011dcc07c149410cea432656a0a92`: 41 commits ahead / 0 behind; parent history is present.
- Refactored PR #33 exact-head hosted CI is pending.
- No local Mac/Xcode execution or visual/accessibility acceptance is claimed.

## Safety

Read-only instrument metadata only. No credentials, session tokens, orders, positions, RiskEngine/OMS/Execution Gateway, broker dealing, or LIVE capability added.
