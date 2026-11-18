# Engineering Session 050 — Broker Test Fixture Lifecycle and Stack Revalidation

**Date:** 2026-11-18  
**Batch:** ATP-2026-11-18-050  
**Repository:** `atheertrading/atheer-trading-platform`  
**Branch:** `feat/capital-demo-session-streaming-ipc`  
**Exact head at report creation:** `e3d5ff4a44a8ac4075603ce93887c27ba6dd164f`  
**Pull request:** [#55 — Centralized Capital.com DEMO broker-session IPC integration](https://github.com/atheertrading/atheer-trading-platform/pull/55)

## 1. Objective

Harden the backend test lifecycle so scheduled keepalive timers and streaming sockets cannot outlive their test fixtures; revalidate the stacked PR ancestry and exact-head CI; reconcile the active broker work with the owner-curated Library Q&A and Mermaid source catalogue.

## 2. Implementation

### Backend test fixture lifecycle

File: `services/api/test/market-data-runtime.test.mjs`

- Added tracked fixture factories for `CapitalDemoRuntime` and `BrokerSessionManager`.
- All 14 runtime constructions and 7 manager constructions in the test file now pass through the tracked factories.
- The suite teardown disconnects all tracked managers and runtimes using `Promise.allSettled`, then closes the shared API test server and its remaining connections.
- This closes a test-harness lifecycle gap: individual tests had explicit cleanup in several paths, but failed assertions or newly added tests could leave a connected runtime's five-minute keepalive timer alive. Teardown now owns cleanup independently of individual assertion paths.
- Existing streaming test teardown in `market-data-streaming.test.mjs` also tracks streaming runtime instances and disconnects them after the suite.

This change does not weaken assertions, increase test timeouts, or disable keepalive behavior in production code.

## 3. Library source reconciliation

The following Library materials were inspected directly during this batch:

- **Atheer Q&A Repository — Q38.1, main navigation groups:** confirms the 12 task-oriented product groups, from Command Center and Markets through Trading & Execution, Positions & Portfolio, Risk Management, Analytics, Atheer Mind OS, and System & Administration.
- **Atheer Q&A Repository — Q39.1, final visual identity:** records IPDS v1.0 and the institutional design principles of clarity, precision, restrained ornament, semantic financial colors, and operational status clarity.
- **Broker Integration Q7/Q8/Q9:** covers token renewal, termination classification/recovery, and provider rate limits. In particular, HTTP 401, 403 and 429 must remain distinct; WebSocket loss is not automatically REST-session loss; a network timeout does not prove authentication failure.
- **Codex knowledge-base catalogue ATP-MER-001:** lists five Mermaid source diagrams:
  - `system-context.mmd`
  - `target-trading-boundaries.mmd`
  - `market-data-pipeline.mmd`
  - `ai-order-boundary.mmd`
  - `backtest-pipeline.mmd`

The Mermaid catalogue marks these as proposed target context/pipelines and states that syntax validation is pending. They are used as architecture guidance, not as evidence of deployed topology. The target trading boundary continues to require human, strategy, and AI intents to pass backend validation, centralized RiskEngine, OMS, Execution Gateway, broker confirmation, and reconciliation. This batch does not implement dealing or bypass those controls.

## 4. Exact repository and PR state

| PR | Head | Base | State at inspection |
|---|---|---|---|
| [#51](https://github.com/atheertrading/atheer-trading-platform/pull/51) | `1e312352696bcc5e18ba00a15dc426d37aa26c5a` | `main` at `3bb2f0b68c11eff019bbd88ce09cf3b7155b9ea4` | Open, draft; capability IPC |
| [#54](https://github.com/atheertrading/atheer-trading-platform/pull/54) | `37a085c5a1c5cf22368518dd1550dbbd2facbd53` | PR #51 branch at `1e312352696bcc5e18ba00a15dc426d37aa26c5a` | Open, draft; managed native backend |
| [#56](https://github.com/atheertrading/atheer-trading-platform/pull/56) | `493e91b010c5637f37a3bc270c99995da3f6d67d` | PR #54 branch at `37a085c5a1c5cf22368518dd1550dbbd2facbd53` | Open, draft; Swift actor-isolation corrections |
| [#55](https://github.com/atheertrading/atheer-trading-platform/pull/55) | `e3d5ff4a44a8ac4075603ce93887c27ba6dd164f` | PR #56 branch at `493e91b010c5637f37a3bc270c99995da3f6d67d` | Open, draft; broker session IPC integration |

All four PRs were reported mergeable by GitHub at the latest metadata inspection. Mergeability is not equivalent to passing checks or acceptance.

### Required stack integration order

Because each child PR targets its immediate parent branch, integrate from the top of the stack upward:

1. PR #55 into PR #56's branch.
2. PR #56 into PR #54's branch.
3. PR #54 into PR #51's branch.
4. Requalify the integrated PR #51 head, then merge PR #51 to `main`.

Do not merge PR #51 to `main` while the native supervisor and authenticated client remain outside its branch. Do not rebase or force-push shared branches.

## 5. Verification evidence

- Local Sync Safety run `44283628390` on exact head `e3d5ff4a44a8ac4075603ce93887c27ba6dd164f`: **passed**.
- CI run `44283635275` on the same exact head: at last inspection, Repository Hygiene was in progress/completing, Backend Toolchain had passed API type-check and was running API tests, and Intel x86_64 / Apple Silicon arm64 jobs were queued. No final-head API test, macOS build, XCTest, Release, or CodeQL pass is claimed.
- Prior PR #55 run `44282381870` was superseded by the exact-head run after additional fixture teardown hardening; it is not used as final qualification evidence.
- PR #56 run `44282183380` was cancelled after Backend Toolchain and Repository Hygiene passed; both macOS architecture jobs were cancelled. The exact PR #56 head therefore has no complete standalone macOS qualification yet.
- PR #54 run `44277867553` recorded an Intel Debug failure caused by Swift actor-isolation errors in the supervisor/runtime composition. The correction is present in PR #56 but still requires successful exact-head qualification.
- No local Mac/Xcode build, owner-workstation launch, visual/accessibility QA, Keychain restart test, or real Capital.com DEMO authentication was performed.

## 6. Current implementation boundaries

- Backend session manager owns provider credentials and REST session tokens in process memory; native app remains the persistent Keychain credential store.
- Credentials are handed to the backend only through the per-launch capability-authenticated loopback IPC path.
- REST keepalive is scheduled at five minutes; WebSocket subscription capacity is capped at 40 instruments.
- Market Explorer displays backend REST/streaming status and subscription count, but does not yet subscribe to or render live quotes. Search results remain instrument metadata, not live quote data.
- No account balances, positions, orders, fills, or execution status are fabricated.
- LIVE authentication, dealing endpoints, and order execution remain unavailable. `CAP_ALLOW_TRADING=false`.

## 7. Next engineering action

After exact-head CI completes, resolve any remaining backend or macOS failures and integrate the stack in the order above. The next market-data vertical slice is authenticated native SSE subscription from selected instruments, with provider-independent quote models, source timestamps, sequence/duplicate validation, freshness state, cancellation, and truthful disconnected/stale UI states. It must remain read-only and must not expose dealing actions.

Owner-Mac launch, Keychain persistence/restart, accessibility/visual QA, and explicitly authorized real DEMO authentication remain separate qualification gates.


## 8. Mainline ancestry revalidation addendum

- Current main head at inspection: 31e3e5547c9204645427ec56426e741d4bcfa955.
- PR #51 head remains 1e312352696bcc5e18ba00a15dc426d37aa26c5a; merge base is 3bb2f0b68c11eff019bbd88ce09cf3b7155b9ea4.
- Comparison reports main four commits ahead and PR #51 twenty commits ahead (diverged). The four mainline commits are documentation-only: ATP-ENGINEERING-REVIEW-2026-11-18.md plus updates to IMPLEMENTATION_STATUS.md, PROJECT_CONTINUITY.md and TASK_REGISTER.md.
- The mainline engineering review introduces EDL-024 through EDL-032, including single broker-session authority, private IPC trust boundary, canonical multi-asset domain, broker-truth reconciliation, market-data quality/subscription governance, durable persistence/audit, bounded AI permissions and release qualification.
- GitHub reports PR #51 mergeable at the latest metadata inspection. This is not permission to skip merge-base verification or exact-head CI. Preserve history; do not force-push or rewrite the branch. After the child stack is integrated upward, revalidate the final PR #51 diff against current main and ensure the four mainline documentation updates remain present in the resulting merge.
