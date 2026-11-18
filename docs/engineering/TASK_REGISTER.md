# ATHEER Trading — Task Register

**Snapshot date:** 2026-11-17  
**Active milestone:** M00 — Governance baseline merged; M01 — Platform architecture and toolchain foundation

Statuses: `DONE` = verified complete; `IN PROGRESS` = active work; `PENDING` = not started; `BLOCKED` = dependency prevents progress; `OWNER DECISION` = requires explicit owner direction.

## M00 — Knowledge, governance, and source reconciliation

| ID | Priority | Task | Status | Acceptance evidence / dependency |
|---|---|---|---|---|
| M00-001 | P0 | Inspect new repository identity, visibility, default branch, and initial commit | DONE | GitHub metadata and commit inspected |
| M00-002 | P0 | Establish root engineering instructions and security baseline | DONE | PR #1 squash-merged as 27e0ce61d2af09296dd121fb1194d6a7cb930bdc |
| M00-003 | P0 | Establish project continuity, conversation index, decision log, and task register | DONE | PR #1 squash-merged as 27e0ce61d2af09296dd121fb1194d6a7cb930bdc |
| M00-004 | P0 | Reconcile Library Engineering Operating Standards and governance references | IN PROGRESS | Full document/source review and conflict register |
| M00-005 | P0 | Inventory Library archives, source documents, and historical specifications | IN PROGRESS | Inventory with source IDs, versions, and provenance |
| M00-006 | P0 | Inspect surviving repositories and local source-code history | IN PROGRESS | Repository/source inventory; inaccessible sources marked |
| M00-007 | P0 | Create Master Document Registry and Source Provenance Register | IN PROGRESS | Initial 47-document registry created; approval/provenance reconciliation remains pending |
| M00-008 | P0 | Create Specification Conflict Register | IN PROGRESS | Conflicts, source authority, resolution, and owner questions |
| M00-009 | P1 | Create Requirements Traceability Matrix | IN PROGRESS | Template exists; formal requirement mapping and verification links remain outstanding |
| M00-010 | P1 | Establish architecture baseline and bounded-context map | PENDING | Reviewed architecture document and diagrams |
| M00-011 | P1 | Reconcile historical ADRs and OOP standard | IN PROGRESS | ADR inventory; no identifier collisions |
| M00-012 | P1 | Define IPDS v1.0 specification and token governance | IN PROGRESS | Primitive, semantic, component, theme, accessibility contracts |
| M00-013 | P1 | Establish documentation validation and CI baseline | PENDING | Reproducible workflow and passing checks |
| M00-014 | P1 | Configure repository security automation and branch rules | PENDING | Rulesets endpoint returned an empty list; branch-protection read returned 403 to the integration; owner-side verification and configuration evidence required |
| M00-015 | P2 | Plan source migration and historical Git preservation | PENDING | Owner-reviewed migration and provenance plan |
| M00-016 | P0 | Reconcile four-repository architecture with current repository strategy | DONE | EDL-004; repository topology decision; SCR-001 resolved for topology only |
| M00-017 | P0 | Reconcile AI autonomy, capability permissions, and execution authority taxonomies | IN PROGRESS | ATP-ARCH-011/028/029 and Q27.2/Q27.4/Q27.5/Q27.6/Q28.24/Q28.47/Q29.5 |

## M01 — Platform and domain architecture

| ID | Priority | Task | Status |
|---|---|---|---|
| M01-001 | P1 | Define platform bounded contexts and dependency rules | PENDING |
| M01-002 | P1 | Define canonical trading-domain model and lifecycle contracts | PENDING |
| M01-003 | P1 | Define market-data contracts, timestamps, freshness, and recovery | PENDING |
| M01-004 | P1 | Define centralized RiskEngine and authorization contracts | PENDING |
| M01-005 | P1 | Define OMS, Execution Gateway, idempotency, outbox, and reconciliation | PENDING |
| M01-006 | P1 | Define AI orchestration, agent permissions, and tool contracts | PENDING |

## M02 — Product foundations

