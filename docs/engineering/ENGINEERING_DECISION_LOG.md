# ATHEER Trading — Engineering Decision Log

This log records decisions and proposals across project knowledge sources. It does not replace formal ADRs. Formal architectural decisions must be reconciled with historical ADRs before assigning or reusing ADR identifiers.

## Owner-endorsed decisions

### EDL-001 — Federated project knowledge and authority

- **Date:** 2026-11-16
- **Status:** Owner-endorsed
- **Decision:** GitHub, ChatGPT Library, and relevant historical ChatGPT conversations form a coordinated project knowledge system. GitHub is authoritative for committed software and Git history, but is not the sole authoritative source for all project architecture or knowledge. The Library remains the designated workspace for governing standards, specifications, architecture documentation, research, and archives. Conversations preserve chronology and rationale. Continuity records connect these sources.
- **Consequences:** Maintain source provenance, document registry, conversation index, decision log, and continuity records. Do not duplicate or silently supersede authoritative documents.

### EDL-002 — Public foundational repository

- **Date:** 2026-11-16
- **Status:** Owner-endorsed
- **Decision:** `atheertrading/atheer-trading-platform` is public during the foundational stage.
- **Consequences:** Treat all committed content, issues, pull requests, workflow logs, and artifacts as public. Never commit secrets or sensitive account data. Public visibility does not itself grant a reuse license; license selection remains a separate owner decision.

### EDL-003 — Provider-independent AI extensibility

- **Date:** 2026-11-16
- **Status:** Owner-endorsed product/architecture direction; detailed design pending
- **Decision:** AI is a foundational platform capability. The architecture should remain extensible across model providers, hosted and local models, agent frameworks, tools, and multi-agent orchestration rather than imposing arbitrary single-vendor restrictions. AI agents may initiate and execute pre-authorized workflows, including bounded autonomous trading and position-management operations, within their assigned mandate.
- **Constraints:** Model/provider flexibility does not imply ungoverned permissions. Agents must have explicit responsibilities, least-privilege tool access, data boundaries, auditability, and controlled side effects. Agents cannot access broker dealing APIs directly, authorize their own risk, or expand their permissions. Every financial action must pass through the same centralized authorization, RiskEngine, OMS, and Execution Gateway path as other order sources.
- **Next:** Develop an AI architecture proposal and compare provider abstraction, model routing, agent runtime, tool contracts, evaluation, observability, and cost/latency controls.

## Proposals and unresolved decisions

| ID | Topic | Status | Required next step |
|---|---|---|---|
| EDP-001 | Modular monorepo structure | Proposed | Reconcile surviving code and documentation before finalizing boundaries |
| EDP-002 | IPDS color and semantic token system | Proposed | Inspect existing visual specifications, then validate contrast and component semantics |
| EDP-003 | License for public repository | Unresolved | Owner selects an explicit license; do not add one by assumption |
| EDP-004 | Branch protection and merge policy | Pending configuration | Inspect repository settings and choose enforceable rules |
| EDP-005 | CI toolchain matrix | Pending verification | Confirm local and hosted Swift/Xcode/Node toolchains |

## Decision maintenance

Every material decision must state its source, date, scope, status, rationale, consequences, and whether a formal ADR is required. Superseded decisions remain in the log with a replacement reference; do not erase history.


### EDP-006 — Orthogonal AI autonomy and capability permissions

