# ATP-PRODUCT-IA-001 — Product Information Architecture

**Status:** Proposed product-level structure derived from the owner-directed product scope; formal architecture reconciliation and approval mapping remain open.  
**Applies to:** ATHEER Trading Pro native macOS workstation.  
**Implementation baseline:** PR #17 provides Workspace and API Connection. PR #18 begins the shared visual foundation and operational workspace panels. This document does not imply that future modules are implemented.

## 1. Product organization

ATHEER Trading Pro is organized as a task-oriented trading workstation. The application shell owns navigation, workspace selection, global operational status, and window lifecycle. Feature modules own their workflows and domain presentation. Shared workspace panels may surface module views without creating independent sources of truth.

Proposed navigation groups:

| Group | Modules |
|---|---|
| Overview | Dashboard |
| Markets & Analysis | Markets, Charts, Analytics |
| Trading Operations | Trading, Positions, Orders, Portfolio, Risk Management |
| Research & Intelligence | Strategies, AI Intelligence |
| System | Activity, Settings, API Connection |

Workspace Management is cross-cutting rather than a trading-domain module. It owns workspace profiles, panel visibility, layout composition, and restoration. Its persistence and docking behavior remain subject to formal workspace specifications.

Only implemented destinations are exposed in navigation. A module is not added to navigation until it has a meaningful screen, defined states, and verified behavior.

## 2. Module responsibility and dependency map

| Module | Purpose and primary workflow | Principal data dependencies | Required safety and state semantics | Current implementation |
|---|---|---|---|---|
| Dashboard | Summarize operational readiness and the trader's current market/account/risk context; route to actionable modules | Market freshness, broker/account state, positions, risk, strategies, activity, service health | Distinguish unavailable, stale, disconnected, not-ready, and disabled states; never synthesize financial values | Not implemented as a separate module |
| Markets | Discover instruments, manage watchlists, inspect quotes and market sessions | Instrument registry/specifications, broker catalogue, normalized quotes, timestamps, freshness and stream health | Show source and timestamp; stale or missing data must not appear current | Market Watch panel exists as an unavailable state only |
| Charts | Inspect price history and live series with technical analysis and drawing tools | Validated historical/live market series, instrument metadata, session/timezone context, indicator calculations | No invented candles or prices; show gaps, stale streams and unavailable history explicitly | Chart Workspace panel exists as an unavailable state only |
| Trading | Prepare discretionary order intents and review validation/risk outcomes | Instrument/account identity, quote snapshot, order-intent contract, risk authorization, OMS state | No direct broker dealing; all future intents must use RiskEngine → OMS → Execution Gateway | Not implemented; no order controls |
| Positions | Monitor broker-confirmed open positions, exposure and lifecycle | Broker-confirmed positions, executions/fills, account and instrument metadata, reconciliation | Broker is authoritative; distinguish requested, acknowledged, filled and reconciled states | Account & Risk panel reports account unavailable |
| Orders | Monitor order lifecycle, acknowledgements, fills, rejections and cancellations | OMS order records, immutable execution events, broker reports, reconciliation | No optimistic claim of broker acceptance/fill; actions require governed authorization | Not implemented; no order controls |
| Strategies | Configure and supervise strategy lifecycle, signals and performance | Strategy registry/configuration, market data, backtest/simulation results, order-intent and risk contracts | Strategy execution cannot bypass RiskEngine or Execution Gateway; environment isolation is mandatory | Not implemented |
| Portfolio | Present account balances, margin, valuation, allocation and exposure | Broker-confirmed account state, positions, instrument valuation, currency metadata | No estimated or fabricated account values presented as broker facts | Not implemented |
| Risk Management | Explain risk state, limits, assessments, rejections and operational lockouts | RiskEngine assessments/policies, positions/exposure, account/margin, market-data quality | UI is not an authorization authority; no control may bypass centralized RiskEngine | Not implemented; account/risk panel is explicitly unavailable |
| Analytics | Analyze validated historical market, portfolio, execution and strategy outcomes | Time-series data, broker executions, account history, strategy/backtest metrics | Label sample/backtest/simulation/live provenance and methodology | Not implemented |
| AI Intelligence | Present research, agent activity, recommendations and decision provenance | Provider-independent Model Gateway, approved context, agent permissions, tool results, decision records | AI is decision support; agents cannot self-authorize or call broker dealing APIs | Not implemented |
| Activity | Provide an auditable chronology of application, service, strategy and trading events | Audit/event records, health transitions, OMS and broker events | Preserve event provenance and distinguish local observations from broker-confirmed events | Not implemented |
| Settings | Configure application, workspace, services and broker preferences | Typed configuration, secure credential references, workspace preferences, service contracts | Secrets stay out of diagnostics and clipboard; closing the window does not imply rollback or service/trading side effects | Not implemented; settings source inventory and persistence rules remain under reconciliation |
| API Connection | Inspect local middleware liveness, readiness, dependency state and diagnostics | Existing read-only health endpoints at 127.0.0.1:4100 | Liveness is not readiness; HTTP 503/not_ready is not a transport disconnect; no credentials or dealing operations | Implemented in PR #17 |

