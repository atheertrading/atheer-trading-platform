# ATHEER Trading — Implementation Status

**Snapshot date:** 2026-11-17  
**Evidence scope:** New public repository inspection and available historical project summaries.

## Status definitions

- **VERIFIED:** directly inspected or tested with recorded evidence.
- **OWNER-REPORTED:** stated by the project owner; not independently verified.
- **HISTORICAL:** recorded in earlier project material; requires revalidation.
- **PROPOSED:** design direction only.
- **NOT IMPLEMENTED:** no implementation evidence in the inspected scope.
- **UNKNOWN:** insufficient evidence to classify.

## New repository

| Item | Status | Evidence |
|---|---|---|
| Public repository exists | VERIFIED | GitHub repository metadata |
| Default branch is `main` | VERIFIED | GitHub repository metadata |
| Initial commit | VERIFIED | `505c06c88c2eaaf819b202d5b2687a9d4ee99bb9` |
| Initial README | VERIFIED | Fetched from `main`; contained an incomplete personal-profile description |
| Root `AGENTS.md` before bootstrap | NOT PRESENT | GitHub contents lookup returned not found |
| Application source in this repository | NOT IMPLEMENTED | Initial commit contained README only |
| Backend source in this repository | NOT IMPLEMENTED | Initial commit contained README only |
| Trading engine in this repository | NOT IMPLEMENTED | Initial commit contained README only |
| Capital.com integration in this repository | NOT IMPLEMENTED | Initial commit contained README only |
| Production IPDS in this repository | NOT IMPLEMENTED | Initial commit contained README only |
| CI workflows in this repository | NOT IMPLEMENTED | No workflow files in inspected initial commit |
| Bootstrap governance documents | IN PROGRESS | Created on `engineering/bootstrap-governance`; PR/merge not yet verified |

## Historical project implementation context

Earlier project records describe SwiftUI app work, workspace models, theme/design-token files, and initial architecture scaffolding in other project locations. They also record Capital.com UI planning and a prior engineering repository. These are **HISTORICAL** references, not verified contents of this new repository.

Historical engineering notes mention macOS 13.7.8, Xcode 14.3.1, and Swift 5.8.1 on an Intel iMac. Current environment and compatibility remain UNKNOWN until rechecked.

## Target capabilities — not implementation claims

- Authentic broker market-data infrastructure.
- Instrument metadata and market-data normalization.
- Quantitative analysis and configurable strategies.
- Centralized RiskEngine.
- Durable OMS, Execution Gateway, and broker reconciliation.
- Portfolio, positions, balances, and operational monitoring.
- AI model gateway, agent runtime, and multi-agent orchestration.
- Professional macOS application and IPDS.
- Backtesting and isolated simulation.
- Security, audit, observability, and production qualification.

## Verification policy

Every status change to VERIFIED must cite a commit, file path, test run, build log, integration result, or other reproducible evidence. Mark owner-reported or historical evidence explicitly. Never infer operational broker connectivity or financial correctness from UI presence, mock tests, generated source, or successful compilation alone.

## Bootstrap pull request evidence

- Branch: `engineering/bootstrap-governance`
- PR: https://github.com/atheertrading/atheer-trading-platform/pull/1
- PR head at creation: `f9cb4d3f8acb413f5422aab96892fd9583747958`
- Files: 11 changed (documentation and repository configuration only).
- Verification: all 11 expected paths fetched successfully from the branch.
- PR state at last inspection: open, not merged.
- No application build, unit test, integration test, or runtime qualification was performed or claimed.


## Platform foundation branch — 2026-11-16