- **Date:** 2026-11-16
- **Status:** Proposed synthesis; formal source reconciliation pending
- **Source basis:** ATP-ARCH-011, ATP-ARCH-028, ATP-ARCH-029; Q27.2, Q27.4, Q27.5, Q27.6, Q28.24, Q28.47, and Q29.5 in the Library Q&A archive.
- **Problem:** The source set uses multiple taxonomies: five operational autonomy levels (L0–L4 / A0–A4), four capability-authority levels (observe/analyze/propose/controlled operation), and three execution models. These describe related but non-identical concerns.
- **Recommendation:** Model autonomy level and capability permissions as separate dimensions. Autonomy describes how independently an agent may operate a workflow; permissions describe which data, tools, records, and side effects it may access. Every action additionally carries an authorization classification and passes the receiving domain's deterministic policy.
- **Execution boundary:** Agents may initiate pre-authorized order workflows, but cannot submit directly to broker APIs or authorize risk. All financial state changes use the central RiskEngine, OMS, and Execution Gateway.
- **Next:** Reconcile the formal specifications and Q&A decision chronology, then establish one canonical autonomy/permission matrix with migration mappings from the historical labels.


### EDL-004 — Consolidated modular engineering repository

- Date: 2026-11-16
- Status: Adopted under the owner's current direction.
- Decision: Use atheertrading/atheer-trading-platform as the single modular engineering monorepo. The ChatGPT Library remains the federated authority for approved specifications, standards, research, and historical archives; conversation chronology is indexed through continuity records.
- Historical reconciliation: This supersedes ATP-ARCH-042 only for the prescribed four separate Git repositories. Its substantive architecture, governance, and control requirements remain in force unless separately revised. The original specification remains preserved in the Library.
- Rationale: Atomic changes across source, tests, contracts, build and documentation; one AI navigation hierarchy; simpler CI and integration; no loss of Library knowledge authority.
- Consequences: Maintain logical ownership domains, CODEOWNERS, traceability, modular dependency rules, and source provenance. Do not create additional repositories absent a new ADR.


## EDL-005 — Mermaid architecture diagrams are maintained as source

**Date:** 2026-11-16  
**Status:** Accepted engineering practice under delegated Head of Engineering authority  
**Decision:** Maintain architecture diagrams as version-controlled Mermaid source files (`.mmd`) under `docs/architecture/diagrams/`, with a catalog, provenance for historical extracts, and automated rendering in CI. Historical diagrams must be preserved separately from canonical current diagrams; extraction does not imply approval or implementation.  
**Rationale:** Source-controlled diagrams are diffable, reviewable, reproducible, and can be validated alongside architecture documentation. Exported images alone are not sufficient source artifacts.  
**Constraints:** Mermaid diagrams express intended architecture and workflows; they are not evidence of implementation. Historical source paths and revisions must remain traceable. A diagram may be marked superseded only with an explicit replacement reference; original source content is retained.

## EDL-006 — Conservative Xcode configuration baseline

- **Date:** 2026-11-16
- **Status:** Accepted engineering decision under delegated Head of Engineering authority; implementation is present on the Phase 2 review branch and hosted CI passed; local Xcode 14.3.1 compatibility verification remains pending.
- **Scope:** Native macOS project configuration for `ATHEERTradingPro`.
- **Decision:** Preserve the verified project identity (bundle ID `com.atheertrading.desktop`), macOS 13.0 deployment target, Swift 5 language mode, and pinned XcodeGen 2.36.1 toolchain compatibility. Define explicit Debug and Release build configurations. Enable targeted Swift concurrency diagnostics as a staged migration baseline. Keep standard architecture selection rather than forcing a universal binary. Keep local/CI code signing disabled pending Phase 3. Do not invent app entitlements, sandbox capabilities, icons, UI-test targets, or package dependencies without concrete product requirements.
- **Rationale:** Minimize compatibility risk against the historical Xcode 14.3.1 / Swift 5.8.1 Intel workstation while improving build reproducibility, diagnostics, and Release qualification.
- **Consequences:** CI must generate the project, inspect the scheme, build Debug, run XCTest, and build Release. Local Intel/Xcode 14.3.1 verification remains required. arm64 requires a separate verified host/toolchain. Hardened-runtime settings do not constitute signing or notarization.
- **Evidence:** Session `ATP-2026-11-16-011`; branch `build/phase-2-xcode-configuration`.
- **Formal ADR:** Not assigned; historical ADR inventory/reconciliation remains in progress.


## EDL-007 — Local backend health vertical slice

