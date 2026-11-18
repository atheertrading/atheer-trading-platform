# ATHEER Trading Pro — Screen and Workflow Inventory

**Status:** Incremental implementation register; not a declaration that the full product screen inventory is complete.  
**Scope:** Screens implemented or being implemented in the native macOS workstation.  
**Authority:** Owner instructions, approved requirements where available, current repository evidence, and reconciled Library specifications.

## Screen register

| Screen ID | Navigation group | Screen | Purpose | Implementation status | Verification status |
|---|---|---|---|---|---|
| ATP-SCR-MKT-001 | Markets | Market Explorer / Instrument Search | Search the Capital.com DEMO instrument catalogue through the backend's authenticated read-only REST session | IMPLEMENTED; backend streaming health display in development on PR #55 | Exact-head CI and owner-Mac build/runtime/visual/accessibility verification pending |
| ATP-SCR-BRK-001 | System & Administration | Broker Management / Capital.com Connection | Store broker credentials in macOS Keychain and provision them to the single backend-owned Capital.com DEMO session over authenticated private IPC | IN DEVELOPMENT on PR #55, stacked on PR #51/#54/#56 | Exact-head CI, owner-Mac Keychain/process qualification, and real DEMO authentication pending |

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
- Streaming connection state and active subscription count are decoded from the authenticated backend status response; the Market Explorer does not itself create subscriptions.
- Trading is explicitly shown as DISABLED.
- Broker credentials persist in macOS Keychain and are handed to the backend through the per-launch authenticated IPC capability. Capital.com REST session tokens and streaming connection information remain backend-owned. The Market Explorer reads the same backend session status used by broker management.
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

- PR #33: Market Explorer integration (merged into main).
- PR #51: private backend IPC capability contract.
- PR #54: managed macOS backend process supervisor.
- PR #56: Swift actor-isolation fixes for the supervisor composition.
- PR #55: backend BrokerSessionManager and native Keychain credential handoff; this PR is stacked on PR #56.

Acceptance still requires exact-head CI, owner-Mac Xcode/XCTest/build verification, visual and accessibility review, and backend DEMO session verification. Native Keychain-to-backend credential/session integration remains a separate security design and implementation task; do not infer it from this screen.


## ATP-SCR-BRK-001 — Broker Management / Capital.com Connection

### Purpose and workflow

Provide a real broker-connection management surface under Settings → Brokers. Credentials are stored in macOS Keychain; the macOS app is a credential-entry and session-control client, while the backend is the sole owner of Capital.com REST session tokens, keepalive, and streaming connection information.

**Implemented workflow on PR #55 (unmerged):**

1. Open Settings → Brokers.
2. Load the Capital.com DEMO credential record from Keychain.
3. Save or replace credentials only through the Keychain credential store.
4. Start the managed backend process with a per-launch 256-bit capability delivered over private stdin.
5. Verify backend liveness and authenticated market-data IPC before exposing the broker adapter.
6. Submit DEMO credentials to `POST /broker-session/connect` over authenticated loopback IPC.
7. Read sanitized session status from `GET /broker-session/status`.
8. Disconnect through `POST /broker-session/disconnect`; report incomplete shutdown rather than claiming success if stream or REST logout cannot be confirmed.

### Data and security contract

- Keychain is the persistent credential store; no API key or password is placed in UserDefaults, environment variables, command-line arguments, logs, or Git.
- Backend broker-session endpoints require the per-launch IPC bearer capability and reject browser-origin/cross-site request context.
- Credential handoff accepts only a bounded JSON payload with the three required Capital.com DEMO fields.
- Provider CST and security tokens remain backend-only and are never returned to the UI.
- HTTP 401, 403, and 429 are kept distinct: authentication rejection, permission restriction, and rate limiting.
- Capital.com session creation is throttled to the Library-recorded one request per second per API key.
- LIVE authentication and dealing remain disabled.

### Implementation status and remaining acceptance

- Native adapter: `BackendBrokerAuthenticationService.swift`.
- Backend owner: `services/api/src/market-data/broker-session-manager.ts`.
- Backend endpoints: `services/api/src/server.ts`.
- Process and IPC lifecycle: `BackendProcessSupervisor.swift` and `BackendRuntimeViewModel.swift`.
- Tests: `BackendBrokerAuthenticationServiceTests.swift`, `services/api/test/market-data-runtime.test.mjs`.
- PR stack: #51 → #54 → #56 → #55; all remain unmerged/draft at the time of this inventory update.
- Exact-head backend/Intel/Apple Silicon CI, owner-Mac Xcode/XCTest and visual/accessibility QA, Keychain persistence/restart qualification, and real Capital.com DEMO authentication remain pending.
- This screen is not a completed Broker Directory, Instrument Catalog, account-selection, or diagnostics suite. The remaining broker-management screens from the Library specification must be implemented as separate, evidenced workflows.