| ID | Priority | Task | Status |
|---|---|---|---|
| M02-001 | P2 | Qualify macOS/Xcode/Swift compatibility and app structure | IN PROGRESS — Xcode 14.3.1 / Swift 5.8.1 / XcodeGen 2.36.1 and generated project were inventoried; owner confirms application launch and use across two displays. This is owner-confirmed, not independent runtime/visual verification. Local Debug/Release/XCTest logs and exact current local HEAD/worktree evidence remain outstanding. |
| M02-002 | P2 | Specify and implement IPDS primitives and semantic tokens | PENDING |
| M02-003 | P2 | Establish backend service foundation and API contracts | IN PROGRESS |
| M02-004 | P2 | Establish automated tests and local developer workflows | IN PROGRESS |
| M02-005 | P2 | Integrate backend health into the macOS workspace | IN PROGRESS — PR #10 exact head `06bd496d957b6cd2f999209cf5dc83cae54251cf` passed hosted CI #117; owner confirms general app launch and two-display use; local XcodeGen/Debug/XCTest logs were not captured in this session. Owner-provided /health/live 200 and /health/ready 503 evidence validates endpoint behavior; API Connection screen-specific visual/state/copy/keyboard verification remains pending. |
| M02-006 | P2 | Implement non-destructive local synchronization and workstation bootstrap | IN PROGRESS |
| M02-007 | P2 | Implement first native multi-screen navigation and API Connection screen | IN PROGRESS — PR #17 `feat/macos-workspace-api-connection`; exact-head workflow #132 passed backend, hygiene, macOS Debug/XCTest/Release and Swift CodeQL jobs; general app launch/two-display use is owner-confirmed, while API Connection screen-specific behavior, recovery, copy/paste, keyboard and accessibility verification remain pending |
| M02-008 | P2 | Establish native application-wide copy/paste foundation | IN PROGRESS — Issue #16 first increment in PR #17; workflow #132 passed on its exact head. General app launch/two-display use is owner-confirmed; application-wide clipboard audit and API Connection-specific copy/paste, keyboard and accessibility verification remain pending. |
| M02-009 | P2 | Implement shared IPDS token foundation and initial operational workspace panels | IN PROGRESS — PR #18 provides the initial shared tokens and four panels. Follow-up PR #22 (`feat/workspace-adaptive-layout`; implementation commit `db073848e7a80bbd4db2868faa741725698cb86c`) adds adaptive grid widths. Exact-head CI on the final PR #22 revision and owner visual acceptance remain pending. Owner confirms application launch and two-display use; this does not establish visual/accessibility acceptance. Formal IPDS source/approval reconciliation remains pending. |

## Governance notes

- Do not mark tasks DONE solely because a document or source file was drafted.
- A pull request opened is not equivalent to merged work.
- A successful compile is not production qualification.
- Historical task statuses must be revalidated against current source and test evidence.
- Update this register together with Project Continuity and Implementation Status.

## Bootstrap review reference