- Date: 2026-11-16
- Status: Accepted engineering decision for the bounded local-development slice under delegated engineering authority; not an owner-approved general API transport decision.
- Decision: Establish a minimal Node.js 24 / TypeScript API process using Node's built-in HTTP server. Bind only to 127.0.0.1 by default and reject non-loopback host configuration. Expose GET /health/live for process liveness and GET /health/ready for platform readiness.
- Readiness remains HTTP 503 while persistence and broker adapters are not configured. Trading is explicitly disabled. No market, account, order, strategy, risk, or broker endpoints are exposed.
- Rationale: Deliver a non-trading application/backend operational slice without fabricating data, exposing services to the network, or prematurely deciding the full API/event transport architecture.
- Constraints: The slice does not settle REST versus WebSocket versus IPC for business APIs. It does not establish database, broker, authentication, production, or LIVE readiness.
- Verification: Strict TypeScript build/check and six Node test cases passed in an isolated Linux container using Node 22.16.0. A prior GitHub run on the previous revision passed npm ci, typecheck, and tests on Node 24.22.2, repository hygiene, and GitHub Actions CodeQL; the macOS build remained queued. The compile-first refactor requires a fresh hosted run; local Mac verification remains pending.


## EDL-008 — Native macOS consumption of local backend health

- Date: 2026-11-16
- Status: Accepted bounded integration decision under delegated engineering authority.
- Decision: The macOS application reads the local backend's liveness and readiness endpoints through an injected URLSession client at 127.0.0.1:4100. A small view model owns refresh state; the workspace displays API connectivity, platform readiness, persistence, broker, and trading state.
- HTTP 503 with a valid not_ready readiness payload is treated as a successful health-query exchange. The UI reports API connected and platform not ready separately.
- The app performs one initial health check and offers manual refresh. It does not poll continuously or manage/launch the backend process.
- No broker credentials, account data, market data, orders, or execution operations are introduced. Trading remains disabled.
- This decision applies only to the local health contract. It does not settle general business API transport, authentication, authorization, or service discovery.
- Verification: Swift 6.2.1 Linux Foundation/URLSession typecheck and Swift-to-Node local health smoke test passed. Xcode/macOS CI and local Mac qualification remain pending.

## EDL-009 — Non-destructive local main synchronization

- Date: 2026-11-16
- Status: Accepted operational safety decision under delegated engineering authority.
- Decision: Local main synchronization must validate the expected repository origin, preserve staged and unstaged patches and non-ignored untracked files in a private external backup, create a local pre-sync branch and retained stash, then fast-forward main only.
- After updating main, restore the original branch and reapply the stash with index state. Retain the stash, backup branch, and external backup for inspection; never auto-drop preservation data.
- Reject detached HEAD, unexpected origin, and divergent main history. Do not reset, clean, force-push, delete local branches, or automatically merge/rebase feature branches.
- The default local path is $HOME/Developer/AtheerTradingPlatform. The bootstrap refuses to proceed from a restored non-main branch.
- Verification: functional tests passed in temporary local Git repositories for dirty worktree, clean fast-forward, wrong origin, and divergent main. This does not qualify the owner's actual Mac.


### EDL-008 implementation invariant clarification — 2026-11-16

The native health client is constrained to the loopback endpoint `127.0.0.1:4100`. The client must reject contradictory readiness payloads that report platform `not_ready` while trading is enabled. This is a fail-closed client validation invariant; it does not grant or implement trading authority.


## EDL-010 — Native macOS broker credential custody and DEMO authentication