## 3. Shared application and workspace contracts

### Application shell
- Owns application identity, primary navigation, selected destination, global status presentation and native window behavior.
- Does not own trading-domain policy or broker state.
- Uses feature-owned view models/services injected at the application boundary.
- Exposes only implemented destinations.

### Workspace
The initial operational workspace composes:
- Market Watch — unavailable until instrument and quote services exist.
- Chart Workspace — unavailable until validated time-series data and charting services exist.
- Account & Risk — unavailable until broker-confirmed account and risk services exist.
- Platform Health — reuses the local backend health view model.

The panels must not show fabricated prices, balances, positions, P&L, orders or risk outcomes. Panel show/hide is currently in-memory presentation state only. Layout persistence, drag/docking, panel resizing, multiple profiles and restoration are not implemented pending formal specification reconciliation.

### API and operational status
Keep process liveness, platform readiness, persistence, broker connectivity, market-data readiness, risk readiness, trading availability and LIVE authorization as distinct states. A successful process health response is not permission to trade.

### Settings window
The owner-directed interaction baseline recorded in ATP-UX-001 is a dedicated Settings window with a section sidebar, primary content area, bottom Close action and native window close behavior. Closing Settings closes the window only; it must not silently revert settings, disconnect services, stop strategies or change trading state. Full settings sections and persistence semantics remain unimplemented pending formal source reconciliation.

## 4. Cross-cutting screen states

Every module must define, as applicable:
- Initial/idle state.
- Loading and refreshing.
- Valid data.
- Empty data (no records exist).
- Unavailable integration (capability not implemented/configured).
- Disconnected transport.
- Invalid or inconsistent response.
- Stale data.
- Permission denied or action unavailable.
- Error and recoverable state.

Do not collapse these into a single empty view or infer readiness from a successful network connection.

## 5. Governing boundaries

- Broker-confirmed financial state is authoritative.
- SIMULATION, BACKTEST, DEMO and LIVE remain isolated.
- No LIVE trading is enabled.
- Manual, strategy and AI order intents must eventually converge on the same governed authorization and execution path.
- No UI or AI component may call broker dealing APIs directly.
- No screen may claim a feature is available solely because a navigation destination exists.

## 6. Source reconciliation and open decisions

This proposed map must be reconciled against the full approved texts and approval metadata for ATP-ARCH-014, ATP-ARCH-037, ATP-ARCH-038 and the original IPDS sources. Those exact source texts and approval metadata were not surfaced by the current Library retrieval. ATP-UX-001 is available on PR #13 as an owner-directed UI/UX directive and remains documentation-only until integrated.

Open items:
1. Confirm the authoritative final module inventory and workspace grouping.
2. Reconcile Settings section inventory, persistence, and window lifecycle.
3. Reconcile panel docking/resizing/persistence semantics.
4. Finalize IPDS v1.0 token/component/accessibility contracts.
5. Define per-module service contracts and detailed interaction states before implementing their navigation destinations.
