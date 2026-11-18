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


## Adaptive Workspace layout increment — 2026-11-17

**Status: IMPLEMENTED IN SOURCE; exact-head CI queued; owner visual acceptance pending.**

- PR #22: `https://github.com/atheertrading/atheer-trading-platform/pull/22`, branch `feat/workspace-adaptive-layout`, based on PR #18 head `08d7b68ef14dbbce57752ce7b7f0215404a281cb`; implementation commit `db073848e7a80bbd4db2868faa741725698cb86c`.
- Commit: `db073848e7a80bbd4db2868faa741725698cb86c`.
- Changed `apps/macos/ATHEERTradingPro/Sources/WorkspaceHomeView.swift`: replaced the fixed four-column status grid and fixed two-column panel grid with SwiftUI adaptive grids.
- Initial provisional layout metrics: status tiles 150–240 points; workspace panels 320–560 points; existing workspace content maximum width remains 1280 points.
- No navigation destinations, business modules, financial data, order controls, persistence, docking, or trading capabilities were added.
- Existing XCTest coverage still asserts the four-panel inventory and default visibility. No new test execution is claimed in this record; exact-head CI is pending.
- Owner confirms that the application launches on the Mac and has been exercised across two displays. This is owner-confirmed runtime evidence only; visual quality, window/panel behavior, accessibility, keyboard/focus, and VoiceOver remain unverified by engineering.
- Formal ATP-ARCH-014/037/038 and original IPDS source/approval reconciliation remains outstanding. The responsive metrics are provisional, not final design-system breakpoints.


## PR #22 exact-head revalidation — 2026-11-17

**Status: SOURCE IMPLEMENTED; EXACT-HEAD HOSTED CI PASSED; OWNER VISUAL/LOCAL QUALIFICATION PENDING.**

- PR #22 remains open and unmerged; branch `feat/workspace-adaptive-layout`; exact inspected HEAD `3931c937708d4adad7a9595657015d478787f418`; base PR #18 HEAD `08d7b68ef14dbbce57752ce7b7f0215404a281cb`.
- CI #160 passed repository hygiene/Markdown lint, backend toolchain/typecheck/tests, macOS Debug build, XCTest, Release build and Swift CodeQL on the exact inspected HEAD.
- Local Sync Safety #167 passed shell syntax validation and non-destructive synchronization tests on the exact inspected HEAD.
- PR #10/#17/#18/#22 remain open and unmerged; the required stack is intact. Exact current heads and their corresponding successful CI/safety runs are recorded in PROJECT_CONTINUITY.md.
- The adaptive source still uses provisional 150–240 pt status-tile and 320–560 pt panel widths. No dedicated new geometry test was added by PR #22; existing XCTest covers panel inventory/default visibility. Hosted XCTest passed.
- No owner-side local Xcode build/test, screenshot review, visual QA, accessibility, keyboard/focus, or independent two-display verification is claimed. The owner's earlier launch/two-display report remains owner-confirmed without an exact tested SHA.
- Formal IPDS and ATP-ARCH-014/037/038 source/approval reconciliation remains open. Workspace persistence, panel resizing/docking, draggable arrangement, profiles, and Settings remain unimplemented.


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


## ATP-UI-ARCH-001A — Market Explorer boundary separation — 2026-11-18

- Replaced provider-facing `MarketSearchInstrument` and Decodable status models in the presentation path with provider-independent `MarketInstrumentSummary` and `MarketDataBackendStatus`.
- Provider response DTOs are now private to `MarketSearchClient.swift`; the adapter maps DTOs into semantic models.
- Moved `MarketExplorerViewModel` into its own source file and removed its default concrete HTTP-client construction.
- `ContentView` now selects `URLSessionMarketSearchClient` at the composition root and injects the protocol into Market Explorer.
- Added an unknown backend-state rejection test and migrated search lifecycle tests to semantic models.
- Code commits: `448fc017d8729fe047a6437f0f9c77bb81b53063`, `a4ea2355a7865eec3284605e0a1a4097ef954ded`, `e3cf9c04bb27bd7c3311ce04825a99688514afd5`, `65b53535304117aff11f71aa7f83bd89c5636c43`, `4b19bc34fbb7599f42673303a08b4a7ab53e6001`, `82d67fde50d56bad020e51d455b653e6901c6237`.
- Exact-head hosted CI is pending. No local Mac/Xcode run is claimed for the refactor.


### ATP-UI-ARCH-001A transport and HTTP-contract completion

- Extracted the immutable-session `URLSessionRequestExecutor` into shared infrastructure and changed Capital.com authentication and Market Explorer to use it, explicitly passing `delegate: nil` to avoid Swift 5.8 actor-boundary Sendable diagnostics.
- Market Explorer now defaults to an ephemeral URLSession with cookie storage and URL cache disabled.
- Added URLProtocol-backed HTTP contract tests for GET status endpoint, GET markets endpoint, encoded searchTerm, no-store headers, DEMO status mapping, 503/500 mapping, and transport-failure mapping.
- Exact-head hosted CI remains pending.


