# ATHEER Trading Pro — Screen Implementation Register

**Snapshot:** 2026-11-18  
**Authority:** ATP-PROMPT-SCREEN-EXEC-001 and the Library's Professional Trading Screens, Workspace Architecture & User Experience directive.  
**Rule:** A navigation destination, panel shell, placeholder, or static visual is not a completed screen. Status reflects integrated behavior and verification evidence.

| Screen ID | Canonical screen | Owning domain | Status | Current behavior / remaining acceptance |
|---|---|---|---|---|
| SCR-CMD-001 | Command Center | Workstation / Platform Operations | IN PROGRESS | Workspace shell and platform health exist; Market Watch is being integrated. Chart, account/portfolio, risk, positions, orders, alerts and execution panels remain incomplete or truthfully unavailable. |
| SCR-MKT-001 | Market Watch | Market Data / Workstation | IMPLEMENTED; TESTED PENDING | Persistent EPIC watchlist, authenticated DEMO search, timestamped Bid/Ask, spread, quote age and feed status; no execution actions. PR #43 qualification pending. |
| SCR-MKT-002 | Market Explorer | Market Data | IN PROGRESS | Provider-backed catalogue search and explicit DEMO stream subscription exist; shared app-scoped model/watchlist integration is in PR #43. |
| SCR-CHART-001 | Chart Workspace | Charting / Market Data | BLOCKED BY CHART DATA CONTRACT | Current UI shows a truthful no-series state. Historical candles, aggregation, chart rendering, indicators, drawings and synchronization are not implemented. |
| SCR-ORD-001 | Order Creation & Review | Order Intake / Risk / OMS | NOT STARTED | No UI dealing workflow until risk authorization, OMS lifecycle, Execution Gateway and broker reconciliation are qualified. |
| SCR-ORD-002 | Order Management | OMS / Execution | NOT STARTED | Requires broker-authoritative order state, fills, cancel/replace semantics and reconciliation. |
| SCR-POS-001 | Positions & Portfolio | Account / Position Management | NOT STARTED | Requires authenticated broker account snapshots and broker-confirmed position projections. |
| SCR-RISK-001 | Risk Management | RiskEngine | NOT STARTED | Requires approved risk policies, account/position data, limits and auditable assessments. |
| SCR-STR-001 | Strategy Center | Strategy OS | NOT STARTED | Requires strategy registry, deterministic lifecycle and runtime governance. |
| SCR-AI-001 | Atheer Mind OS | AI / Decision Intelligence | NOT STARTED | Requires provider-independent Model Gateway, permission profiles, evidence and audit boundaries. |
| SCR-ANA-001 | Performance & Analytics | Analytics | NOT STARTED | Requires reconciled fills, account/position history and environment-separated performance data. |
| SCR-OPS-001 | System & Administration | Platform Operations | IN PROGRESS | Backend health, API diagnostics and broker credential management surfaces exist; complete system observability and operational controls remain pending. |

## SCR-MKT-001 acceptance evidence

- Source: Library ATP-PROMPT-SCREEN-EXEC-001 and Master Visual Design Directive.
- Implementation: `MarketWatchlistStore.swift`, `MarketWatchPanelView.swift`, shared app-scoped `MarketExplorerViewModel`, Command Center integration.
- Tests: watchlist validation, persistence, ordering, unsupported schema recovery, persistence failure, and shared-view-model construction.
- Architecture: `ATP_MARKET_WATCH_WORKSPACE_INTEGRATION.md`, Mermaid diagram 14.
- Verification: exact-head PR #43 CI required; owner-side runtime, accessibility and visual acceptance remain separate.
