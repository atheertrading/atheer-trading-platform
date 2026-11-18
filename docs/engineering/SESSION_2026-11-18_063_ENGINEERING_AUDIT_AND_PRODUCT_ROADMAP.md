# Session 063 — Engineering Audit, Source Reconciliation and Product Roadmap

**Date:** 2026-11-18  
**Workstream:** ATP-ENG-063  
**Repository:** `atheertrading/atheer-trading-platform`  
**Audit base:** `main` `31e3e5547c9204645427ec56426e741d4bcfa955`  
**Working branch:** `docs/atp-eng-063-roadmap-audit` (child of PR #70 head `7d3aaea2b5405d6bba3f5d9ced8811c50d62b469`)  
**Tracking issue:** https://github.com/atheertrading/atheer-trading-platform/issues/77

## Objective

Review the current GitHub implementation, exact branch ancestry and CI evidence against the Library's product vision, Q&A repository, consolidated architecture records, Mermaid source archives, engineering standards and UI delivery plan. Establish the next controlled delivery sequence without overstating implementation or qualification.

## Sources reviewed

### GitHub

- Root `AGENTS.md`, README, AI-agent navigation and developer/toolchain references.
- Current continuity, task register and implementation-status records on the broker/chart branch.
- `ATP-ENGINEERING-REVIEW-2026-11-18.md`, including EDL-024 through EDL-032.
- PR metadata, exact heads, changed-file inventories, ancestry comparisons, workflow jobs and the failed PR #53 Intel build log.
- Source and tests for supervisor lifecycle, private credential IPC, Capital.com DEMO REST/streaming, historical normalization and native chart workspace.
- IPDS foundation PR #69, screen blueprint PR #73 and UI issue #72.

### ChatGPT Library

- 517 Markdown Q&A records in `Atheer Q&A Repository.zip`; inventoried the archive and examined relevant vision, multi-user, supported-instrument, broker, risk, order lifecycle, agent-authority and UI questions.
- 47 formal architecture/engineering records in the consolidated archive, for 564 Markdown records total; examined the implementation sequence, security, data, broker, risk, OMS, execution, AI and release-gate records.
- The two 52-diagram Mermaid exports were compared by filename and SHA-256: all 52 `.mmd` files are byte-identical. They are historical source material and are not automatically the current canonical diagram set.
- The current Library's `10_ENGINEERING_EXECUTION` folder has no consolidated product/engineering roadmap. The five-year vision is strategic direction; issue #72 is a UI-only delivery plan.
- The Library's historical archive is at the Library root, outside the `AtheerTradingPro` folder. Earlier statements that it was absent from the Library were caused by a folder-scoped search.

### External broker contract

Reviewed the current official Capital.com Open API reference and Help Center API overview. Confirmed the documented session, REST-rate, session-creation, streaming-subscription and order-confirmation semantics. This is documentation verification only; no account credentials or live provider session were used.

## Product and architecture assessment

The product direction is a broker-agnostic, multi-asset professional Trading Operating System. Capital.com is the initial broker, not the permanent architectural boundary. Potential asset classes include FX, metals, energy, indices, equities, digital assets and agricultural commodities, but an instrument is tradable only after broker/account/jurisdiction capabilities and its contract specification are verified.

The five-year vision is organized as strategic horizons:
1. Professional core.
2. Intelligence ecosystem.
3. Scalable multi-user and multi-broker infrastructure.
4. Professional/team/institutional capabilities.
5. Integrated trading-intelligence ecosystem.

These are strategic horizons, not delivery-date commitments. The initial deployment remains owner-managed and controlled; multi-user, web and institutional capabilities are future stages.

The governing implementation sequence in the consolidated architecture is:

`M0 Source Reconciliation → M1 Requirements and Architecture → M2 Security and Persistence → M3 Data OS → M4 Capital.com Integration → M5 OMS and Risk Engine → M6 Execution Gateway → M7 Strategy and Position Management → M8 Intelligence and Research → M9 Desktop and Web Integration → M10 Integration and DEMO Validation → M11 Release Readiness → Owner Gate: LIVE Authorization`.

The critical path is source reconciliation, requirements, architecture, security/persistence, market data and broker integration, RiskEngine and OMS, Execution Gateway, position management, end-to-end DEMO validation and release readiness. UI, research, historical testing and AI can progress in parallel only within their dependencies; none may establish an independent execution path.

## Verified repository and branch state

Observed `main` head: `31e3e5547c9204645427ec56426e741d4bcfa955`.

### Broker-to-chart stack

| PR | Head (short) | Current state | Qualification observation |
|---|---|---|---|
| #51 | `1e312352` | Open, ready | Recorded checks passed; branch is 20 ahead / 4 behind current main |
| #52 | `426b3a9c` | Open, Draft | Backend, hygiene and Intel passed; Apple Silicon cancelled |
| #53 | `37a085c5` | Open, Draft | Intel macOS compile failure; #56 contains source corrections |
| #56 | `493e91b0` | Open, Draft | Full exact-head Intel/Apple Silicon qualification pending |
| #55 | `d7957bc5` | Open, Draft | Per-test 30s and backend-job 15m bounds added; fresh run did not complete qualification |
| #64 | `a3380652` | Open, Draft | Exact-head qualification pending |
| #66 | `519cb86b` | Open, Draft | Private UDS credential IPC present; lifecycle review findings recorded below |
| #67 | `2506aebe` | Open, Draft | Cached-quote replay freshness correction; 5s stale classification is not a RiskEngine policy decision |
| #68 | `b4ca620d` | Open, Draft | Authenticated historical DEMO normalization; qualification pending |
| #70 | `7d3aaea2` | Open, Draft | Authenticated historical chart workspace; qualification pending |

Immediate parent/child comparisons from #52 through #70 show zero commits behind at their declared stack boundaries. The root #51 branch is nevertheless 4 commits behind current `main`; the four intervening main changes are engineering-review/continuity/status/task documentation. This root drift must be reconciled and propagated before integration.

### Separate IPDS/UI stack

- PR #69: head `fa195a6e`, 6 ahead / 0 behind current `main`; Draft. Intel, backend, repository hygiene, CodeQL and Mermaid completed successfully on its recorded run; Apple Silicon was cancelled.
- PR #73: head `6591283c`, 10 ahead / 0 behind PR #69; Draft. Backend and repository hygiene passed; Intel and Apple Silicon remained queued.
- PR #70 is 422 commits ahead / 10 behind PR #69. The chart/data and IPDS/UI branches are not integrated.
- Shared Swift files include `ATHEERTradingProApp.swift` and `ATHEERTradingProTests.swift`.
- Mermaid identifier collisions exist: PR #68 uses diagram 10 for historical normalization; PR #69 uses 10 for workspace lifecycle and 11 for UI order-intent authorization; PR #70 uses 11 for authenticated historical chart workspace. Renumbering and catalogue reconciliation are required before merge.

### PR dispositions recorded during this audit

- PR #52 and #53 were returned to Draft because the exact-head qualification is incomplete.
- PR #57 was closed as superseded by PR #66. Its bounded-shutdown implementation, tests and session record are preserved in #66; its branch and history were not deleted or rewritten.
- Review comments were added to PRs #52, #53, #57, #67, #69 and #70.
- A blocking lifecycle review was submitted to PR #66.
- No PR was merged into `main`.

## Implementation reality

### Present on open PR branches — qualification pending

- Managed local backend and dynamic loopback port/readiness.
- Per-launch capability-based local API authorization.
- Private Unix-domain socket for broker credential provisioning from the native app to the backend; no credential-bearing HTTP route in PR #66.
- One backend-owned Capital.com DEMO session manager.
- DEMO REST market search, live streaming, reconnect/status handling and historical price retrieval.
- Bid/Ask historical OHLC normalization, timestamp/provenance metadata, duplicate handling and observed-gap reporting.
- Native historical chart view with timeframe and Bid/Ask selection.
- Workspace/Command Center and IPDS appearance foundation on separate PR branches.

### Not implemented or not verified

- Full broker-independent BIDCMS instrument catalog, market-navigation taxonomy and complete per-instrument contract/capability model.
- Durable trading database, migrations, audit/event persistence and recovery.
- Canonical OrderIntent/Order/Fill/Position contracts and durable order journal/outbox.
- Central RiskEngine, OMS, Execution Gateway, broker dealing adapter and broker confirmation/reconciliation.
- Account/portfolio/position management and emergency trading controls.
- Strategy lifecycle, deterministic backtesting, simulation and forward validation.
- Atheer Mind OS, Agent OS, Skill OS and model gateway.
- Multi-broker, multi-user, team, web and institutional implementation.
- Owner-Mac build, Keychain restart, visual/accessibility/RTL QA, authenticated DEMO session, market-data soak, or end-to-end DEMO order lifecycle.

The reviewed API server exposes broker-session status, market-data status/stream, market search and historical data. It does not expose order/position dealing routes or a RiskEngine/OMS/Execution Gateway implementation.

## Blocking source-review findings

### PR #66 — managed session lifecycle

The private UDS transport is a meaningful improvement over credential-bearing HTTP, but the source review found four lifecycle issues requiring correction before qualification:

1. `runBoundedShutdownStep` uses `Promise.race`; timeout rejects the wrapper but does not cancel the underlying action. The next teardown step can overlap with the timed-out operation.
2. Per-step limits total 4s + 7s + 7s + 4s = 22s, exceeding the 20s process hard deadline.
3. UDS `close()` destroys sockets and waits for server closure but does not track/drain asynchronous `handleRequest` promises. An in-flight connect may continue while stream and broker teardown starts.
4. Concurrent UDS connect/disconnect/account-replacement requests are not serialized at the broker-session lifecycle boundary.

These findings were submitted as a PR #66 review and are tracked in issue #77. They must be fixed with deterministic overlap, drain, cancellation and account-switch tests.

### Market-data semantics

The current stream implementation classifies a quote as stale after 5 seconds and sets `automatedDecisionsAllowed=false`. The recorded owner baseline describes 5 seconds as normal, blocks new automated entries above 10 seconds and classifies stale above 15 seconds. The stream threshold is a conservative display/data-quality behavior, not an approved RiskEngine limit. Reconcile the semantics before risk wiring.

### Capital.com contract alignment

The reviewed REST/stream implementation aligns with the documented DEMO session and market-data path, including the 10 req/s general REST limit, one session-creation request per second, 10-minute session inactivity and 40-instrument streaming cap. The API key model must not be treated as a read-only credential guarantee; read-only behavior is enforced by the adapter's exposed operations and the absence of dealing routes.

For future order placement, a broker acknowledgement/deal reference is not a fill. The adapter must query the documented confirmation endpoint and reconcile broker orders, fills, positions and account state before the OMS marks execution complete or retries an ambiguous request.

## UI/IPDS assessment

Issue #72 defines a 12-screen experience and a delivery order: Shell/Navigation, Command Center, Markets, Charts & Analysis, Trading + Risk + Positions, then the remaining intelligence, strategy, automation, analytics and administration areas.

The corrected estimate is 85–140 engineer-days for UI-only work. It excludes substantial backend/domain work, broker qualification, owner-review latency and release certification. High-fidelity screen assets remain pending; the committed SVG is a structural shell wireframe. Generated composite concepts are inspiration only and their sample financial values must never be used as data.

## Actions and next work

The complete acceptance sequence is tracked in [ATP-ENG-063 issue #77](https://github.com/atheertrading/atheer-trading-platform/issues/77):

1. Reconcile current `main` into the #51 root branch and propagate history-preserving merges through the stack.
2. Complete #53/#56 supervisor compile correction and exact-head Intel + Apple Silicon qualification.
3. Correct PR #66 lifecycle serialization, UDS request draining and shutdown deadline behavior.
4. Re-run backend, Intel, Apple Silicon, repository hygiene, CodeQL, Local Sync Safety and Mermaid checks on exact current heads.
5. Integrate PR #69/#73 with the chart stack; resolve shared Swift changes and Mermaid identifiers.
6. Complete broker-independent instrument discovery/specification and market-data quality gates.
7. Implement the governed DEMO order vertical slice: OrderIntent → validation → RiskEngine → OMS → Execution Gateway → Capital.com adapter → deal confirmation → reconciliation.
8. Add strategy/simulation, portfolio/position intelligence and AI decision support only after their dependencies and authority contracts are satisfied.
9. Complete owner-Mac, Keychain, DEMO session, soak, visual/accessibility/RTL and end-to-end DEMO qualification.

## Safety and verification boundary

- `CAP_ALLOW_TRADING=false` remains unchanged.
- No broker credentials, API keys, tokens or provider sessions were used.
- No DEMO or LIVE orders were submitted.
- No production dealing or deployment action was performed.
- No local Mac Terminal/Xcode session is connected; no local build or runtime result is claimed.
- No LIVE activation is authorized by this roadmap. The Owner Gate for LIVE remains separate and explicit.
