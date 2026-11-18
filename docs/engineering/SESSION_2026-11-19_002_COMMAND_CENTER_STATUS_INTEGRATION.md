# Engineering Session 2026-11-19 — Command Center Backend Status Integration

**Work package:** ATP-UI-CC-STATUS-001  
**Team:** A — UI / Frontend Engineering  
**Branch:** `feat/ui-command-center-status-integration`  
**Base:** PR #90 exact head `c0f386c1e7701f6445d1e70eea6ee87545c7e954`  
**Tracking:** Issue #72; integration boundaries in #77 and #79

## Objective

Replace static Command Center operational labels with a deterministic presentation of existing backend status contracts. Reuse the authenticated market-data status client and backend health/readiness model; do not add or infer endpoints.

## Source findings

- The Command Center previously rendered fixed values such as `Provider not configured` and `BROKER DISCONNECTED`.
- The native client already exposes `MarketSearchClient.fetchBackendStatus()`, backed by the existing market-data status route and strict Capital.com / DEMO response decoding.
- `BackendHealthSnapshot` already carries readiness-derived broker and trading-gate fields. `OperationalStatusPresentation` already fails closed when readiness or the trading field is unavailable.
- The current health contract does not expose an account snapshot, so the Account card remains explicitly `NO SNAPSHOT`.
- The market-data status is a REST-session state only. It does not prove an active WebSocket stream, current quotes, or chart data.

## Implementation scope

- Added an injected `CommandCenterStatusViewModel` using the existing `MarketSearchClient` port.
- Replaced hardcoded market-data and broker claims with backend-derived status cards.
- Reused the existing backend readiness presentation for execution-gate state; no trading or dealing control is added.
- Preserved an unavailable account state rather than synthesizing financial values.
- Shared one `URLSessionMarketSearchClient` instance across Command Center, Markets, and instrument quick search at the application composition point.
- Added deterministic XCTest coverage for REST/streaming separation, unavailable backend state, readiness-derived broker/trading status, and unknown broker-state handling.

## Files changed

- `apps/macos/ATHEERTradingPro/Sources/CommandCenterStatusViewModel.swift` (new)
- `apps/macos/ATHEERTradingPro/Sources/CommandCenterView.swift`
- `apps/macos/ATHEERTradingPro/Sources/ContentView.swift`
- `apps/macos/ATHEERTradingPro/Sources/WorkspaceHomeView.swift`
- `apps/macos/ATHEERTradingPro/Tests/ATHEERTradingProTests.swift`
- Engineering continuity, implementation status, task register, and conversation index.

## Safety and ownership

- No backend source or API contract was modified.
- No broker credential or session lifecycle was changed.
- No account, balance, position, P&L, quote, order or execution value is fabricated.
- No broker-dealing endpoint is called by the UI.
- `CAP_ALLOW_TRADING=false` remains unchanged. No LIVE, production, account-permission or risk-limit action is authorized.

## Verification

- Source review and deterministic test cases added.
- Exact-head hosted CI, owner-Mac build/launch, authenticated DEMO status, visual QA, VoiceOver, keyboard, Light appearance and Arabic RTL remain pending until independently evidenced.