- Date: 2026-11-17
- Status: Owner-directed implementation decision for the native desktop client.
- Decision: The native ATHEER Trading Pro macOS application stores broker credentials in macOS Keychain, isolated by broker, environment, and account login identity. Capital.com DEMO authentication is performed by a dedicated native provider service using the verified REST session contract. CST and X-SECURITY-TOKEN remain in memory only.
- Scope: This decision applies to the owner-directed local macOS credential workflow. It does not change the backend-owned credential boundary for remote clients, hosted services, or future multi-client deployments; those must use a dedicated secure backend vault and explicit account authorization.
- Rationale: The native desktop product requires local secure credential entry, persistence, editing, and deletion in Keychain. The existing backend adapter is environment-configured and does not provide an authenticated user credential-management API.
- Mandatory constraints: DEMO only; LIVE rejected; no dealing, order, position mutation, or account mutation methods; no secrets in UserDefaults, logs, diagnostics, source control, or network response payloads; no trading authorization or risk-control changes. Capital.com API keys are trading-capable and are not read-only, so the native feature must remain capability-restricted and trading-disabled.
- Consequences: API credentials are present in the native process memory while authenticating and are transmitted only to the fixed official DEMO HTTPS endpoint. This local trust boundary is not appropriate for remote or multi-user clients. REST session authentication does not establish streaming or trading readiness.
- Verification: Official Capital.com API documentation and the existing backend adapter/specification were inspected. Hosted macOS build/XCTest and real provider authentication remain pending.


## EDL-018 — Market Explorer provider DTO and presentation boundary

- **Date:** 2026-11-18
- **Status:** Implemented on PR #33 branch; exact-head hosted CI pending.
- **Decision:** Keep provider JSON DTOs private to the Capital.com/backend infrastructure adapter. Map them into provider-independent market-data semantic models before exposing results to the application-facing `MarketSearchClient` port. The ViewModel must receive that port by dependency injection and must not construct a production HTTP client.
- **Rationale:** Prevent provider schema changes from leaking into SwiftUI and presentation state, preserve a replaceable adapter boundary, and keep production dependency selection in the application composition root.
- **Compatibility:** Preserve the existing DEMO-only provider/environment validation, 100-character search bound, backend-connected gate, stale-search generation checks, and user-visible status behavior.
- **Verification:** Added unknown connection-state rejection coverage and retained DTO mapping, stale result, query bound, and disconnected-state tests. Exact-head CI pending.


## EDL-019 — Shared actor-safe URLSession request executor

- **Date:** 2026-11-18
- **Status:** Implemented on PR #33 branch; exact-head hosted qualification pending.
- **Decision:** Use one shared `URLSessionRequestExecutor` infrastructure type for actor-isolated broker and market-data clients. The executor owns one immutable URLSession reference, is explicitly `@unchecked Sendable` based on URLSession's documented thread-safety, and calls the async API with `delegate: nil`.
- **Rationale:** Avoid repeating the Swift 5.8 non-Sendable URLSessionTaskDelegate workaround in each service and keep transport execution outside presentation actors.
- **Session policy:** Market Explorer uses an ephemeral URLSession with cookie storage and URL cache disabled. The caller can inject a URLSession for deterministic URLProtocol tests.
- **Verification:** URLProtocol tests cover status and markets GET routes, query encoding, no-store headers, 503/500 mapping, and transport failure mapping. Exact-head CI pending.


## EDL-022 — Single backend broker credential and session authority

- **Date:** 2026-11-18
- **Status:** Required architecture decision; implementation pending.
- **Authority:** Library Broker Integration Q5 and Q6.
- **Decision:** One backend CMS and Broker Session Manager is the sole authority for broker credentials, Capital.com authentication, CST/X-SECURITY-TOKEN lifecycle, renewal, reconnect and session status. The macOS app is a secure credential-entry/management client, not an independent broker-session owner.
- **Current discrepancy:** PR #26 authenticates directly from Swift using Keychain credentials; PR #37 authenticates separately using backend environment credentials.
- **Target:** app-managed backend child process; 256-bit per-launch capability bootstrapped over private stdin/pipe; bearer authorization on local control endpoints; backend CMS with a Keychain-backed storage adapter/helper; environment credentials test-only.
- **Merge gate:** PR #37 must not be merged as completed broker integration until this architecture is implemented and DEMO-qualified. LIVE remains disabled.

