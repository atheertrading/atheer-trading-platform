# Instrument Quick Search

**Work package:** ATP-UI-QUICKSEARCH-001  
**Status:** Implemented on a feature branch; exact-head qualification pending  
**Tracking:** UI Delivery Plan #72; Collaboration Charter #79

## Purpose

Provide a native, keyboard-accessible entry point to the existing authenticated
instrument catalogue. This is a focused application-shell capability, not a new
screen destination or a second market-data implementation.

## Interaction

- The sidebar exposes **Search instruments** with the `⌘K` keyboard shortcut.
- The sheet accepts an instrument name or provider EPIC.
- Search uses the existing `MarketSearchClient` and `MarketExplorerViewModel`.
- Results display only provider-returned instrument metadata: name, EPIC, currency,
  and market status when supplied.
- Selecting a result opens the implemented Markets destination and forwards the
  query into its existing search flow.
- Empty, searching, unavailable, and failure states remain explicit.

## Data and security boundary

The UI calls no broker API directly and introduces no backend endpoint. It reuses
the current client contract for authenticated backend status and read-only
Capital.com DEMO catalogue search. The backend remains the owner of provider
credentials and broker sessions.

The search surface does not show prices, balances, positions, order state, or
risk values. It cannot submit, authorize, modify, or cancel an order. Selecting
an instrument changes only the Markets presentation query.

No fixture or sample instrument is injected into production UI state. A result is
rendered only when returned by the client.

## Architecture

- `InstrumentQuickSearchView` is a presentation-only SwiftUI sheet.
- It receives a `MarketSearchClient` through dependency injection.
- It reuses `MarketExplorerViewModel` to avoid duplicating the search state
  machine and request lifecycle.
- `InstrumentQuickSearchRouting` converts a selected catalogue record into a
  search query, preferring a non-empty provider name and falling back to EPIC.
- `MarketExplorerView` consumes the handoff once, clears it before awaiting, and
  runs the same ViewModel search operation. The clear-before-await rule prevents
  duplicate submission from initial appearance and `onChange`.

## Verification

The focused tests verify query handoff into the existing client and the
name-to-EPIC fallback. Existing Market Explorer tests continue to cover
disconnected-session rejection, query bounds, stale-response suppression, and
provider-result presentation.

Hosted exact-head CI, native macOS build/launch, VoiceOver, keyboard, and visual
qualification remain required. The PR is stacked on the operational-status shell
branch and must be reconciled with the charting application-composition changes
tracked by ATP-ENG-063 (#77) before merge.

## Non-negotiable constraints

- `CAP_ALLOW_TRADING=false` remains unchanged.
- No dealing endpoint or execution path is added.
- No placeholder navigation destination is added.
- Workspace, panel, backend, and broker-session lifecycles remain independent.