The initial governance baseline was squash-merged through [PR #1](https://github.com/atheertrading/atheer-trading-platform/pull/1) as commit 27e0ce61d2af09296dd121fb1194d6a7cb930bdc.

## Source-reconciliation progress update — 2026-11-16

Structural inspection of the two Library ZIP archives is complete. Tasks M00-004, M00-005, M00-006, M00-008, M00-011, and M00-012 are IN PROGRESS. The 47 formal documents and 517 Q&A documents have not yet been reconciled individually. The repository topology conflict was resolved by EDL-004; the original ATP-ARCH-042 remains preserved as a source document.

## Platform foundation work — 2026-11-16

The platform foundation was merged through PR #2. It adds the XcodeGen-driven macOS app shell, macOS build/test scripts, local environment diagnostics, AI navigation guidance, repository architecture/layout, PR template, CodeQL and CI workflows, Dependabot, and developer setup instructions.

The local Mac has not been freshly qualified in this session. The XcodeGen pin remains 2.36.1 for the historical Xcode 14.3.1 workstation. Do not mark M02-001 complete until generation, Debug/Release builds, XCTest, and local runtime verification are completed on the actual Mac.

## Documentation quality task

- M00-018 — Normalize legacy Markdown formatting across the historical engineering registry and knowledge-source documents, then re-enable temporarily disabled spacing, link, and table-style rules. The initial CI lint run found 82 formatting-only findings across 22 files; the current config keeps other default rules active while this baseline cleanup remains pending.

## Mermaid documentation and architecture source recovery — 2026-11-16

| ID | Priority | Task | Status | Acceptance evidence / dependency |
|---|---|---|---|---|
| M00-019 | P0 | Correct continuity records for PR #2 merge and active repository identity | IN PROGRESS | Session 008 addendum; update stale implementation and decision snapshots |
| M00-020 | P0 | Recover and migrate all original Mermaid blocks from the Library archive | IN PROGRESS | 31 source Markdown documents / 52 blocks; extractor committed; generated files, provenance manifest, rendering and review still pending |
| M01-007 | P1 | Establish canonical architecture diagram sources and Mermaid CI rendering | DONE | PR #6 merged at 70794e7f20f129c17ba64bcf4b1eba0df32999df; Mermaid rendering, repository hygiene, backend, macOS build/tests/Swift CodeQL, and Actions analysis passed |
| M00-021 | P1 | Reconcile the 47 formal documents, 517 Q&A sources and approval metadata | IN PROGRESS | Historical registry lists 47 formal documents; current accessible Q&A archive contains 517 Markdown files but no formal-specification directory. Codex.zip contains derived summaries, not original ATP-ARCH-014/037/038/IPDS sources. Exact revisions and approval traceability remain blocked on original source retrieval. |

The historical Mermaid count is 31 source documents containing 52 Mermaid blocks, not 31 individual diagrams. Do not mark M00-020 or M01-007 DONE until generated legacy sources are committed, all Mermaid files render in CI, and provenance is verified.

## Documentation readiness and scaling follow-up — 2026-11-16

- Added `docs/engineering/REPOSITORY_DOCUMENTATION_READINESS.md`: identifies present bootstrap documentation, historical references absent from the current tree, and future production/scaling documentation.
- Added `docs/architecture/PLATFORM_SCALING_AND_DEPLOYMENT_STRATEGY.md`: proposed modular-monolith-first scaling strategy; no cloud provider, capacity target, SLO, RPO or RTO is invented.
- Added `docs/engineering/REQUIREMENTS_TRACEABILITY_MATRIX.md`: initial traceability structure; formal requirement mapping and verification links remain pending.
- M00-009 (Requirements Traceability Matrix) is IN PROGRESS, not DONE; a template exists, but formal requirement mapping and verification links remain outstanding.
- PR #6 is merged and its Mermaid rendering, repository hygiene, backend, macOS build/tests/Swift CodeQL, and Actions-analysis checks passed. M01-007 is DONE. M00-020 remains IN PROGRESS until all 31 source Markdown documents / 52 Mermaid blocks are extracted, committed with provenance, rendered, and reviewed.

## Phase 1 qualification — 2026-11-16

- PR #7 records repository identity, CI, branch and source-control findings.
- Phase 1 remains IN PROGRESS: active main ruleset, local Git author/authentication, and repository-level Actions/security settings remain unresolved or unverified.
- The owner has explicitly authorized Phase 2 to proceed as a sequencing exception. This does not close or waive Phase 1 findings.

## Phase 2 Xcode configuration — 2026-11-16

- M02-001 is IN PROGRESS.
- Branch `build/phase-2-xcode-configuration` introduces explicit Debug/Release build settings, targeted Swift concurrency diagnostics, generated scheme inspection, and a hosted Release build.
- Developer setup documentation records the configuration policy and known signing/sandbox/architecture limitations.
- Verification, PR review, local Mac build/test/launch, and arm64 qualification remain pending. Do not mark M02-001 DONE until those acceptance criteria are evidenced.


## Backend foundation — local health vertical slice — 2026-11-16

- M02-003 is IN PROGRESS: a loopback-only Node.js 24 / TypeScript API health service is being introduced under services/api.
- M02-004 is IN PROGRESS: six API/configuration tests and CI execution are added in the review branch.
- The service exposes process liveness and platform readiness only. Persistence and broker dependencies are explicitly not configured; trading remains disabled.
- This work does not implement order, account, market-data, broker, strategy, risk, or execution endpoints.
- Acceptance remains pending current GitHub CI and subsequent local Node.js 24 verification.


## M02-005 macOS backend health integration — 2026-11-16

- Added a dependency-injected URLSession health client, view model, and backend status panel on branch feat/macos-backend-health-integration.
- The client treats HTTP 503 with a valid not_ready response as a reachable API and a platform-readiness failure, not a network disconnect.
- The application exposes no broker or order controls. Trading remains disabled.
- Four XCTest cases are included. Hosted macOS CI and local Mac build/test/launch verification remain pending.

## M02-006 Safe local synchronization and workstation bootstrap — 2026-11-16

- PR #11 merged the non-destructive safe-sync workflow, workstation doctor, bootstrap guard, Makefile targets, and local sync procedure.
- The isolated Git behavior tests passed for dirty-worktree preservation, clean fast-forward, origin mismatch rejection, and divergent-main refusal.
- Actual execution against the owner's Mac and current local worktree remains pending.


### Phase 0 reconciliation — 2026-11-16

- M02-005 remains IN PROGRESS: PR #10 contains the native loopback health client, readiness decoder, view model, workspace panel, and five XCTest cases. Hosted macOS Debug/Release build and XCTest, backend checks, repository hygiene, and CodeQL passed on the pre-documentation head; the documentation-only follow-up commits require their own fresh checks. Local Mac verification remains outstanding.
- M02-006 remains IN PROGRESS: safe-sync and workstation bootstrap are merged and isolated Git behavior tests passed. Execution against the owner's local checkout has not been performed.
- M02-001 remains IN PROGRESS: hosted Xcode qualification passed, but local Xcode 14.3.1 compatibility, app launch, and Apple Silicon qualification remain unverified.
- M00-014 remains PENDING: branch protection and repository security configuration cannot be verified through the connected integration; HTTP 403 is an access limitation, not evidence of disabled protection.
- M00-004/005/006/007/008/011/012/017 and M00-021 remain in source/document reconciliation states as already recorded. The 47 formal documents, 517 Q&A records, approval metadata, historical repository recovery, ADR inventory, and requirement mapping are not fully reconciled.


### Phase 0 source retrieval findings — 2026-11-16

- P0 — Preserve and register the three current governing documents in Library `/work`; complete their cross-reference and revision metadata.
- P0 — Reconcile the original Engineering Operating Standards working draft against the current Master Directive and delegation. Its repository pointer names AtheerAutotrade and its own approval statement is conditional; do not treat it as blanket owner-approved.
- P0 — Locate original formal architecture archive (47 documents) and compare against the Codex package registry; full originals were not present in the visible Library folder inventory.
- P1 — Reconcile 517 primary Q&A files plus nested archive content; retain original paths, hashes, approval states, and requirement/ADR links.
- P1 — Verify source-stated approval declarations AR-001–003 against exact embedded section scope, revision, and date. They do not establish blanket approval or LIVE authorization.
- P1 — Reconcile ADR-0004/0005/0006 originals and OOP standard; current archive register references them but does not include their original full text.

- PR #10 code-review correction fixes the health client to loopback and rejects `not_ready` responses that advertise trading enabled; a fifth XCTest covers this fail-closed invariant. Fresh CI is required on the updated branch head.


## Workspace visual foundation — 2026-11-17

- M02-009 adds shared design-token roles and reusable workspace panels; it remains IN PROGRESS pending exact-head CI, runtime QA and formal IPDS source reconciliation.
- M02-007 hosted CI #132 passed on PR #17 exact head; owner runtime QA remains pending.
- M02-008 hosted CI #132 passed on PR #17 exact head; application-wide clipboard audit and owner runtime QA remain pending.
- ATP-ARCH-014/037/038 and original IPDS full source/approval metadata were not surfaced by Library retrieval; do not mark product IA or IPDS as formally approved.


## PR #18 local qualification checkpoint — 2026-11-17

- Local safety branch `safety/local-pr10-checkpoint-20261117` preserves the original local PR #10 checkout at `06bd496d957b6cd2f999209cf5dc83cae54251cf`.
- Remote ancestry was verified: PR #10 → PR #17 → PR #18. The local qualification branch `work/local-pr18-qualification` tracks `origin/feat/macos-workspace-visual-foundation` at source head `331f424d6d1180569504b725cbcaa1eece41ed46`; the working tree was clean at branch creation.
- Local toolchain inventory returned Xcode 14.3.1, Swift 5.8.1, XcodeGen 2.36.1, and an existing generated Xcode project. This is environment discovery only; no local build, XCTest, launch, or visual result is claimed.
- PR #18 workflow #135 passed on source head `331f424d6d1180569504b725cbcaa1eece41ed46`: repository hygiene/Markdown lint, backend typecheck/tests, macOS Debug build, XCTest, Release build, and Swift CodeQL. Local Sync Safety workflow #90 also passed.
- Next: inspect full governing/architecture requirements and source; run local Debug → XCTest → Release with isolated DerivedData; then launch and perform visual, interaction, accessibility, and multi-display checks where supported.


## 2026-11-17 — Adaptive workspace layout and source-retrieval checkpoint

- The initial Workspace used a fixed four-column status grid and fixed two-column panel grid. The follow-up implementation changes both to adaptive grids with bounded item widths: status 150–240 points; panels 320–560 points. These are provisional responsive metrics, not final IPDS breakpoints.
- Branch: `feat/workspace-adaptive-layout`; base: PR #18 head `08d7b68ef14dbbce57752ce7b7f0215404a281cb`; implementation commit: `db073848e7a80bbd4db2868faa741725698cb86c`.
- Owner confirms the app launches on the Mac and has been exercised across two displays. Record this as OWNER-CONFIRMED; it is not independent visual QA or evidence of accessibility acceptance.
- Current Library retrieval did not surface the original ATP-ARCH-014/037/038 or IPDS files. The Q&A and Codex archives are not substitutes; M00-021 and M02-009 remain IN PROGRESS.
- No trading, broker, risk, credential, or LIVE behavior was introduced.


### PR #22 adaptive Workspace layout — current checkpoint

- PR #22 is OPEN and stacked on PR #18; base head `08d7b68ef14dbbce57752ce7b7f0215404a281cb`. The branch received documentation follow-ups after PR creation, so use the live PR metadata for the current head.
- Exact-head CI on the final revision is pending; earlier workflow attempts on prior heads do not qualify. No exact-head pass is claimed.
- Owner-confirmed application launch and two-display use are recorded separately from independent visual/accessibility acceptance.


## 2026-11-17 continuation revalidation — ATP-2026-11-17-019

- M02-009 remains IN PROGRESS. PR #22 exact HEAD `3931c937708d4adad7a9595657015d478787f418` passed CI #160 (repository hygiene/Markdown lint, backend typecheck/tests, macOS Debug/XCTest/Release, Swift CodeQL) and Local Sync Safety #167. This supersedes the earlier pending exact-head CI note.
- PR #10/#17/#18/#22 remain open and unmerged in the required dependency chain. Their inspected exact-head CI and Local Sync Safety runs passed: #10 CI/CodeQL #117 and safety #48; #17 CI #132 and safety #82; #18 CI #155 and safety #145; #22 CI #160 and safety #167.
- Owner-confirmed launch/two-display use is not exact-build visual or accessibility acceptance. Local Xcode/XCTest evidence and screenshots remain outstanding; do not mark M02-001 or M02-009 DONE.
- Formal ATP-ARCH-014/037/038 and original IPDS source/approval reconciliation remains outstanding. Adaptive width metrics remain provisional.
- Next acceptance: read-only local preflight, then exact-revision local Debug → XCTest → Release and owner visual/accessibility review on both displays. Preserve all uncommitted local work; no synchronization or branch switch until preflight is reviewed.


## Command Center and ATP-WORKSPACE-001 — 2026-11-17

- PR #24 remains OPEN / DRAFT on `feat/macos-command-center-ipds`, stacked directly on PR #18 head `08d7b68ef14dbbce57752ce7b7f0215404a281cb`.
- Command Center source is implemented in `CommandCenterView.swift`; `WorkspaceHomeView` delegates to it. Market, broker, account and execution values remain explicitly unavailable; no synthetic financial data or dealing controls were introduced.
- ATP-WORKSPACE-001 is IN PROGRESS. `WorkspaceEngine.swift` now contains typed workspace/profile/panel/layout models, stable identities, versioned snapshots, a persistence protocol, UserDefaults persistence, observable state, workspace creation/selection/rename, panel visibility, reset/save/restore, validation, and safe recovery paths.
- Command Center now reads panel visibility and width constraints from the engine. Panel reorder/resize UI, full profile management, independent windows, window restoration, and multi-display behavior remain unimplemented.
- Added deterministic in-memory persistence XCTest coverage for visibility persistence/restoration, workspace creation, duplicate panel identity, unsupported schema, and unreadable stored data recovery.
- Latest implementation head at this record: `59f5e363356f6e3cbac6e79df02c8d0b1d1a5a07`. Local Sync Safety #207 passed. Exact-head CI #174 is queued; no macOS build/XCTest result is claimed.
- Owner Mac build, runtime, and visual qualification for PR #24 remain pending. Do not mark M02-009 or ATP-WORKSPACE-001 DONE before exact-head CI and owner-side qualification.


## ATP-MD-001 — Capital.com DEMO and Market Data Infrastructure (2026-11-17)

| ID | Priority | Task | Status | Acceptance evidence / dependency |
|---|---|---|---|---|
| ATP-MD-001A | P0 | Implement Capital.com DEMO REST session and read-only market endpoints | IN PROGRESS | PR #25 source; exact-head CI and real DEMO auth still required |
| ATP-MD-001B | P0 | Implement backend session lifecycle and loopback market-data API | IN PROGRESS | PR #25 source; exact-head tests and local integration qualification required |
| ATP-MD-001C | P0 | Resolve and implement Capital.com DEMO WebSocket streaming | BLOCKED | Official provider confirmation of DEMO streaming host required |
| ATP-MD-001D | P0 | Implement quote validation, freshness, disconnect and recovery contracts | IN PROGRESS | Initial quote/freshness contracts in PR #25; stream lifecycle and approved thresholds pending |
| ATP-MD-001E | P1 | Bind Market Watch to authenticated provider stream | BLOCKED | Requires ATP-MD-001C and real DEMO integration evidence |
| ATP-MD-001F | P1 | Bind Charting Engine to validated provider candles | BLOCKED | Requires streaming/candle contracts and provider integration evidence |

PR #25 is stacked on PR #24 to preserve the existing Command Center and Workspace. No synthetic market data or dealing capability is permitted.


## Broker Management and Capital.com DEMO Authentication — 2026-11-17

| ID | Priority | Task | Status | Acceptance evidence / dependency |
|---|---|---|---|---|
| ATP-BROKER-001A | P0 | Add Settings → Brokers native navigation and broker-management screen | IN PROGRESS | Feature branch `feat/broker-management-keychain-demo`; runtime verification pending |
| ATP-BROKER-001B | P0 | Add Keychain-backed broker/environment credential storage | IN PROGRESS | Keychain implementation isolates broker, environment, and account login identity inside the protected Keychain item; update operations preserve the existing device-only accessibility policy; account-specific load/delete tests added; macOS execution pending |
| ATP-BROKER-001C | P0 | Add Capital.com DEMO REST authentication and session verification | IN PROGRESS | POST /session + GET /session + DELETE /session implemented from official contract; URLProtocol tests cover request fields, token headers, 401 redaction, and LIVE rejection; no owner credentials or live DEMO result |
| ATP-BROKER-001D | P1 | Add session expiry monitoring and safe re-authentication | IN PROGRESS | Read-only GET /session health verification runs every 60 seconds while the Brokers view is active; explicit re-authentication remains manual |
| ATP-BROKER-001E | P1 | Complete credential deletion, failure, cancellation, and persistence qualification | IN PROGRESS | Source paths and XCTest coverage added for storage, account/environment isolation, deletion, auth failures, and network contract; timestamp persistence and owner-Mac verification remain pending |
| ATP-BROKER-001F | P1 | Perform real Capital.com DEMO authentication and capture sanitized evidence | BLOCKED | Requires owner-provided DEMO credentials through local Keychain only |
| ATP-BROKER-001G | P0 | Resolve Swift 5.8 MainActor default-argument build failure found during owner-Mac qualification | IMPLEMENTED — requalification pending | Injected authentication dependency now defaults to nil and is constructed inside the MainActor-isolated ViewModel initializer; added default-composition XCTest; exact-head Debug/XCTest/Release and owner-Mac rerun required |

The implementation branch is stacked on PR #25 head to retain the existing app and DEMO provider baseline. PR #24 and PR #25 source branches and HEADs are not modified. LIVE remains blocked; market streaming and trading remain separate and disabled.


## PR #26 qualification remediation — 2026-11-17

- Owner-Mac qualification after commit `a1c6c471a0a9a7cfc82a9a30299e7bbdffa9cfb9` confirmed Debug compilation and 34 of 35 XCTest cases passing; the single failure is `CapitalComAuthenticationTests.testDemoAuthenticationUsesOfficialRequestContractAndVerifiesSession()` at the post-URLSession `httpBody` unwrap. The exact-head hosted macOS XCTest job failed at the same assertion; its Release step was skipped and the Apple Silicon job was cancelled.
- GitHub defect reports: [#27 request-body capture](https://github.com/atheertrading/atheer-trading-platform/issues/27), [#28 URLSession Sendable diagnostics](https://github.com/atheertrading/atheer-trading-platform/issues/28), and [#29 Brokers UI freeze investigation](https://github.com/atheertrading/atheer-trading-platform/issues/29).
- Remediation prepared: the test recorder captures request bytes at the URLProtocol interception boundary, supporting both `httpBody` and `httpBodyStream`; assertions decode JSON and verify identifier, password, and encryptedPassword=false. Production authentication code is unchanged in this correction.
- Next gates: focused Capital.com test and full XCTest; resolve/justify Swift 5.8 URLSession Sendable diagnostics; reproduce and isolate the UI freeze; then complete Debug → XCTest → Release on Intel and Apple Silicon and owner-Mac runtime/navigation QA.
- This record does not claim the new test patch has compiled or passed. PR #26 remains Open/Draft; PR #24/#25, LIVE restrictions, dealing boundaries, and risk controls are unchanged.


## PR #26 owner-Mac qualification and AppKit/concurrency remediation — 2026-11-17

- Session report: `SESSION_2026-11-17_020_PR26_OWNER_MAC_QUALIFICATION.md`.
- Baseline owner report **The terminal on Hossam's Mac - 02** confirms exact source HEAD `0e7f25edb65e6a6a41b86b6f4513231d36edf79e`, Intel/macOS 13.7.8/Xcode 14.3.1/Swift 5.8.1, Debug and Release build success, and 35/35 XCTest success.
- The Release log explicitly shows a universal `arm64 x86_64` binary creation step. This is build-slice evidence, not Apple Silicon runtime qualification.
- Baseline runtime diagnostics: four URLSession Sendable warnings; SwiftUI List-backed panel row mutations identified as the AppKit NSTableView reentrancy path; backend liveness connection refused because the local process was not listening.
- Remediation now present in source: isolated URLSession request executor and deferred panel List row mutations. Post-remediation build/tests remain pending exact-head CI and owner-Mac rerun.
- Baseline exact-SHA CI #222: repository hygiene and backend toolchain passed; Intel and Apple Silicon macOS jobs were cancelled. Local Sync Safety #319 passed.
- ATP-BROKER-001 remains IN PROGRESS. Real Keychain restart test, normal Intel runtime/visual QA, backend integration with service running, Apple Silicon runtime QA, and real DEMO auth remain outstanding.
- PR #26 remains Open/Draft. LIVE and dealing remain disabled; no RiskEngine, execution, or broker-permission changes.



- Follow-up `f22cac58682910256049541c252b6e54bf17c682` also defers ContentView sidebar selection changes outside the NSTableView delegate callback. The reentrancy warning is not marked resolved until owner-Mac runtime confirms it no longer occurs.

## ATP-MKT-001 — Market Explorer / Instrument Search — 2026-11-17

| Work item | Priority | Status | Dependencies | Acceptance gate |
|---|---|---|---|---|
| Implement native Market Explorer with provider-backed DEMO instrument search | P1 | IMPLEMENTED ON FEATURE BRANCH — VERIFICATION PENDING | PR #24 Workspace/Command Center; PR #25 Capital.com DEMO market search; PR #26 broker management | Review focused PR; exact-head hygiene/backend/macOS Debug/XCTest/Release/CodeQL checks; owner-Mac build/runtime/visual/accessibility QA |

- Branch: feat/macos-market-explorer, stacked on PR #26 head 9f46a5ce9fc313e73dbff9e78680804c4dd1692f.
- PR #31: https://github.com/atheertrading/atheer-trading-platform/pull/31 (OPEN / DRAFT; not merged).
- Initial exact-head CI #44159176929 on 94766cfe98ff3238e3c42d0560335d45395df163: Repository Hygiene and Backend Toolchain passed; Intel and Apple Silicon macOS jobs queued. Local Sync Safety #44159176655 passed. Re-run and re-record checks after any new commit.
- Screen ID: ATP-SCR-MKT-001.
- Prompt: docs/development/ATHEER_CHATGPT_SCREEN_IMPLEMENTATION_EXECUTION_PROMPT.md.
- Screen contract: docs/product/ATHEER_SCREEN_AND_WORKFLOW_INVENTORY.md.
- Search is read-only and requires backend status connected in DEMO. No streaming, quote, chart, order, or trading capability is claimed.
- Native app Keychain credentials are not automatically transferred to the backend session; secure handoff remains a separate task.
- No build or XCTest execution is claimed until exact-head CI or owner-Mac evidence is available.


## ATP-MKT-002 — Market Explorer Search Lifecycle Hardening — 2026-11-17

| Work item | Priority | Status | Dependencies | Acceptance gate |
|---|---|---|---|---|
| Prevent stale/out-of-order Market Explorer search responses; align query validation and add deterministic race tests | P1 | IMPLEMENTED ON FOCUSED BRANCH — VERIFICATION PENDING | PR #31 Market Explorer | Exact-head hygiene/backend/macOS Debug/XCTest/Release/CodeQL; owner-Mac runtime, keyboard/focus, visual and VoiceOver QA |

- Branch: `fix/market-explorer-search-lifecycle`, based on PR #31 exact head `66de2c54cf1ae8156bd3b3e1c8447ae2dfe5e4be`.
- Session report: `SESSION_2026-11-17_022_MARKET_EXPLORER_SEARCH_LIFECYCLE.md`.
- Added generation guards for search and status requests; query edits invalidate prior responses; search eligibility enforces 1–100 characters; accessible query-length counter added.
- Added XCTest cases for 101-character query rejection and out-of-order completion.
- No CI, local build, or runtime result is claimed yet. Follow with HTTP contract tests after this increment is qualified.


- Follow-up PR #33: https://github.com/atheertrading/atheer-trading-platform/pull/33 (OPEN / DRAFT), PR-creation head `a0d6164dbed794cb2d83f211146412bab7a0787f`; latest recorded branch head `2750d272e21c2cb39024f55d016dd178c2bad914`; stacked on PR #31 exact head `66de2c54cf1ae8156bd3b3e1c8447ae2dfe5e4be`.
- CI run #44170771670 on `2750d272`: Backend Toolchain passed; Repository Hygiene failed on this line due an unmatched Markdown code span; Intel and Apple Silicon macOS jobs were queued. Local Sync Safety #44170771652 passed. The documentation lint defect is corrected in the next commit; macOS verification remains pending.
- Initial exact-head CI #44170652406: Repository Hygiene passed; Backend Toolchain in progress; Intel and Apple Silicon macOS jobs queued. Local Sync Safety #44170652465 passed. macOS verification remains pending.

## ATP-MKT-002 MainActor build remediation — 2026-11-17

The exact-head Intel macOS CI job for PR #33 failed during Debug compilation on actor-isolated URLSessionMarketSearchClient default arguments in MarketExplorerView and MarketExplorerViewModel. Both now accept optional injected dependencies and construct the default client inside the MainActor-isolated view-model initializer. Requalification on the corrected head is pending; no macOS pass is claimed.


## ATP-UI-ARCH-001A — Market Explorer presentation boundary separation

| Work item | Priority | Scope | Status | Evidence |
|---|---:|---|---|---|
| ATP-UI-ARCH-001A | P1 | Keep provider DTOs in infrastructure, expose semantic market models, separate ViewModel, inject client at composition root | IMPLEMENTED; exact-head CI pending | PR #33; private provider DTOs, semantic model mapping, separate injected ViewModel, shared Sendable URLSession executor, ephemeral no-cookie/no-cache session, URLProtocol endpoint/query/status/transport regression coverage |

Acceptance:
- SwiftUI and ViewModel consume only provider-independent semantic models.
- Provider JSON DTOs remain private to the infrastructure adapter.
- ViewModel requires an injected `MarketSearchClient`; it cannot construct a production URLSession client.
- The app composition root selects and injects the production adapter.
- Existing query length, DEMO-only provider validation, disconnected-state gating, and stale-search suppression remain covered by XCTest.


## 2026-11-18 integration checkpoint — PR #24 / #25 / #26

| Pull request | Result | Merge commit |
|---|---|---|
| #24 — Workspace / Command Center foundation | MERGED 2026-11-18 | `bd83fd3c8df481104c347f05d9d4f38537d8b011` |
| #25 — Capital.com DEMO market-data foundation | MERGED 2026-11-18 | `6b570b8c5a3367784cde7fa2643593c5b5a1eda2` |
| #26 — Secure Capital.com DEMO broker management | MERGED 2026-11-18 | `6b4668b9355178d5e13219f14cfe8cc847770915` |

- These merge results supersede older task-register statements that PR #24/#25/#26 remained OPEN / DRAFT.
- PR #26 exact-head hosted CI run `44231098511` passed Intel x86_64 Debug/XCTest/Release/Swift CodeQL, Apple Silicon arm64 Debug/XCTest/Release, Backend Toolchain, and Repository Hygiene. Dedicated CodeQL `44231098441` and Local Sync Safety `44231098576` passed.
- `ATP-BROKER-001` remains IN PROGRESS: owner-Mac Keychain restart/runtime QA on the merged head and real Capital.com DEMO authentication are still outstanding. LIVE/dealing remains disabled.
- PR #33 is retargeted to `main` after PR #26 merge; current head `8885fd6f43098421973d098b2cd3d94a8e7545e3`; exact-head CI is running. Do not merge until Intel/Apple Silicon, backend and hygiene checks pass.


## ATP-SEC-001A — Native local API request marker (cross-PR)

| Work item | Priority | Scope | Status | Evidence |
|---|---:|---|---|---|
| ATP-SEC-001A | P1 | Require native client marker and reject browser-origin access to local market-data routes | IN PROGRESS | PR #33 native Market Search sends `X-ATHEER-LOCAL-CLIENT: macOS`; PR #37 implements server-side Origin/Sec-Fetch-Site enforcement and regression tests. Both PRs must be integrated together. |

The marker is not a secret and does not authenticate arbitrary local processes. It mitigates browser CSRF/cross-origin access only; production still requires a per-launch capability token or authenticated local IPC.


## ATP-BRK-002 — Centralized backend credential and broker-session authority

| Work item | Priority | Scope | Status | Evidence |
|---|---:|---|---|---|
| ATP-BRK-002 | P0 | Unify macOS Keychain credential provisioning, backend CMS, Capital.com authentication and CST/X-SECURITY-TOKEN lifecycle behind one backend session authority | BLOCKING PR #37 integration | Library Broker Integration Q5/Q6; PR #26 Swift direct-auth; PR #37 environment-driven backend auth; EDL-022 |

Required: app-managed backend child process; 256-bit per-launch capability bootstrapped over private stdin/pipe; bearer auth for local control APIs; backend CMS backed by a Keychain helper/adapter; environment credentials test-only; one Broker Session Manager shared by market data, streaming, account data and future OMS. Add isolation, secret-redaction, IPC authorization, reconnect and token lifecycle tests.

## ATP-BRK-003 / ATP-MKT-007 — Connection and subscription orchestration

| Work item | Priority | Scope | Status | Evidence |
|---|---:|---|---|---|
| ATP-BRK-003 | P1 | Enforce session-creation rate limit, REST keepalive scheduling, session recovery and account-switch coordination | PARTIAL | PR #37 coalesces concurrent connects and exposes `ping()`; sequential throttle and scheduled ping are not implemented |
| ATP-MKT-007 | P1 | Allocate 40 WebSocket instrument slots by operational priority and restore after reconnect/account switch | PARTIAL | PR #37 shared WebSocket, 40-cap, dedupe, heartbeat and reconnect are implemented; priority allocator and utilization metrics remain |

Do not conflate REST request-rate limits, authenticated REST session inactivity, WebSocket heartbeat/duration and the 40-instrument subscription cap. Do not invent undocumented provider connection limits.

## PR #33 — Market Explorer integration

- Status: MERGED 2026-11-18.
- Merge commit: `2e8bf9bd5f4274ed5d500474335a778cd6f9b75c`.
- Tested head: `04e70808d5cb403b6a7b8e05ceb41dc335e3d4cf`.
- CI `44235123474`, CodeQL `44235124217`, Local Sync Safety `44235123457`: all successful.
- Owner-Mac visual/runtime and authenticated DEMO acceptance remain pending.


## ATP-BRK-002 — Native supervisor shutdown qualification update (2026-11-18)

- PR #57 now distinguishes exit code 0, non-zero backend exit, and signal/forced termination. Non-zero or unclean termination is surfaced to the view model after process and capability state are cleared.
- Tests cover graceful SIGTERM, forced SIGKILL, non-zero exit status, startup cancellation and idempotent stop.
- `CAP_ALLOW_TRADING=false` is explicitly set in the child environment.
- Operation-specific stderr diagnostics are still discarded by the native supervisor; only the overall failure status is surfaced. Filtered diagnostic capture remains open.
- Latest code head `4a55032511125d98a9cb4861c8ab4173bea42a3e`; exact-head CI is pending.
