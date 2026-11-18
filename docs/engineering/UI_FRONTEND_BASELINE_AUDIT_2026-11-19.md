# Team A — UI / Frontend Engineering Baseline Audit

**Audit ID:** ATP-UI-BASELINE-001  
**Date:** 2026-11-19  
**Repository:** `atheertrading/atheer-trading-platform`  
**Canonical branch baseline:** `main` — `31e3e5547c9204645427ec56426e741d4bcfa955`  
**UI implementation snapshot reviewed:** PR #90 head `c0f386c1e7701f6445d1e70eea6ee87545c7e954`, extended by PR #91 head `b70c528d3654d9ab2af704f951b4cadcfc18b873`  
**Governing instructions:** `AGENTS.md` (blob `0f4ed8d0c3d7eb69785886da4e0d2f3b25e8bad4`), Issues #72, #77 and #79, TEAM A assignment ATP-TEAM-A-001.

## 1. Executive result

The repository contains a functioning native macOS application foundation and several real read-only workflows. It is not yet the complete 12-area trading workstation. The current UI stack has four actual navigation destinations: Command Center, Markets, API Connection and Settings. The remaining product areas are either not implemented in that stack or are being developed on separate unmerged chart/data branches.

The main-branch baseline remains the older commit above. The current native shell and measured 12-screen design package are proposed on a chain of open Draft PRs; they are not part of `main`. The Team A implementation branch for this increment is a child of PR #90. It has not been merged.

The most immediate verified UI defect was that the Command Center displayed static market-data and broker labels despite existing backend status contracts. PR #91 adds a typed, read-only projection of those contracts and preserves unknown/unavailable states. The separate live Market Watch/chart stack must still be reconciled before any shared-file integration.

## 2. Repository and active branch baseline

### Main and UI branch ancestry

| PR | Purpose | Head SHA | Base | State at audit |
|---:|---|---|---|---|
| #69 | IPDS semantic theme / appearance foundation | `fa195a6e0617091322b7934564db0e681cd9d58d` | `main` | Open, Draft |
| #80 | Persistent operational status strip | `9fd6e3aaa6af82eba55e01c512200cee6956bd01` | #69 branch | Open, Draft |
| #85 | Keyboard-accessible instrument quick search | `326214b20dd2bdebd8d7e171bf8cf6aafbe12922` | #80 branch | Open, Draft |
| #89 | Native application shell | `7c756390240a05c5570d5e2c200c20c3b2e917e3` | #85 branch | Open, Draft |
| #90 | Measured 12-screen IPDS design package | `c0f386c1e7701f6445d1e70eea6ee87545c7e954` | #89 branch | Open, Draft |
| #91 | Command Center backend-status integration | `b70c528d3654d9ab2af704f951b4cadcfc18b873` | #90 branch | Open, Draft |

PR #73 is a separate screen-blueprint documentation branch based on the PR #69 foundation. It is not the parent of the shell chain above.

### Parallel chart and market-data ancestry

| PR | Purpose | Head SHA | Base | State at audit |
|---:|---|---|---|---|
| #70 | Authenticated historical candlestick workspace | `031c88e73d7a172601138aea8904371a0f630a02` | Historical market-data branch at `96df364562b3af4a123f41b440ad0c7f525a6566` | Open, Draft |
| #83 | Persistent DEMO quote monitor in Command Center | `abf87d40c866a2b6ef7efffbd1b8d7186165f095` | #70 branch | Open, Draft |

PR #83 modifies `CommandCenterView.swift`, `ContentView.swift` and `WorkspaceHomeView.swift`, which are also changed by PR #91. PR #70 changes those same shared application files as well. Older alternative branches #43 and #44 also overlap the Command Center / charting surface. These branches must not be merged independently or assumed to be compatible. A deliberate, history-preserving integration sequence and source-level conflict review are required.

## 3. Actual application screen inventory

The native app's `AppSection` has four real destinations. The 12 SVGs in PR #90 are design-review assets; they do not create application routes or complete screens.

