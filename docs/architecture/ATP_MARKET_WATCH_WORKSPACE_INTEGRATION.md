# ATP-MARKET-001 — Command Center Live Market Watch Integration

**Screen ID:** SCR-MKT-001  
**Status:** Implemented on a stacked branch; exact-head macOS qualification pending  
**Branch:** `feat/command-center-live-market-watch`  
**Parent:** PR #42 — Authorized OMS Lifecycle Persistence  
**Provider:** Capital.com DEMO market-data REST/SSE boundary  
**Trading capability:** Read-only; no order entry or broker dealing

## 1. Design authority

This increment implements the governing screen directive **ATP-PROMPT-SCREEN-EXEC-001 — Screen Implementation, Application Development & Professional Trading Workstation** from the ChatGPT Library and the Library's **Professional Trading Screens, Workspace Architecture & User Experience** specification.

The design baseline requires a persistent native macOS shell, a configurable workspace, authentic provider-backed market watch, explicit connection/freshness states, no fabricated prices, and separation between market data, broker authentication, risk authorization, and execution.

The screen is designed around the established ATHEER palette and existing SwiftUI design tokens. It does not copy proprietary layouts from Bloomberg, TradingView, Interactive Brokers, or other reference products.

## 2. Screen purpose and workflow

The Command Center's Market Watch panel allows a trader to:

1. Search the authenticated Capital.com DEMO instrument catalogue.
2. Add provider-returned instrument EPICs to a persistent, ordered watchlist.
3. Subscribe selected watchlist instruments to the existing timestamped DEMO quote stream.
4. Monitor Bid, Ask, Spread, quote age, and feed/subscription state.
5. Remove instruments from the watchlist; removal also releases that instrument's stream subscription.
6. Open the full Market Explorer or API diagnostics.

The full Market Explorer and Command Center share one app-scoped `MarketExplorerViewModel` and one `MarketWatchlistStore`. Navigating between screens does not recreate the market-data runtime or silently cancel a requested stream.

## 3. State ownership and lifecycle

| State | Owner | Persistence / lifecycle |
|---|---|---|
| Backend DEMO market-data status | App-scoped `MarketExplorerViewModel` | Refreshed from backend status API |
| Search query and result state | App-scoped `MarketExplorerViewModel` | In-memory; shared across Markets and Command Center |
| Stream request, selected EPICs, quote cache, connection state | App-scoped `MarketExplorerViewModel` | In-memory; explicit Start/Stop; survives screen/panel navigation |
| Watchlist EPICs and ordering | `MarketWatchlistStore` | Versioned UserDefaults persistence |
| Workspace panel visibility/order | `WorkspaceEngine` | Independent, existing workspace persistence |
| Broker account/session state | Broker management domain | Separate; not inferred from market-data session |
| Trading permission | Backend trading gate | Remains disabled; never owned by the screen |

Workspace panel visibility does not own the market-data stream. Hiding/removing the panel must not implicitly cancel orders, positions, strategies, RiskEngine, or other runtime services. The Market Watch panel does not call any trading or broker-dealing API.

## 4. Data and safety contract

- Catalogue results come from the authenticated backend DEMO REST session.
- Bid/Ask values appear only from timestamped Capital.com DEMO SSE quote events.
- No sample prices, synthetic prices, fake P&L, or fabricated account/position data are shown.
- Quote age is calculated from provider timestamp; freshness is shown explicitly.
- A missing quote is displayed as unavailable, not replaced by a cached or fabricated value.
- The provider stream limit of 40 instruments is enforced by the watchlist store and stream model.
- Market-data connection is not broker account authentication.
- Broker disconnected/account unavailable/execution disabled remain separate, truthful operational states.
- `CAP_ALLOW_TRADING=false` remains unchanged.

## 5. Implemented components

- `MarketWatchlistStore`: versioned persistence, EPIC validation, duplicate prevention, 40-instrument cap, ordering, and non-destructive recovery from corrupt/unsupported persisted data.
- `MarketWatchPanelView`: compact professional watchlist, search/add, live quote display, spread, quote age, feed status, explicit stream controls, and diagnostics/navigation actions.
- `MarketExplorerView`: uses the shared app-scoped model/store and adds provider search results to the persistent watchlist.
- `ContentView`: owns shared market data and watchlist state for the application lifecycle.
- `WorkspaceHomeView` / `CommandCenterView`: receive shared services through explicit dependency injection.
- Command Center market-data status now reflects actual backend/stream state instead of a hard-coded unavailable label.

## 6. Explicit non-scope

- No chart/candle engine or technical indicators.
- No market depth/order book unless the provider exposes and validates it.
- No account balance, positions, P&L, or risk metrics.
- No order creation, order submission, cancellation, modification, or close action.
- No broker account authentication inferred from the market-data session.
- No strategy or AI runtime side effects.

## 7. Verification

- Unit tests cover watchlist persistence round-trip, duplicate idempotency, invalid EPIC rejection, maximum size, ordering, unsupported schema recovery without overwriting stored data, and save-failure behavior.
- SwiftUI construction tests cover shared Market Explorer / Market Watch models.
- Hosted macOS Intel x86_64 and Apple Silicon arm64 build/test/release jobs must pass on the exact PR head.
- Owner-side Mac runtime, Keychain, accessibility/VoiceOver, window resizing, and multi-display visual qualification remain separate acceptance steps.