## EDL-023 — Centralized broker connection and subscription orchestration

- **Date:** 2026-11-18
- **Status:** Partially implemented; remaining work tracked in ATP-BRK-003 / ATP-MKT-007.
- **Authority:** Library Broker Integration Q10.
- **Decision:** Centralize REST session lifecycle, authentication rate limiting, WebSocket lifecycle, subscription registry, priority allocation, recovery and observability. Distinguish REST request rate, authenticated session inactivity, WebSocket heartbeat/duration and instrument subscription capacity.
- **Implemented in unmerged PR #37:** shared WebSocket runtime, 40-instrument cap, deduplication, five-minute heartbeat, reconnect/backoff and quote-quality counters.
- **Pending:** sequential session-creation rate limit, scheduled REST keepalive, priority subscription allocation, account-switch restoration and connection utilization metrics.
- **Constraint:** Do not invent undocumented provider-wide REST or WebSocket connection limits.


## EDL-022 implementation addendum — 2026-11-18 (PR #55)

- **Status:** Partially implemented on unmerged PR #55; not accepted as a qualified broker integration.
- **Implemented:** backend `BrokerSessionManager` owns the provider credentials/session runtime; native Keychain credentials are handed over capability-authenticated loopback IPC; provider session tokens remain backend-only; status/connect/disconnect APIs are bounded and sanitized.
- **Session policy:** enforce the Library-documented one session-creation request per second per API key. Preserve distinct HTTP 401 (authentication), 403 (permission), and 429 (rate limit) semantics. Do not map all provider failures to invalid credentials.
- **Account switch:** disconnect the stream only after the manager accepts a session replacement attempt; a rate-limited request must not tear down the existing stream.
- **Logout:** attempt broker REST logout even if stream shutdown reports an error. Drop the credential-bearing runtime reference in all logout outcomes; never return a success response when the complete shutdown was not confirmed.
- **Remaining:** exact-head CI; ordered PR #51/#54/#55 integration; owner-Mac Keychain persistence and process lifecycle; authenticated Capital.com DEMO acceptance; stream recovery/reconciliation qualification. LIVE and dealing remain disabled.


## EDL-022 security qualification addendum — 2026-11-18

- **Status:** Partially implemented; confidentiality qualification remains open.
- **Finding:** The current app-to-backend credential request uses authenticated plain HTTP to `127.0.0.1`. The per-process 256-bit bearer capability provides authentication and route authorization; it does not encrypt the credential body.
- **Decision:** Do not treat loopback binding or bearer authentication as payload confidentiality. Keep PR #55 and dependent broker integration blocked from security-qualified merge until credential transfer uses a private local IPC channel with appropriate process/peer controls, or the relevant authority explicitly accepts a documented same-host threat boundary.
- **Preferred implementation direction:** private stdio RPC between the supervised parent and backend child, or a protected Unix-domain socket, for credential payloads. Retain capability-authenticated HTTP for non-secret local control and market-data operations unless a broader redesign is justified.
- **Safety:** No credential was used in this batch. LIVE, dealing and trading remain disabled.


## EDL-029 official provider-limit verification addendum — 2026-11-18

Current official Capital.com sources were checked:
- https://open-api.capital.com/
- https://help.capital.com/hc/en-us/articles/6630830103058-Do-you-have-any-limitations-on-their-API
- https://help.capital.com/hc/en-us/articles/6630762294418-Which-kind-of-APIs-do-you-have

Verified limits: 10 REST requests/second per user; `POST /session` one request/second per API key; REST inactivity and WebSocket session duration/inactivity 10 minutes; application-level WebSocket ping at least once every 10 minutes; maximum 40 `marketData.subscribe` epics; DEMO `POST /positions` and `POST /workingorders` 1,000 requests/hour. Account switching through `PUT /session` interrupts WebSocket streaming.