| Product area | Current implementation on the UI stack | Verified boundary / gap |
|---|---|---|
| Command Center | Native `CommandCenterView`; persistent workspace panels; backend health; backend-derived status cards in PR #91 | Chart, Market Watch quote feed and account panels do not become live just because the screen exists. Live quote monitor is on separate PR #83. |
| Markets | `MarketExplorerView`, typed `MarketExplorerViewModel`, provider-backed REST instrument search | Results are instrument metadata, not streaming quotes or authenticated candles. |
| Charts & Analysis | No Charts navigation destination in the current UI stack; PR #90 contains a design composition | Historical/chart implementation is on separate PR #70 / related chart stack and is not integrated into this UI ancestry. |
| Trading & Execution | No order-entry workflow in the current UI stack | No UI dealing call is permitted; governed backend authorization and execution remain mandatory. |
| Positions | No position monitor/read model in this UI stack | No verified account-position contract is consumed here. |
| Orders | No order lifecycle/read model in this UI stack | No OMS order-state contract is consumed here. |
| Risk Management | Account/risk panel presents unavailable values, not a RiskEngine workflow | UI cannot authorize or override RiskEngine. |
| Portfolio & Performance | Not implemented as a native destination | Requires verified account and portfolio read models. |
| Strategy Center | Not implemented as a native destination | No strategy lifecycle/backtest API contract is consumed by this UI stack. |
| Automated Trading | Not implemented as a native destination | Agent status, authorization, intent and execution must remain separate concepts. |
| Intelligence & Research / Mind OS | Not implemented as a native destination | AI output cannot bypass RiskEngine or governed execution. |
| System & Administration | Partial coverage through Settings, Broker Management and API Connection | These are separate existing destinations; a complete administration/diagnostics workspace is not present. |

Current `AppSection` source confirms only `workspace`, `markets`, `apiConnection` and `settings`. The implementation must not expose placeholder routes as completed destinations.

## 4. Design system and visual foundation

Verified implementation:
- `ATHEERDesignTokens.swift` provides semantic color and typography roles used by native views.
- `ATHEERAppearance.swift` resolves Dark / Light appearance with Dark as the fallback; the appearance preference is persisted and exposed in Settings.
- PR #89 replaces the stock navigation presentation with a custom native macOS shell and applies shared viewport metrics.
- PR #90 adds `IPDSViewportMetrics.swift`, a shared 1440 × 900 pt / 2880 × 1800 px 2× design specification and 12 independent SVG compositions.

Not complete / not approved by this audit:
- The 12 SVG files are design-review compositions, not production SwiftUI screens.
- Owner / Design Authority approval of the visual package remains a separate gate.
- Canonical turquoise remains unresolved between the historical `#40E0D0` and existing source `#00CEC8`; current source values were not silently changed.
- Light-appearance screen coverage, Arabic localization, true RTL layout, bidirectional financial text and locale-specific formatting are not product-wide qualified.
- Native screenshot comparison, contrast measurements, focus/keyboard, VoiceOver and minimum-window visual QA remain pending.

## 5. Workspace and panel architecture

Verified source in `WorkspaceEngine.swift`:
- Versioned Codable workspace snapshot (schema v1) with profiles, workspaces, panel configurations and layout settings.
- `UserDefaultsWorkspacePersistence` behind a `WorkspacePersistence` protocol.
- Workspace/profile creation and selection, active workspace renaming/reset, panel visibility, ordering, add/remove, default restoration and sidebar width resizing with bounded values.
- Snapshot validation, duplicate identity/order rejection and recovery from corrupt or unsupported persisted data.

Current boundaries:
- The present panel catalogue contains Market Watch, Charts, Account & Risk and Platform Health.
- The current width control is a Command Center sidebar width; this is not a general docking/grid-resize engine.
- The audited engine exposes workspace/profile creation and selection but no general workspace deletion operation.
- Native multi-window lifecycle, detached/full-screen panels, arbitrary panel resizing/drag docking and multi-display restoration are not established by this source snapshot.
- Panel visibility/configuration remains separate from backend service lifecycle; hiding a panel must not stop a broker or market-data session.

## 6. ViewModel and client architecture