The branch build/platform-foundation (PR #2) adds:
- XcodeGen project specification targeting macOS 13.0 and bundle identifier com.atheertrading.desktop.
- Minimal SwiftUI application shell and an XCTest target.
- Local doctor/build/test scripts and developer setup instructions.
- GitHub Actions CI, CodeQL workflow, Dependabot, CODEOWNERS, PR template, and Markdown lint configuration.
- AI navigation guide, repository architecture/layout, and repository topology decision EDL-004.

Status: committed to the feature branch; PR #2 is open and not yet merged. GitHub CI has not yet been observed. The Xcode project is generated from project.yml during CI/local setup. No local Xcode build, runtime test, broker integration, or trading capability is verified. The shell intentionally has no broker connection or order execution.

Local synchronization instructions are in docs/development/PULL_REQUEST_AND_LOCAL_SYNC.md. The new repository is distinct from the earlier atheer-trading-pro local checkout; do not overwrite or repoint that checkout as part of cloning this repository.


Toolchain compatibility correction: XcodeGen is pinned to 2.36.1 and built from source using the selected Xcode-provided Swift compiler. The current XcodeGen/Homebrew formula line requires Xcode 15.3 or later and is not suitable for the historical Xcode 14.3.1 workstation. Homebrew is therefore optional, not a required bootstrap dependency. The local installer and both CI workflows use the same pinned generator version. This compatibility correction is committed to the open platform foundation PR; local compilation remains unverified.


The first complete repository-hygiene run reached Markdown lint and reported 82 formatting-only findings across 22 historical and new Markdown files. The project has a temporary compatibility lint baseline that keeps the remaining default rules active while M00-018 normalizes legacy formatting and re-enables the spacing/link rules. The backend-toolchain job passed Node.js 24 validation. The hosted macOS build/test job is still pending; no Xcode build/test pass is claimed.


Final toolchain pin: XcodeGen 2.36.1 is built from immutable upstream commit 26e817b2deca1ceb9fdebfa963b86311fef3d05c; the upstream Package.resolved locks its dependency graph. The installer verifies the source SHA and records it beside the installed binary. Node.js 24 is selected by .nvmrc and CI consumes that file. Local toolchain installation and Xcode build/test remain unverified.


CI resource optimization: Swift CodeQL initialization and analysis now run inside the same macOS job as Xcode build and XCTest, avoiding a second macOS runner allocation. The standalone CodeQL workflow analyzes GitHub Actions configuration on Ubuntu. This preserves Swift static analysis while reducing duplicate macOS runner demand.


## Current verified correction — 2026-11-16

This section supersedes earlier status text in this file that says platform foundation PR #2 is open or that its hosted CI has not run.

- Platform foundation PR #2 was squash-merged to `main` at `83e524e35a7f167abf2f8d11838db6af63444f95`.
- Hosted PR checks passed before merge. No post-merge run is claimed here.
- The repository contains a reproducible XcodeGen macOS app foundation and CI configuration. Local Mac/Xcode qualification remains pending.
- The active documentation branch `docs/architecture-diagram-baseline` contains eight canonical Mermaid source diagrams, a source inventory, an extraction utility, a Mermaid render workflow, and a session recovery record. The branch has not yet been merged or CI-qualified.
- The Library archive contains 31 Mermaid-bearing Markdown documents with 52 fenced Mermaid blocks. The eight canonical diagrams are newly authored current baselines; they do not replace the 52 historical source blocks.
- No production broker integration, end-to-end trading execution, or LIVE trading capability is established by these documentation changes.

## Phase 2 Xcode configuration addendum — 2026-11-16

This addendum is the latest status for the Xcode configuration work and supersedes earlier statements above that do not reflect the current Phase 2 branch.

**Status: IN PROGRESS — hosted CI passed on the current review head; local Mac verification remains pending.**

- Inspected current `main` project configuration: XcodeGen project `ATHEERTradingPro`; bundle ID `com.atheertrading.desktop`; display name `ATHEER Trading Pro`; macOS 13.0; Swift 5 language mode; generated Info.plist; hardened-runtime build flag; unsigned build; one app target, one basic XCTest target, scheme `ATHEERTradingPro`.
- Branch: `build/phase-2-xcode-configuration`.
- `project.yml` now defines explicit Debug and Release settings, targeted Swift concurrency diagnostics, standard architecture selection, organization metadata, and build diagnostics.
- CI now inspects generated schemes, builds Debug, runs XCTest, and builds Release on the existing Intel macOS runner.
- `DEVELOPER_SETUP.md` documents configuration policy and the known signing, sandbox, architecture, and local verification limitations.
- Session record: `docs/engineering/SESSION_2026-11-16_011_PHASE_2_XCODE_CONFIGURATION.md`.

**Hosted verification:** PR #8 CI passed on head `44f2262f9af95a789317fea36a2c432cbad04114`: XcodeGen installation, project generation, generated-scheme inspection, Debug build, XCTest, Release build, Swift CodeQL, backend toolchain, and repository hygiene. The local Xcode 14.3.1 workstation has not been freshly inspected or tested. Hosted Intel CI does not qualify Apple Silicon/arm64. Hardened-runtime settings do not establish signed/notarized status. No app sandbox, entitlements, icons, UI-test target, or package dependency has been invented.

Phase 1 remains IN PROGRESS under the owner's explicit authorization to proceed with Phase 2 as a sequencing exception. Main-branch ruleset enforcement, local Git author/authentication, and repository-level Actions/security settings remain open.


## Backend health vertical slice — ATP-2026-11-16-012

**Status: IN PROGRESS — implementation and isolated-container tests completed; GitHub CI and local Mac verification pending.**

- Branch: feat/backend-health-vertical-slice.
- Added a private Node.js 24 / TypeScript API package under services/api with no runtime package dependencies.
- Runtime configuration defaults to 127.0.0.1:4100 and rejects non-loopback host configuration and invalid ports.
- GET /health/live reports process liveness only.
- GET /health/ready returns HTTP 503 while persistence and broker adapters remain unconfigured; trading is explicitly disabled.
- Unknown routes return 404; non-GET requests to known health routes return 405.
- Added six tests for health responses, fail-closed readiness, method/path handling, and runtime configuration.
- Added API contract documentation, package setup documentation, Makefile command, and Node 24 CI typecheck/test steps.
- Isolated verification in the available Linux container: TypeScript 5.8.3 build and strict typecheck passed; Node.js 22.16.0 tests passed 6/6 against compiled JavaScript. A prior GitHub run on the previous revision passed npm ci, strict typecheck, and all six tests on Node.js 24.22.2; repository hygiene and GitHub Actions CodeQL also passed. The macOS build job remained queued. This commit changes TypeScript execution to compile-first and requires a fresh hosted run.
- No database, broker, market data, account, order, strategy, RiskEngine, OMS, or Execution Gateway functionality is implemented by this slice.


## macOS backend health integration — ATP-2026-11-16-013

**Status: IN PROGRESS — implementation and isolated-container smoke test completed; hosted macOS CI and local Mac qualification pending.**

- Branch: feat/macos-backend-health-integration; PR #10.
- Added a dependency-injected URLSession client, payload decoder, view model, and backend status panel to the native macOS workspace.
- The app distinguishes API connectivity from platform readiness. HTTP 503 with a valid not_ready payload is displayed as API connected / platform not ready.
- Persistence and broker are shown as not configured; trading is shown as disabled. No order controls or broker connection were added.
- Four XCTest cases cover payload mapping, inconsistent HTTP status rejection, connected-but-not-ready state, and disconnected state.
- Swift 6.2.1 Linux Foundation/URLSession typecheck and Swift-to-Node API smoke test passed. These are not Xcode/macOS acceptance results.
- Current PR #10 hosted backend, repository hygiene, and CodeQL checks passed on its prior head; macOS build/test remained queued. The branch is being rebased onto current main, so fresh CI is required.
- Local Mac build, XCTest, and launch remain separate acceptance requirements.

## Safe local synchronization — ATP-2026-11-16-014

**Status: IMPLEMENTED AND VERIFIED IN ISOLATED GIT TESTS; LOCAL MAC EXECUTION PENDING.**

- PR #11 merged scripts/safe-sync.sh, bootstrap and doctor updates, deterministic DerivedData paths, app-run helper, Makefile workflows, local sync documentation, and a dedicated GitHub Actions safety workflow.
- The safety workflow passed. It verifies staged/unstaged and untracked preservation, backup branch and external backup, retained stash, clean fast-forward, origin mismatch rejection, and divergent-main refusal.
- No local user repository or workstation files were accessed or modified in this session.
- Actual local repository inspection, safe synchronization, Xcode project generation, build, XCTest, and application launch remain pending.


## Phase 0 engineering-state assessment — 2026-11-16

**Repository snapshot:** `atheertrading/atheer-trading-platform`, default branch `main`, verified main SHA `0dc062bb620a4afa93c60e5f060ee405846e3cbc` before PR #10 integration. PR #10 branch `feat/macos-backend-health-integration` was seven commits ahead and zero behind that main SHA.

**Implemented and merged:** governance baseline, XcodeGen macOS shell/configuration, Mermaid documentation baseline, backend health/readiness service, and safe local synchronization/bootstrap. Relevant merged PRs: #1, #2, #6, #7, #8, #9, #11; dependency PRs #3, #4, #5 also merged.

**Pending integration:** PR #10 adds the native macOS health panel, URLSession client, payload validation, view model, and five XCTest cases. Its original head `3b7bc500a7a2225b92409c5ab8da2fb3d6b56564` had successful hosted macOS Debug/Release build, XCTest, Swift CodeQL, backend toolchain, repository hygiene, GitHub Actions CodeQL, and safe-sync checks. Two subsequent documentation-only commits updated continuity and README status; fresh checks on the updated head are required before merge.

**Not implemented in the repository:** PostgreSQL persistence, authentication/authorization, broker adapter or Capital.com connectivity, market-data ingestion/streaming, instruments domain, RiskEngine, OMS, Execution Gateway, order lifecycle, reconciliation, portfolio/positions, strategy engine, backtesting/simulation, Model Gateway, agent runtime, production IPDS, and operational production deployment.

**Local qualification:** not performed in this assessment. Historical Xcode 14.3.1 / Swift 5.8.1 / macOS 13.7.8 and XcodeGen 2.36.1 are not freshly verified. The safe-sync workflow is not yet executed against the owner's local checkout. Do not mark M02-001, M02-005, or M02-006 complete on hosted evidence alone.


### PR #10 updated-head verification — 2026-11-16

The original implementation head `3b7bc500a7a2225b92409c5ab8da2fb3d6b56564` passed hosted macOS build/test/Release, Swift CodeQL, backend toolchain, repository hygiene, GitHub Actions CodeQL, and safe-sync checks. Fourteen documentation-only follow-up commits advanced the branch to `2a999fc8609ac833c94908ef219c347ec5137c95` (21 commits ahead of main, zero behind). At the latest check inspection, the dedicated safe-sync run had passed, CodeQL and Local Sync Safety were in progress, and the main CI workflow was pending. The updated head is not yet merge-qualified. Local Mac verification remains unperformed.


### PR #10 review hardening — 2026-11-16

The health client destination is fixed to loopback rather than accepting an arbitrary base URL. The readiness decoder rejects any `not_ready` response that reports trading enabled or a non-disabled trading status. An XCTest covers this contradictory-payload rejection. This code change is pending fresh hosted CI and local Mac verification.

- PR #10 review hardening: loopback endpoint is fixed; not-ready/trading-enabled contradictions are rejected; five XCTest cases cover the health decoder and view-model behavior.


## PR #10 current-head verification — 2026-11-17

**Status: HOSTED CI VERIFIED; PR OPEN; LOCAL QUALIFICATION AND REVIEW POLICY OUTSTANDING.**

- Exact inspected head: `bbe43218e4010442605befb9527907b0968dca4f`; base `main` at `0dc062bb620a4afa93c60e5f060ee405846e3cbc`; 26 ahead / 0 behind; 19 files changed.
- CI #116 passed repository hygiene, backend toolchain/typecheck/tests, XcodeGen generation, scheme inspection, macOS Debug, XCTest, Release, and Swift CodeQL. Local Sync Safety #46 and GitHub Actions CodeQL #116 passed.
- Fail-closed correction `ee92ac8c97e065db2cd774804c130499a1f49a4c` fixes the URLSession client to `127.0.0.1:4100` and rejects a `not_ready` payload that advertises trading enabled. Five health-focused XCTest cases are present.
- PR #10 remains open and unmerged. GitHub reports mergeable. No review submissions or requested reviewers were present at inspection. Branch protection is unverified because the endpoint returned 403 to the connected integration; rulesets returned an empty list.
- Actual owner-Mac build/test/launch and local app/backend health integration remain outstanding. M02-005 remains IN PROGRESS. Hosted CI is not physical workstation qualification.
- Coordination request posted on PR #10 for the macOS verification worker and review/maintainer worker. No local worktree was accessed and no protected trading/security/production settings were changed.


## 2026-11-17 — first native workspace/API connection implementation

**Status: IMPLEMENTED IN SOURCE; HOSTED MACOS CI PENDING; OWNER RUNTIME QA PENDING.**

- Branch: `feat/macos-workspace-api-connection`.
- PR: [#17](https://github.com/atheertrading/atheer-trading-platform/pull/17), based on PR #10 head `06bd496d957b6cd2f999209cf5dc83cae54251cf`.
- Exact PR head at this update: `45f38158b5c7e97ba1857804e585147ddf6c61cb`.
- Added native `NavigationSplitView` with two real destinations only: Workspace and API Connection.
- Added a dedicated read-only API Connection screen with initial check, manual refresh, separate process liveness/platform readiness, readiness HTTP status, dependency/trading fields, timestamps, and non-sensitive copy actions.
- Improved health error classification. Transport failure of the liveness endpoint, invalid liveness response, unexpected liveness HTTP status, and readiness-only failures are distinct. A successful liveness result is retained when readiness cannot be queried.
- Added selectable/copyable diagnostic values, contextual Copy, native text-editing commands, and focused XCTest cases.
- Exact-head repository hygiene, backend toolchain/typecheck/tests, and Local Sync Safety #76 passed. CI #129 macOS generation/build/XCTest/Release/Swift CodeQL was still running at XcodeGen installation; no result is inferred.
- Owner-provided curl evidence confirms the local API's expected HTTP 200 liveness and HTTP 503 not-ready behavior. The new app screen has not yet been visually verified on the owner's Mac.
- Full workspace/panel composition, settings window, IPDS token conformance, and application-wide clipboard audit remain incomplete. Issues #14 and #16 remain open.
- The repository contains no Capital.com adapter or credential-handoff API. No credential form or Keychain workflow is implemented; the current local health API is not a secure secret-transfer contract.
- No broker credentials, trading operations, risk controls, LIVE capability, or production configuration were changed.


## Workspace visual foundation — 2026-11-17

- PR #18 branch: `feat/macos-workspace-visual-foundation`, based on PR #17 head `75144f209e4a25d6cd10c2cd4571ac7e5070cffd`.
- Verified source head at qualification start: `331f424d6d1180569504b725cbcaa1eece41ed46`.
- Added `ATHEERDesignTokens.swift` with shared color roles, typography roles and spacing primitives based on the owner-provided palette and existing shell treatment.
- Added `WorkspacePanel.swift` with reusable panel, unavailable-state and status-tile components.
- Replaced the minimal Workspace home with an operational overview containing Market Watch, Chart Workspace, Account & Risk and Platform Health panels plus explicit market-data, broker, account and trading status.
- Added in-memory panel show/hide/reset and a direct API Connection navigation action. No persistence or docking behavior is claimed.
- Added test `testWorkspacePanelInventoryAndDefaultVisibility`.
- Added provisional product information architecture and IPDS foundation records. Full formal source and approval reconciliation remains pending.
- PR #17 workflow #132 passed on its exact head. PR #18 workflow #135 passed on exact source head `331f424d6d1180569504b725cbcaa1eece41ed46`: repository hygiene/Markdown lint, backend typecheck/tests, macOS Debug build, XCTest, Release build, and Swift CodeQL. Local Sync Safety workflow #90 passed.
- Local qualification branch `work/local-pr18-qualification` was created from the verified PR #18 head after confirming PR #10 → PR #17 → PR #18 ancestry. The preserved local PR #10 checkpoint remains at `06bd496d957b6cd2f999209cf5dc83cae54251cf`.
- Local environment discovery: Xcode 14.3.1, Swift 5.8.1 (x86_64 macOS target), XcodeGen 2.36.1; generated Xcode project exists. These are toolchain/project observations only; local build, XCTest, app launch, visual, accessibility, and multi-display qualification have not yet been performed.
- Workspace persistence, profiles, panel resizing/docking, multiwindow behavior, synchronized instrument/account context, and Settings remain unimplemented or unqualified. Formal IPDS source/approval reconciliation remains pending.
- No broker, credential, order, risk-policy, trading-permission, LIVE or production behavior was changed.


## PR #24 — Command Center and initial Workspace Engine — 2026-11-17

**Status: SOURCE IMPLEMENTED; EXACT-HEAD CI IN PROGRESS; OWNER MAC QUALIFICATION PENDING.**

- PR #24: `feat/macos-command-center-ipds`, based on PR #18 head `08d7b68ef14dbbce57752ce7b7f0215404a281cb`. PR remains open, draft, and unmerged.
- Latest source head when recorded: `59f5e363356f6e3cbac6e79df02c8d0b1d1a5a07`.
- Added `CommandCenterView.swift` and routed `WorkspaceHomeView.swift` to the Command Center. The view uses the existing ATHEER design-token roles, adaptive two-region/stacked layout, operational status, chart workspace, Market Watch, Account & Risk, Platform Health, workspace selection, and persisted panel visibility.
- Added `WorkspaceEngine.swift`: Codable workspace/profile/panel/layout models; stable UUID identity; schema-versioned snapshots; `WorkspacePersistence` protocol; UserDefaults persistence; observable state; create/select/rename; panel visibility; reset/save/restore; validation of schema, identities, profile references, panel identities, names, and layout bounds; recovery from invalid or unreadable persisted data.
- `WorkspacePanelID` now conforms to Codable. XCTest additions exercise persistence/restoration, visibility state, duplicate panel identity recovery, unsupported schema recovery, and corrupt-data recovery.
- Exact source diff at this checkpoint: five files changed (CommandCenterView, WorkspaceEngine, WorkspaceHomeView, WorkspacePanel, ATHEERTradingProTests). Local Sync Safety #207 passed. CI #174 was queued at last inspection; earlier CI runs were cancelled by newer commits and are not evidence for this head.
- No local Xcode build, XCTest, app launch, or visual QA has been performed for PR #24. Hosted CI does not replace owner-Mac qualification.
- No broker integration, market data, financial values, order execution, risk mutation, credentials, LIVE capability, or production settings were introduced.
- Not implemented: panel drag/drop/reorder, interactive resize, docking, full profile-management UI, independent windows, window restoration, and multi-display orchestration.


## ATP-MD-001 — Capital.com DEMO / Market Data (2026-11-17)

| Item | Status | Evidence |
|---|---|---|
| Capital.com DEMO REST adapter source | IMPLEMENTED — pending exact-head qualification | PR #25, CapitalDemoClient |
| Backend DEMO session runtime | IMPLEMENTED — pending exact-head qualification | PR #25, CapitalDemoRuntime |
| Local API market-data routes | IMPLEMENTED — pending exact-head qualification | PR #25, /market-data/* routes |
| Provider-neutral quote and freshness contracts | IMPLEMENTED — pending exact-head qualification | PR #25, normalized quote contract |
| Mocked adapter/runtime tests | PRESENT — exact-head execution pending | PR #25, services/api/test/market-data*.test.mjs |
| Authenticated Capital.com DEMO session | NOT VERIFIED | No owner credentials supplied; no live provider authentication attempted |
| Capital.com DEMO WebSocket endpoint | UNKNOWN / BLOCKING | Official public API page does not explicitly identify a DEMO streaming hostname |
| Real-time Market Watch | NOT IMPLEMENTED | Must wait for authenticated stream and data qualification |
| Live-connected Charting | NOT IMPLEMENTED | Must wait for validated stream and candle contracts |
| LIVE trading / dealing | DISABLED / NOT IMPLEMENTED | No LIVE or dealing routes introduced |

Mocked tests and compilation do not prove broker connectivity. Status must be upgraded only with exact-head CI and provider-side integration evidence.


## ATP-BROKER-001 — Native Broker Management and Capital.com DEMO (2026-11-17)

| Capability | Status | Evidence / limitation |
|---|---|---|
| Settings → Brokers navigation | IMPLEMENTED IN SOURCE | PR #26, existing ContentView/AppSection/SettingsHomeView |
| Capital.com broker workspace | IMPLEMENTED IN SOURCE | PR #26, explicit DEMO/auth/session/stream/trading states |
| Credential entry/edit/clear | IMPLEMENTED IN SOURCE | SecureField, validation, confirmation-based clear |
| Keychain credential storage | IMPLEMENTED IN SOURCE | KeychainBrokerCredentialStore; device-only accessibility; broker/environment/account-login isolation |
| Capital.com DEMO authentication | IMPLEMENTED IN SOURCE | POST /session, CST/X-SECURITY-TOKEN memory-only, GET /session verification |
| Session health monitoring | IMPLEMENTED IN SOURCE | Read-only GET /session every 60 seconds while Brokers screen is active |
| Network/authentication contract tests | PRESENT IN SOURCE | CapitalComAuthenticationTests covers request contract, 401 redaction, and LIVE rejection |
| Credential-store and view-model tests | PRESENT IN SOURCE | Persistence, account/environment isolation, deletion, invalid input, and connection-state coverage |
| Hosted macOS Debug/XCTest/Release | PENDING — remediation committed; fresh exact-head CI required | The owner-Mac log exposed a Swift 5.8 MainActor initializer error at BrokerManagementServices.swift:444; fix is committed, but no passing rebuild is claimed |
| Local macOS build/runtime/Keychain restart QA | PENDING | Owner Mac verification required |
| Real Capital.com DEMO authentication | NOT VERIFIED | No owner credentials supplied; no provider session claimed |
| Market-data WebSocket streaming | NOT IMPLEMENTED BY THIS FEATURE | REST authentication and streaming remain separate |
| LIVE dealing / trading | DISABLED | No dealing methods; risk and execution controls unchanged |

PR #26 is Draft and stacked on PR #25 head. It does not modify PR #24 or PR #25. Do not mark ATP-BROKER-001 complete until exact-head macOS CI, owner-side runtime/Keychain verification, and real DEMO authentication evidence are available.


### Owner-Mac qualification finding and compile remediation — 2026-11-17

- First owner-Mac qualification evidence was supplied from macOS 13.7.8, Xcode 14.3.1 / Swift 5.8.1, XcodeGen 2.36.1.
- `make doctor` and `make generate` completed successfully. Debug build, XCTest build, and Release build were blocked by a Swift concurrency error at `BrokerManagementServices.swift:444:55`: a `@MainActor` authentication-service initializer was invoked from a synchronous nonisolated default argument.
- Corrected dependency construction by making the authentication initializer parameter optional and constructing the default `CapitalComAuthenticationService` inside the `@MainActor` ViewModel initializer. Added an XCTest that exercises default dependency composition without authenticating or making network requests.
- This is a source-level remediation only. It has not yet been compiled or executed on the owner Mac or by fresh exact-head CI. URLSession `Sendable` diagnostics in the original log remain warnings requiring review after the primary compile blocker is cleared.
- No broker credentials, provider session, trading permissions, risk policy, LIVE capability, or dealing behavior were changed.


## PR #26 qualification remediation — 2026-11-17

- Owner-Mac qualification after commit `a1c6c471a0a9a7cfc82a9a30299e7bbdffa9cfb9` confirmed Debug compilation and 34 of 35 XCTest cases passing; the single failure is `CapitalComAuthenticationTests.testDemoAuthenticationUsesOfficialRequestContractAndVerifiesSession()` at the post-URLSession `httpBody` unwrap. The exact-head hosted macOS XCTest job failed at the same assertion; its Release step was skipped and the Apple Silicon job was cancelled.
- GitHub defect reports: [#27 request-body capture](https://github.com/atheertrading/atheer-trading-platform/issues/27), [#28 URLSession Sendable diagnostics](https://github.com/atheertrading/atheer-trading-platform/issues/28), and [#29 Brokers UI freeze investigation](https://github.com/atheertrading/atheer-trading-platform/issues/29).
- Remediation prepared: the test recorder captures request bytes at the URLProtocol interception boundary, supporting both `httpBody` and `httpBodyStream`; assertions decode JSON and verify identifier, password, and encryptedPassword=false. Production authentication code is unchanged in this correction.
- Next gates: focused Capital.com test and full XCTest; resolve/justify Swift 5.8 URLSession Sendable diagnostics; reproduce and isolate the UI freeze; then complete Debug → XCTest → Release on Intel and Apple Silicon and owner-Mac runtime/navigation QA.
- This record does not claim the new test patch has compiled or passed. PR #26 remains Open/Draft; PR #24/#25, LIVE restrictions, dealing boundaries, and risk controls are unchanged.


### PR #26 owner-Mac qualification — 2026-11-17 (ATP-2026-11-17-020)

- The owner-provided terminal report confirms baseline HEAD `0e7f25edb65e6a6a41b86b6f4513231d36edf79e`, Intel macOS 13.7.8 / Xcode 14.3.1 / Swift 5.8.1, XcodeGen 2.36.1, Debug build success, Release build success, and 35 XCTest passing with zero failures.
- Release build output explicitly invokes `CreateUniversalBinary` for `arm64 x86_64`; this is architecture-slice build evidence only, not Apple Silicon runtime QA.
- Runtime warnings: four URLSession Sendable diagnostics, AppKit NSTableView reentrancy, test-host window ordering, and backend loopback connection refused. The latter indicates backend health was unavailable during test launch, not a test failure.
- Remediation source now uses a narrow non-MainActor URLSession request executor and defers mutations originating from the panel manager's SwiftUI List row callbacks.
- Post-remediation qualification has not yet run. Exact-SHA hosted macOS jobs on the baseline were cancelled; repository hygiene and backend toolchain passed.
- Still pending: owner rerun with backend running; inspect the AppKit warning under normal app activation; actual Keychain persistence across app restart; Apple Silicon runtime QA; and real Capital.com DEMO auth.
- PR #26 remains Open/Draft; no LIVE, dealing, or risk-control changes.



- Follow-up commit `f22cac58682910256049541c252b6e54bf17c682` defers the always-visible navigation sidebar List selection state update as an additional AppKit reentrancy safeguard. This is source-level mitigation; owner runtime confirmation remains pending.

## ATP-SCR-MKT-001 — Market Explorer / Instrument Search — 2026-11-17

**Implementation status:** IMPLEMENTED ON FEATURE BRANCH  
**Verification status:** PENDING  
**Branch:** feat/macos-market-explorer  
**Dependency chain:** PR #24 → PR #25 → PR #26 → Market Explorer feature branch

- Added a Markets navigation destination and native Market Explorer screen.
- Added typed backend market-data status and instrument-search contracts with provider/environment validation.
- Search is gated on backend Capital.com DEMO REST session state being connected.
- The screen explicitly distinguishes REST session, market streaming (not connected), and trading (disabled).
- Only instrument metadata is rendered. Untimestamped bid/offer fields are omitted.
- Five deterministic XCTest cases cover status and market payload decoding, LIVE/invalid payload rejection, disconnected-session gating, and connected search results.
- Native Keychain broker credentials from PR #26 and backend environment credentials/session from PR #25 remain separate. No secure credential/session bridge is implemented.
- Exact-head hosted CI, owner-Mac build/XCTest, app runtime, visual QA, accessibility, and real DEMO provider verification remain pending.
- No streaming, charts, watchlists, orders, dealing, risk mutation, LIVE capability, or production readiness is claimed.


## ATP-MKT-002 — Market Explorer Search Lifecycle Hardening — 2026-11-17

**Implementation status:** IMPLEMENTED ON FOCUSED BRANCH  
**Verification status:** PENDING  
**Branch:** `fix/market-explorer-search-lifecycle`  
**Base:** PR #31 exact head `66de2c54cf1ae8156bd3b3e1c8447ae2dfe5e4be`

- Search and backend-status requests use generation tracking to ignore stale completions.
- Editing the search query invalidates the previous request and clears obsolete result state; unavailable status is retained.
- Search eligibility and request validation both enforce 1–100 characters; the existing search UI shows an accessible length counter.
- Added XCTest source coverage for overlong query rejection and out-of-order response handling.
- CI and owner-Mac verification remain pending. No compilation/test success is claimed.
- No new screen, streaming, chart, dealing, LIVE, or risk-control functionality was added.


- PR #33: https://github.com/atheertrading/atheer-trading-platform/pull/33 (OPEN / DRAFT), exact head `a0d6164dbed794cb2d83f211146412bab7a0787f`, based on PR #31 exact head `66de2c54cf1ae8156bd3b3e1c8447ae2dfe5e4be`.
- Initial exact-head CI #44170652406: Repository Hygiene passed; Backend Toolchain in progress; Intel and Apple Silicon macOS jobs queued. Local Sync Safety #44170652465 passed. No macOS build or XCTest result is yet available.


## ATP-MKT-003 — Capital.com DEMO Market Streaming Foundation — 2026-11-17

**Implementation status:** IMPLEMENTED ON FOCUSED BRANCH  
**Verification status:** PENDING  
**Branch:** `feat/capital-demo-market-streaming`  
**Base:** PR #33 head at branch creation `61b0953a04047868f000709369e2a182b3db34d4`

- Server-side DEMO stream endpoint is discovered from authenticated `GET /session`; endpoint host/protocol are validated.
- Shared WebSocket runtime handles quote subscriptions, 40-epic limit, correlation acknowledgements, five-minute ping, bounded reconnect, and resubscription.
- Quote events are normalized and checked for invalid, duplicate, and out-of-order updates; latest values are cached in memory.
- Local API SSE relay exposes quote events without exposing provider tokens.
- Backend tests and Mermaid architecture documentation added.
- Hosted TypeScript/API tests and real DEMO provider verification remain pending. No real quote receipt is claimed.
- macOS consumer, durable history, OHLC stream, Charting, and RiskEngine integration are not part of this increment.
- `CAP_ALLOW_TRADING=false` remains unchanged; no dealing or LIVE capability added.


## ATP-MKT-004 — Existing Market Explorer Live Quote Integration — 2026-11-17

**Implementation status:** IMPLEMENTED ON FOCUSED BRANCH  
**Verification status:** PENDING  
**Branch:** `feat/macos-market-explorer-live-quotes`  
**Base:** PR #34 head at branch creation `1378cc9d78151dc58bc548887ff5a3c45594d62b`

- Native URLSession SSE consumer and parser added.
- Existing Market Explorer now has explicit instrument selection and Start/Stop/Clear streaming controls; maximum 40 selected instruments.
- Timestamped provider Bid/Ask, provider time, quote age, and arrival-time data-quality state are displayed from stream events only.
- Backend sends post-subscription and periodic status events.
- Hosted macOS Intel/Apple Silicon and owner-Mac QA are pending. No live Capital.com quote is claimed.
- No new screen or trading capability. `CAP_ALLOW_TRADING=false` remains unchanged.

## ATP-MKT-005 — Historical Market Data Contracts

**Implementation status:** IMPLEMENTED ON FOCUSED BRANCH  
**Verification status:** BACKEND VERIFIED; FULL EXACT-HEAD QUALIFICATION PENDING  
**Branch:** `feat/historical-market-data-contracts`  
**Source correction commit:** `d6bca573c28ca71b38cb10c9313e86c517b68f08`  
**Base:** PR #38 exact head `0d37f11a8f91d09c82b39c443e346622a7df3530`

- Typed provider-neutral historical candle contract added.
- Bid and Ask OHLC remain separate; provider UTC timestamp and local receipt time are preserved independently.
- Optional `lastTradedVolume` is retained with explicit provider-field lineage; no unsupported volume interpretation is assigned.
- Exact duplicates are dropped/countable; conflicting duplicates are rejected.
- Time gaps are reported as observed and require a market-session calendar before classification.
- DEMO historical endpoint accepts paired UTC `from/to` bounds and max 1–1000, and returns normalized data.
- Pagination metadata corrected to use raw provider record count before duplicate removal; regression case verifies `max=2`, two raw duplicates, one normalized candle, and `limitReached=true`.
- Exact-head Backend Toolchain passed Node 24.22.2 type-check/build and 37/37 API tests (run #44182796685, job #134391313681); Repository Hygiene passed; Local Sync Safety passed (run #44182796765).
- Mermaid validation remains in progress (run #44182796666); Intel x86_64 and Apple Silicon arm64 macOS jobs remain queued (jobs #134391313683 and #134391313955).
- Pagination review thread was resolved after the correction and regression test passed.
- Follow-up task/status/continuity/index documentation commits were added after the source correction. The 37/37 result above applies to source correction head `d6bca573...`; the final documentation-updated PR head requires a fresh exact-head run.
- No durable persistence, live provider verification, OHLC streaming, Charting, or market-session calendar is claimed.
- `CAP_ALLOW_TRADING=false` remains unchanged; no dealing or LIVE behavior.


## Swift 5.8 Market Explorer stream qualification remediation — 2026-11-18

| Item | Status | Evidence |
|---|---|---|
| XCTest async error propagation | IMPLEMENTED ON PR #38 / #39 BRANCHES | Test now declares `async throws`; commits `f07548e...` and `59ddc5e...` |
| Quote-event test construction | IMPLEMENTED ON PR #38 / #39 BRANCHES | Quote factory returns `MarketDataStreamQuote` before `.quote(...)` wrapping |
| Foundation concurrency import adjustment | IMPLEMENTED ON PR #38 / #39 BRANCHES | `@preconcurrency import Foundation` in `MarketSearchClient.swift` |
| Owner Intel Debug/XCTest | OWNER-REPORTED | PR #39 comment 6962746664: Debug passed, 48/48 tests; tested base plus local source modifications |
| New exact-head hosted CI | PENDING | PR #38 run #44190351651; PR #39 run #44190373646 |
| Apple Silicon / Release / runtime / accessibility / provider verification | NOT VERIFIED | Explicitly outside the owner-reported local run |

The hosted PR #38 failure on its previous head was a source-level XCTest compile failure, not a demonstrated application runtime failure. Do not mark the streaming integration accepted or merge-qualified until exact-head CI and the remaining architecture/runtime gates complete.


## ATP-DOMAIN-001 — Canonical Trading Domain Foundation — 2026-11-18

| Capability | Implementation status | Verification status |
|---|---|---|
| Strong identifiers, environment and provenance | Implemented in `services/api/src/domain/shared.ts` | Exact-head typecheck pending |
| Exact decimal values and increment alignment | Implemented; no binary float coercion or implicit rounding | API tests pending |
| Instrument identity and broker specification | Implemented; broker/environment identity and unit-bearing constraints preserved | API tests pending |
| Broker account and balance snapshots | Implemented with source/environment validation | API tests pending |
| Immutable order-intent envelope | Implemented with intent/command/correlation/idempotency and origin/market-data provenance | API tests pending |
| Risk assessment and lifecycle policy | Implemented as policy-versioned decision record and caller-supplied transition policy | API tests pending; concrete OMS state machine intentionally not selected |
| Broker order/position observations, fills, execution events, reconciliation and audit | Implemented as provenance-bearing contracts | API tests pending |
| PostgreSQL persistence / transactional outbox | Not implemented in this package | Next work package after domain qualification |

**PR:** #40, branch `feat/trading-domain-foundation`, based on PR #39. Initial CI run #44193072976 failed backend typecheck on two branded-identifier comparisons in the earlier head; the code was corrected in subsequent commits. The current source head `f295023e...` requires exact-head revalidation. Repository Hygiene passed on the earlier head. No current-head backend test pass is claimed.

No local Node 24 or owner-Mac verification is claimed. No broker dealing, RiskEngine bypass, LIVE capability, or change to `CAP_ALLOW_TRADING=false`.


## ATP-DOMAIN-001 strict UTC parser follow-up — 2026-11-18

- Current code correction: commit `7ebe46ce7abd104cb74345169e16dbe64cb87998` rejects impossible calendar dates and out-of-range clock components before `Date.parse`.
- Regression coverage added for leap-year validity, impossible month lengths, invalid month, hour 24, and minute 60.
- Previous head `34015bda...`: backend 46/46 tests, Repository Hygiene, Mermaid, Local Sync Safety, and Intel x86_64 Debug/XCTest/Release/Swift CodeQL passed; Apple Silicon arm64 queued.
- New fix head `7ebe46ce...`: Local Sync Safety passed; Mermaid in progress and CI queued at last inspection. Previous-head results are not carried forward.
- PostgreSQL persistence remains the next package after exact-head domain qualification and formal schema/state reconciliation. No dealing or LIVE capability; `CAP_ALLOW_TRADING=false`.

## ATP-PERSISTENCE-001 — PostgreSQL durable trading journal — IN PROGRESS

- PR #41: `feat/postgres-persistence-foundation`, stacked on PR #40.
- Implemented PostgreSQL driver/lockfile, SQL migration ledger and schema, environment-pinned repository adapter, instrument/account persistence, order-intent/risk journal, reconciliation/audit persistence, and transactional domain outbox.
- Added real PostgreSQL 17 CI service and integration tests for migration checksum drift, concurrent migration startup, intent/risk idempotency, conflict detection, foreign-key rollback, audit/reconciliation records, and no execution-dispatch events.
- Exact-head hosted verification has not yet been inspected. No test pass is claimed at this checkpoint.
- No broker dealing API, execution dispatcher, production database, or LIVE capability. `CAP_ALLOW_TRADING=false` unchanged.

- Startup integration now verifies schema/checksums without mutating the database. Schema application is an explicit `npm run migrate` operation; see `docs/operations/POSTGRESQL.md`.
