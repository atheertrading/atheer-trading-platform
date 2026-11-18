# Engineering Session 049 — Broker Session IPC Integration

**Date:** 2026-11-18  
**Product:** ATHEER Trading Pro  
**Repository:** `atheertrading/atheer-trading-platform`  
**Implementation PR:** [#55](https://github.com/atheertrading/atheer-trading-platform/pull/55)  
**Parent runtime PR:** [#54](https://github.com/atheertrading/atheer-trading-platform/pull/54)  
**IPC contract PR:** [#51](https://github.com/atheertrading/atheer-trading-platform/pull/51)  
**Implementation branch:** `feat/capital-demo-session-streaming-ipc`

## 1. Objective

Remove the duplicate broker-session authority between the macOS app and backend. Keep user credentials in macOS Keychain, provision them to one authenticated backend process over private loopback IPC, and keep Capital.com session tokens and streaming credentials backend-owned.

This increment is connectivity and market-data infrastructure only. It does not add order placement, dealing, LIVE access, or trading authorization.

## 2. Implemented on the unmerged PR branch

### Backend session ownership

- Added `BrokerSessionManager` as the single backend owner for Capital.com DEMO credentials, REST session lifecycle, keepalive access, and streaming connection information.
- Added capability-protected `/broker-session/status`, `/broker-session/connect`, and `/broker-session/disconnect` routes.
- Credential input is restricted to a bounded JSON payload containing exactly `apiKey`, `identifier`, and `password`. Unsupported media types, malformed JSON, unexpected fields, and oversized bodies fail closed.
- Session responses are sanitized and marked `no-store`; provider CST and security tokens are never returned.
- Session creation is throttled to the Library-recorded Capital.com limit of one request per second per API key. HTTP 401, 403, and 429 remain distinct classifications.
- The manager drops its credential-bearing runtime reference even if remote logout fails. The API reports failure rather than falsely confirming a successful logout.
- Account replacement disconnects the streaming runtime only after the session throttle permits replacement; a rejected rate-limited attempt does not unnecessarily tear down the existing stream.
- A stream shutdown failure does not prevent the backend from attempting REST logout. The response remains an explicit failure if the complete shutdown cannot be confirmed.

### Native macOS integration

- Added `BackendBrokerAuthenticationService`, which sends Keychain-loaded DEMO credentials only to the authenticated backend loopback endpoint.
- The app does not maintain a second Capital.com REST session or receive provider session tokens.
- Requests use an ephemeral URLSession, disabled cache/cookie storage, no-store headers, and the per-launch IPC bearer capability.
- The native service rejects LIVE authentication before network access and maps 401, 403, and 429 distinctly.
- Broker management is composed through `BackendRuntimeViewModel`; the old direct native Capital.com authentication owner was removed from that path.
- The adapter uses the shared `URLSessionRequestExecutor` so Foundation's non-Sendable URLSession delegate parameter does not cross the main-actor boundary. This follows the repository's existing Swift 5.8 concurrency mitigation.

### Tests added

- Backend API integration tests for authenticated status, bounded credential handoff, sanitized responses, session creation throttling, account-switch protection, logout failure cleanup, and stream-shutdown failure handling.
- Native URLProtocol tests for authenticated credential handoff, DEMO-only enforcement, 401/403/429 classification, and confirmed logout.
- Existing stream lifecycle and quote-quality coverage is retained and adapted to the authenticated IPC contract.

## 3. Library and architecture sources consulted

The following owner-curated Library sources were inspected for this increment:

- **Screen Implementation, Application Development & Professional Trading Workstation** — governing implementation and verification contract.
- **Atheer Q&A Repository — Broker Integration Q4** — Capital.com API constraints, including one session-creation request per second per API key, ten-minute REST session inactivity, WebSocket session lifecycle, and a 40-instrument subscription ceiling.
- **Atheer Q&A Repository — Broker Integration Q8** — session termination classification; 401 authentication failure, 403 permission restriction, 429 rate limiting, and the requirement to distinguish REST session loss from WebSocket disconnection.
- **Atheer Q&A Repository — Real-Time Market Data Q1 and Q7** — Capital.com as the initial primary real-time source, bid/ask and timestamp provenance, and separation of execution processing from UI rendering.
- **Codex knowledge base — ATP-MER-001 Mermaid Diagram Catalogue** and the source diagrams `system-context.mmd`, `market-data-pipeline.mmd`, `ai-order-boundary.mmd`, and `target-trading-boundaries.mmd`.

The Mermaid catalogue explicitly classifies these diagrams as proposed target context/pipelines and says syntax validation is pending. They were used as architectural guidance, not represented as deployed topology. The market-data diagram reinforces source provenance, normalization, sequence/freshness validation, and stale-data isolation. The AI/order boundary and target-trading-boundaries diagrams preserve the invariant that human, strategy, and AI intents converge on backend validation, centralized RiskEngine, OMS, Execution Gateway, broker confirmation, and reconciliation. This PR does not implement or bypass those trading components.

## 4. Pull-request stack and verification

| PR | Base | Role | Current status |
|---|---|---|---|
| #51 | `main` | Private IPC capability contract and backend route authorization | Open; parent dependency |
| #54 | PR #51 branch | Bundled backend process supervisor and authenticated native IPC | Draft; parent of this PR |
| #55 | PR #54 branch | Broker session authority and native Keychain handoff | Draft; this increment |

### Evidence available at this report

- PR #54 exact-head CI run `44276116460` on `90dfaef64e0845cb2c968c84086db43f0662aecb`: Repository hygiene passed; Backend Toolchain (typecheck and API tests) passed; universal Node runtime packaging and Intel architecture inspection passed; Intel XcodeGen stage was in progress and Apple Silicon was queued at last inspection.
- PR #55 intermediate runs were superseded/cancelled as implementation commits arrived. A prior run completed the API typecheck before its test step was cancelled; that is not a passing test result for the final head.
- Local Sync Safety passed on intermediate PR #55 heads. A final exact-head full CI run is still required after this report commit.
- No local Mac/Xcode build, owner-workstation launch, visual/accessibility qualification, Keychain restart test, or real Capital.com DEMO authentication was performed in this environment.

## 5. Remaining acceptance gates

1. Complete PR #51 checks and merge the capability contract only after its exact-head qualification.
2. Complete PR #54 Intel and Apple Silicon build/test/Release qualification, then merge it into the capability branch in stack order.
3. Rebase/retarget PR #55 only after its parent is integrated, without force-pushing or rewriting shared history.
4. Require final exact-head backend typecheck/tests, Intel and Apple Silicon Debug/XCTest/Release, repository hygiene, and CodeQL as configured.
5. On the owner's Mac, verify packaged Node launch, ephemeral port discovery, authenticated IPC, Keychain save/load/restart, broker connect/disconnect, UI responsiveness, and accessibility.
6. Run an explicitly authorized Capital.com DEMO qualification using owner-provided credentials; validate session status, REST keepalive, streaming reconnect, account-switch behavior, and reconciliation before any future dealing work.

## 6. Safety and product status

- `CAP_ALLOW_TRADING=false`; trading remains disabled.
- LIVE broker authentication and order/dealing routes remain unavailable.
- No broker credentials or real DEMO session were used.
- No claim is made that this batch is merged, release-ready, or broker-qualified.
- Manual and automated order intents must continue to converge on the same future governed path: authorization → centralized RiskEngine → OMS → Execution Gateway → broker → reconciliation.
