# ATHEER Trading Pro — Screen and Workflow Inventory

**Status:** Incremental implementation register; not a declaration that the full product screen inventory is complete.  
**Scope:** Screens implemented or being implemented in the native macOS workstation.  
**Authority:** Owner instructions, approved requirements where available, current repository evidence, and reconciled Library specifications.

## Screen register

| Screen ID | Navigation group | Screen | Purpose | Implementation status | Verification status |
|---|---|---|---|---|---|
| ATP-SCR-MKT-001 | Markets | Market Explorer / Instrument Search | Search the Capital.com DEMO instrument catalogue through the backend's authenticated read-only REST session | IMPLEMENTED on feat/macos-market-explorer; PR review pending | CI and owner-Mac build/runtime/visual/accessibility verification pending |

## ATP-SCR-MKT-001 — Market Explorer / Instrument Search

### Purpose and workflow

Allow the trader to discover instruments using the Capital.com DEMO market catalogue. The screen first reads GET /market-data/status, then permits a read-only instrument search only when the backend reports an active DEMO REST session.

**Workflow:**

1. Open Markets → Market Explorer.
2. Read GET /market-data/status.
3. Confirm provider is capital.com, environment is DEMO, and REST session state is connected.
4. Enter a search term and submit.
5. Read GET /market-data/markets?searchTerm=...
6. Validate provider/environment and instrument identity.
7. Display provider-backed instrument metadata and explicit empty/error/unavailable states.

### Data contract

- Backend status: provider, environment, and connection state.
- Instrument result: epic, optional instrumentName, optional marketStatus, and optional currency.
- Bid/offer fields are intentionally not displayed because the current search response contract does not provide the timestamp/freshness metadata required to represent them as current market quotes.

### State and safety rules

- DEMO is visibly labelled.
- REST authentication/session state is distinct from market-data streaming state.
- Streaming is explicitly shown as NOT CONNECTED.
- Trading is explicitly shown as DISABLED.
- The app's native Keychain broker credentials/session and the backend's environment-configured DEMO credentials are separate in this increment. No credential transfer or shared-session behavior is claimed.
- Search is blocked unless the backend reports a connected DEMO session.
- No quote, candle, account, position, P&L, order, fill, or execution values are fabricated.
- No order or dealing actions exist on this screen.

### Source and tests

- apps/macos/ATHEERTradingPro/Sources/MarketExplorerView.swift
- apps/macos/ATHEERTradingPro/Sources/Services/MarketSearchClient.swift
- apps/macos/ATHEERTradingPro/Sources/AppSection.swift
- apps/macos/ATHEERTradingPro/Sources/ContentView.swift
- apps/macos/ATHEERTradingPro/Tests/ATHEERTradingProTests.swift

Deterministic XCTest source coverage includes DEMO-only status decoding, DEMO instrument metadata decoding, rejection of LIVE/invalid instrument responses, blocking search while disconnected, and publishing results after a connected backend status.

### Dependencies and remaining acceptance

- PR #24: Command Center / Workspace foundation.
- PR #25: backend-owned Capital.com DEMO market-data REST adapter and market search route.
- PR #26: native DEMO broker credential and authentication management.
- New work is stacked on PR #26 exact head; PR #24/#25/#26 are not modified by this branch.

Acceptance still requires exact-head CI, owner-Mac Xcode/XCTest/build verification, visual and accessibility review, and backend DEMO session verification. Native Keychain-to-backend credential/session integration remains a separate security design and implementation task; do not infer it from this screen.