## Integration checkpoint — 2026-11-18

### Merged foundations

- PR #24 Workspace / Command Center: merged as `bd83fd3c8df481104c347f05d9d4f38537d8b011`.
- PR #25 Capital.com DEMO market-data foundation: merged as `6b570b8c5a3367784cde7fa2643593c5b5a1eda2`.
- PR #26 secure Capital.com DEMO broker management: merged as `6b4668b9355178d5e13219f14cfe8cc847770915`.
- PR #26 exact-head hosted CI run `44231098511` passed Intel x86_64 Debug/XCTest/Release/Swift CodeQL, Apple Silicon arm64 Debug/XCTest/Release, Backend Toolchain and Repository Hygiene. Dedicated CodeQL and Local Sync Safety also passed.

### Remaining broker acceptance

- Broker management is integrated in `main`, but `ATP-BROKER-001` is not production/DEMO-runtime complete.
- Owner-Mac Keychain restart/persistence and UI runtime acceptance on the merged head remain pending.
- Real Capital.com DEMO credentials have not been entered or authenticated in this session.
- LIVE authentication, dealing, and order execution remain disabled.

### Market Explorer

- PR #33 retargeted to `main` after PR #26 merge.
- Current exact head: `8885fd6f43098421973d098b2cd3d94a8e7545e3`.
- Architecture boundary refactor, shared URLSession executor and HTTP-contract tests are implemented; exact-head CI is running.


### ATP-SEC-001A — Native Market Search client marker

- PR #33 now sends `X-ATHEER-LOCAL-CLIENT: macOS` on both backend status and market search GET requests.
- Server-side rejection of missing markers, browser Origin and cross-site Fetch Metadata is implemented in dependent PR #37.
- The client/server contract is not considered complete until both PRs are integrated and exact-head CI passes.


## 2026-11-18 — PR #33 Market Explorer integration merged

- PR #33 merged into `main` with squash merge commit `2e8bf9bd5f4274ed5d500474335a778cd6f9b75c`.
- Merged source head: `04e70808d5cb403b6a7b8e05ceb41dc335e3d4cf`.
- Exact-head CI run `44235123474`: Intel x86_64 macOS build/XCTest/Swift CodeQL passed; Apple Silicon arm64 Debug/XCTest/Release passed; Backend Toolchain and Repository Hygiene passed.
- Dedicated CodeQL run `44235124217` and Local Sync Safety run `44235123457` passed.
- The successful CI is hosted verification only. Physical Mac runtime, visual/accessibility QA, Keychain restart persistence and authenticated Capital.com DEMO acceptance remain separate owner-workstation gates.

### Broker and connection integration gates

- ATP-BRK-002 / EDL-022: one backend CMS and Broker Session Manager must own broker credentials and CST/X-SECURITY-TOKEN lifecycle. PR #26's Swift Keychain/direct-auth path and PR #37's environment-driven backend-auth path are separate authorities and must be reconciled before PR #37 is merged as a completed broker integration.
- Selected secure bootstrap direction: app-managed backend child process; 256-bit per-launch capability delivered over private stdin/pipe; bearer authorization on local control routes; backend CMS uses a Keychain-backed storage adapter/helper; environment credentials remain test/development-only.
- ATP-BRK-003 / ATP-MKT-007 / EDL-023: PR #37's current shared WebSocket, 40-instrument cap, deduplication, five-minute ping, reconnect/backoff and quote-quality counters are implemented; sequential session-creation rate limiting, scheduled REST keepalive, priority-based subscription allocation, account-switch restoration and utilization metrics remain incomplete.
- PR #37 remains draft and is not merge-qualified. Its branch diverges from the new `main` history (91 ahead / 33 behind when compared to the PR #33 squash merge); do not retarget or rewrite history. Resolve the dependency graph with a preservation-first integration plan.

### Downstream charting batch

- PR #44, #45 and #47 exact-head CI runs `44221728876`, `44227375230` and `44233627460` respectively report all jobs successful, including Intel/Apple Silicon, backend and repository hygiene where present.
- These PRs remain drafts and are stacked on unmerged feature branches. Passing CI does not establish merge readiness into `main`; parent branch ancestry and integration order remain to be reconciled.


## 2026-11-18 — Backend broker-session ownership and native IPC handoff (PR #55)