The audited source has typed presentation and infrastructure boundaries:
- `BackendHealthViewModel` with `BackendHealthClient`, `URLSessionBackendHealthClient` and a decoder separating process liveness from platform readiness.
- `BrokerManagementViewModel` and broker-management services for the current Settings workflow.
- `MarketExplorerViewModel` with the `MarketSearchClient` application port, provider DTO decoding and `URLSessionMarketSearchClient`.
- `URLSessionRequestExecutor` shared by native HTTP clients.
- `OperationalStatusPresentation` maps backend readiness into local API, platform and trading-gate presentation without treating liveness as readiness.
- PR #91 adds `CommandCenterStatusViewModel` using the existing `MarketSearchClient.fetchBackendStatus()` contract and a pure status projection.

The new Command Center presentation deliberately:
- identifies the market-data response as Capital.com DEMO REST-session status; it does not claim a WebSocket stream or live quote;
- derives broker and trading-gate labels only from backend readiness fields, preserving UNKNOWN / NOT VERIFIED when no usable field exists;
- leaves Account as `NO SNAPSHOT` because the current UI health contract has no account snapshot;
- does not create a new endpoint, authenticate the broker or call a dealing route.

## 7. Test and qualification baseline

- The current PR #91 source snapshot contains 57 XCTest methods in `ATHEERTradingProTests.swift`; PR #91 adds four Command Center status tests. Count is source inventory only, not proof that tests passed.
- PR #91 exact head `b70c528d3654d9ab2af704f951b4cadcfc18b873`: Local Sync Safety run #2200 passed; Backend Toolchain and Repository Hygiene jobs passed. Intel macOS build / XCTest / CodeQL was in progress at XcodeGen installation, and Apple Silicon was queued at the last inspection. No complete exact-head macOS pass is claimed in this audit.
- PR #90 exact head had successful Debug build and XCTest steps on Intel in its reviewed run; Release remained in progress and Apple Silicon was cancelled. It was therefore not fully qualified at the time of review.
- PR #70 and #83 CI summary runs were marked failed because their macOS jobs and the backend test step were cancelled; this is incomplete qualification, not evidence of a source compile failure. Their Local Sync Safety / diagram or repository-hygiene results were separate and do not substitute for macOS/XCTest passes.
- Owner-Mac build/launch, runtime inspection, screen captures, authenticated DEMO acceptance, VoiceOver, keyboard focus, Light, Arabic RTL and multi-display checks remain unverified.

## 8. Verified gaps and priority order

1. Finish exact-head qualification and reconcile the #69 → #80 → #85 → #89 → #90 → #91 UI chain without bypassing branch protection.
2. Integrate the persistent Market Watch / historical chart stack only after reconciling PR #70 / #83 shared source files and upstream broker/data dependencies.
3. Complete the Command Center with verified persistent market watch and actual platform/account/risk contracts; keep unavailable account/risk values explicit until Team B publishes the contracts.
4. Deliver a native Charts & Analysis route using the qualified historical and live-candle capabilities; verify timestamps, Bid/Ask separation, stale/gap state and source provenance.
5. Deliver Orders, Positions, Risk and Trading presentation only after matching backend read models, RiskEngine, OMS, authorization and reconciliation contracts are available.
6. Deliver remaining Portfolio, Strategy, Automated Trading, Mind OS and Administration destinations against approved contracts rather than placeholders.
7. Complete native accessibility, Light, Arabic RTL, responsive/minimum-window, workspace persistence, multi-window and multi-display qualification.

Issue #72 remains the UI delivery tracker and records an 85–140 engineer-day UI planning estimate. This audit does not reduce that estimate and does not count design-only SVGs as completed screen implementations.

## 9. Safety and governance

- Manual, automated and AI-generated trading intents must remain on the governed backend execution path.
- No SwiftUI view may call broker dealing APIs directly.
- Backend and account values must not be synthesized for visual completeness.
- DEMO, SIMULATION, BACKTEST and LIVE remain distinct execution/data environments.
- Keep `CAP_ALLOW_TRADING=false` until the specified backend, reconciliation, risk and owner authorization gates are satisfied.
- No credentials, repository secrets, broker account permissions, production settings or LIVE trading were accessed or changed by this audit.
- PR #91 remains Draft and stacked on PR #90. Merge authority is not permission to skip exact-head tests, integration dependencies, review or repository protections.