Code reconciliation on the current broker-session/streaming stack:
- `CapitalDemoClient` shared request-start queue defaults to 100 ms (10 requests/second).
- `CapitalDemoRuntime` and `BrokerSessionManager` enforce at least 1,000 ms between session creation attempts.
- REST keepalive defaults to 5 minutes and rejects intervals at/above 10 minutes.
- `CapitalDemoStreamingRuntime` sends application-level `destination: "ping"` every 5 minutes and caps the shared instrument set at 40.
- Future account-switch support must invalidate/reconnect the WebSocket and re-subscribe after the broker confirms the active account. Future OMS must enforce endpoint-specific DEMO quotas; no dealing routes are part of this work.

This verifies documentation-to-code alignment only; it does not claim real DEMO authentication or live streaming. Full evidence: `SESSION_2026-11-18_052_CAPITAL_API_LIMITS_VERIFICATION.md`.


## EDL-030 — Live quote transport and Market Explorer boundary (2026-11-18)

The native Market Explorer consumes broker-normalized market data through a local, bearer-capability-authenticated SSE endpoint. The transport is for non-secret market-data events only; broker credentials must not be placed in this HTTP stream. The native client uses an ephemeral URLSession, no cookie storage/cache, loopback-only request validation, bounded event payloads, provider timestamp/freshness validation, and a 40-epic ceiling.

The UI must preserve the shared ATHEER design-token system, responsive layouts and accessibility. It may display timestamped DEMO quotes and quality state but has no order-intent, OMS, execution, or strategy authority. Search results remain metadata-only. A future chart engine may consume this stream through a separate market-data abstraction; it must not turn this UI into an execution path.

This decision does not resolve the separate P0 broker-credential confidentiality issue: credential handoff remains outside the HTTP loopback API and requires private IPC (e.g. stdio RPC or a protected Unix-domain channel) before secure authenticated broker connectivity is qualified.


## EDL-031 — Broker credentials use private Unix-domain IPC (2026-11-18)

Broker API key, identifier and password must never be sent in a loopback HTTP request body, command-line argument, or child-process environment. Credential connect/disconnect operations use a per-process Unix-domain socket created by the native supervisor. The parent directory is mode 0700, the socket is mode 0600, the request includes the existing 256-bit process capability, and the backend performs constant-time capability validation. The socket protocol is bounded, DEMO-only, action-allowlisted and returns sanitized status only.

The native supervisor owns the socket directory lifecycle, validates the Darwin socket-path limit, verifies socket permissions before reporting readiness, and removes the directory only after confirmed child termination. HTTP remains capability-authenticated for non-secret status and market-data operations; HTTP credential connect/disconnect routes are removed.

This decision supersedes the earlier open design choice between private stdio RPC and a protected Unix-domain channel. UDS is selected because it separates credential transport from readiness/log output and has explicit filesystem permissions and lifecycle ownership. LIVE execution remains disabled.


## EDL-032 — Centralized Capital.com 429 recovery (2026-11-19)

The shared Capital.com REST client remains the single process-level request scheduler. In addition to its 100 ms request-start spacing and independent one-second session-creation throttle, it observes HTTP 429 responses and applies one shared cooldown to subsequent REST requests.

- Prefer numeric-seconds or HTTP-date `Retry-After` values; bound the server-directed delay to 60 seconds.
- If the header is absent or invalid, use exponential full jitter.
- Limit each request to three 429 retries.
- Apply a fresh 10-second timeout to each network attempt, separately from the server-directed wait.
- Do not automatically retry network timeouts or other uncertain transport failures.
- Future order/dealing methods must not inherit this retry behavior without explicit idempotency, acknowledgement, and reconciliation semantics. A 429 refusal is distinct from an ambiguous execution timeout.

This decision governs only the current read-only Capital.com DEMO adapter and session operations. It does not introduce OMS or broker-dealing capability. Evidence and qualification scope: `SESSION_2026-11-19_070_SERIALIZED_DISCONNECT_AND_429_RECOVERY.md`.