- **IN PROGRESS / UNMERGED:** `BrokerSessionManager` is the backend session authority for Capital.com DEMO credentials, REST session tokens, keepalive and stream connection info.
- Added capability-protected broker-session status/connect/disconnect APIs; credential payloads are bounded and strict; responses are no-store and sanitized.
- Added the native `BackendBrokerAuthenticationService` to hand Keychain credentials to the authenticated backend IPC process. Direct native Capital.com session ownership was removed from the broker-management composition path.
- Added account-switch coordination, the documented one-session-creation-per-second limit, separate 401/403/429 handling, credential-runtime cleanup on logout failure, and stream-shutdown failure coverage.
- Added backend and native URLProtocol tests. They are committed but not yet qualified on the final PR #55 head.
- PR stack: #51 IPC capability → #54 native process supervisor → #55 broker-session integration. Do not merge out of order.
- PR #54 exact-head run `44276116460`: backend toolchain and repository hygiene passed; macOS qualification remained in progress/queued at last inspection.
- PR #55 final exact-head CI, Intel/Apple Silicon XCTest, owner-Mac launch/Keychain qualification and real DEMO broker acceptance remain pending.
- Trading and LIVE access remain disabled. See `SESSION_2026-11-18_049_BROKER_SESSION_IPC_INTEGRATION.md`.


## 2026-11-18 — Broker fixture lifecycle and stacked IPC integration (Batch 050)

- PR #55 code/test head e3d5ff4a44a8ac4075603ce93887c27ba6dd164f adds tracked teardown for 14 CapitalDemoRuntime and 7 BrokerSessionManager fixtures in market-data-runtime.test.mjs; the streaming test suite separately tracks and disconnects streaming runtimes. This prevents test-owned keepalive intervals and sockets from surviving the suite.
- Documentation commit f36578a7167acff29596ee0c02b34ebd0e11c07e records the batch and advances PR #55. The final exact-head CI on the new documentation commit is pending; no final-head test or macOS pass is claimed.
- Local Sync Safety 44283628390 passed on the code/test head before the report commit. On that same head, API typecheck passed and API tests were still running; Intel and Apple Silicon jobs were queued. Do not carry these results forward as proof for the new head.
- PR stack remains open/draft: #51 capability IPC → #54 managed backend process → #56 Swift actor-isolation correction → #55 backend broker-session integration. Integrate from #55 upward into #56, then #54, then #51; requalify #51 before main.
- Market Explorer shows REST/streaming status but no live quote subscription yet. Authenticated native SSE subscription, quote normalization/freshness and UI states remain the next market-data implementation slice.
- Owner-Mac build/launch, Keychain restart, visual/accessibility QA, and real Capital.com DEMO authentication remain unverified. LIVE/dealing/trading remain disabled.


## 2026-11-18 — Batch 051 implementation status

- **Backend shutdown:** bounded stream disconnect, broker logout and HTTP server close; 20-second hard child deadline; redacted operation diagnostics; non-zero exit status on incomplete cleanup. Added deterministic timeout/failure/success tests. Exact-head CI is pending.
- **Native supervisor:** PR #57 branch has the PR #56 class-bound protocol and mutable supervisor compile corrections. Local Sync Safety passed; exact-head CI is pending; ancestry remains diverged.
- **Mermaid architecture:** read all five ATP-MER-001 sources from Library Codex.zip. They are proposed target architecture; syntax validation and deployed implementation are not claimed.
- **Credential handoff confidentiality:** unresolved. Authenticated loopback HTTP does not encrypt API-key/login/password payloads. Keep broker stack blocked until a private local IPC transport or an explicitly accepted threat boundary is in place.
- **Broker DEMO / LIVE:** no real DEMO authentication was performed. LIVE/dealing/trading remain disabled; `CAP_ALLOW_TRADING=false`.


## 2026-11-18 — Official Capital.com API limit verification

- Verified official current limits: 10 REST requests/second per user; 1 `POST /session`/second per API key; 10-minute REST and WebSocket session inactivity/duration; ping at least every 10 minutes; maximum 40 WebSocket market-data epics; 1,000 DEMO position/working-order requests per hour.
- Code alignment: shared REST client spaces request starts by 100 ms; session creation is throttled to 1 second; REST and WebSocket pings run every 5 minutes; stream subscription cap is 40.
- Account-switch interruption is documented; account-switch support remains unqualified. Future OMS must implement the endpoint-specific order budget.
- Evidence: `SESSION_2026-11-18_052_CAPITAL_API_LIMITS_VERIFICATION.md` and EDL-029.


## 2026-11-18 — Market Explorer live quote monitor

- Integrated authenticated local SSE transport and native quote stream view model.
- Added 40-epic selection, timestamped bid/ask/spread, quote age, freshness quality, status telemetry and reconnect/backoff.
- Preserved existing Market Explorer design tokens, adaptive status layout and accessibility.
- Backend status events now reflect provider-confirmed subscriptions and reconnect/degraded states; error details are redacted.
- Display-only DEMO market data; no dealing. Exact-head CI and owner-Mac DEMO validation remain pending.


## 2026-11-18 — Pull-request consolidation

- Superseded/duplicate PRs #49, #50, #54 and #58 closed unmerged; unique code/tests/docs preserved.
- Clean live quote replacement is draft PR #64, 11 commits ahead / 0 behind its parent at integration.
- PR #55, #57 and #64 are open draft PRs with CI queued; no merge claimed.
- P0 broker credential confidentiality remains unresolved.
