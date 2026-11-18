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
| M01-005 | P1 | Define OMS, Execution Gateway, idempotency, outbox, and reconciliation | IN PROGRESS — ATP-OMS-001; OEL-12 and risk-gated durable OMS order persistence implemented in PR #42; outbox consumer, Gateway, broker events, fills, and reconciliation remain pending |
| M01-006 | P1 | Define AI orchestration, agent permissions, and tool contracts | PENDING |

## M02 — Product foundations

| ID | Priority | Task | Status |
|---|---|---|---|
| M02-001 | P2 | Qualify macOS/Xcode/Swift compatibility and app structure | IN PROGRESS |
| M02-002 | P2 | Specify and implement IPDS primitives and semantic tokens | PENDING |
| M02-003 | P2 | Establish backend service foundation and API contracts | IN PROGRESS |
| M02-004 | P2 | Establish automated tests and local developer workflows | IN PROGRESS |
| M02-005 | P2 | Integrate backend health into the macOS workspace | IN PROGRESS — PR #10 exact head `06bd496d957b6cd2f999209cf5dc83cae54251cf` passed hosted CI #117; owner Mac XcodeGen/Debug/XCTest/launch are owner-confirmed; owner supplied /health/live 200 and /health/ready 503 expected payload. App-panel verification remains pending in PR #17. |
| M02-006 | P2 | Implement non-destructive local synchronization and workstation bootstrap | IN PROGRESS |
| M02-007 | P2 | Implement first native multi-screen navigation and API Connection screen | IN PROGRESS — PR #17 `feat/macos-workspace-api-connection`; exact-head workflow #132 passed backend, hygiene, macOS Debug/XCTest/Release and Swift CodeQL jobs; owner runtime QA pending |
| M02-008 | P2 | Establish native application-wide copy/paste foundation | IN PROGRESS — Issue #16 first increment in PR #17; workflow #132 passed on its exact head; full control audit and owner runtime QA pending |
| M02-009 | P2 | Implement shared IPDS token foundation and initial operational workspace panels | IN PROGRESS — PR #18 source head `331f424d6d1180569504b725cbcaa1eece41ed46`; exact-head hosted workflow #135 passed repository hygiene/Markdown lint, backend typecheck/tests, macOS Debug build, XCTest, Release build, and Swift CodeQL. Local Mac qualification is active on `work/local-pr18-qualification`; local build/test/launch and visual/accessibility QA remain pending. Formal IPDS source/approval reconciliation remains pending. |

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
| M00-021 | P1 | Reconcile the 47 formal documents, 517 Q&A sources and approval metadata | IN PROGRESS | Existing source inventory; document-level authority/revision/approval traceability pending |

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


## ATP-MKT-003 — Capital.com DEMO Market Streaming Foundation — 2026-11-17

| Work item | Priority | Status | Dependencies | Acceptance gate |
|---|---|---|---|---|
| Provider WebSocket quote ingestion, shared subscription manager, quote validation, and local SSE relay | P1 | IMPLEMENTED ON FOCUSED BRANCH — VERIFICATION PENDING | PR #25 DEMO REST runtime; PR #31 Market Explorer; PR #33 search lifecycle | TypeScript/API CI, stream lifecycle tests, provider DEMO verification, loopback transport security review |

- Branch: `feat/capital-demo-market-streaming`, based on PR #33 head `61b0953a04047868f000709369e2a182b3db34d4`.
- Session report: `SESSION_2026-11-17_023_CAPITAL_DEMO_STREAMING.md`.
- Architecture: `ATHEER_MARKET_DATA_STREAMING_ARCHITECTURE.md`; Mermaid diagram: `09-capital-demo-market-data-streaming.mmd`.
- Implemented provider session endpoint discovery, WSS validation, server-side token handling, shared 40-instrument subscription cap, correlation acknowledgements, five-minute ping, reconnect/resubscribe, quote quality checks, in-memory cache, and loopback SSE.
- No CI or real-provider success is claimed yet. macOS consumer, historical persistence, OHLC streaming, Charting, and RiskEngine integration remain separate follow-up work.


## ATP-MKT-004 — Existing Market Explorer Live Quote Integration — 2026-11-17

| Work item | Priority | Status | Dependencies | Acceptance gate |
|---|---|---|---|---|
| Connect existing Market Explorer to backend DEMO SSE stream with explicit selection and timestamped quote presentation | P1 | IMPLEMENTED ON FOCUSED BRANCH — VERIFICATION PENDING | PR #34 streaming backend | Intel + Apple Silicon Build/XCTest/Release/CodeQL; owner-Mac visual/accessibility/runtime QA; provider DEMO verification |

- Branch: `feat/macos-market-explorer-live-quotes`, based on PR #34 head `1378cc9d78151dc58bc548887ff5a3c45594d62b`.
- Session report: `SESSION_2026-11-17_024_MARKET_EXPLORER_LIVE_QUOTES.md`.
- Adds URLSession SSE parser/client, explicit selection and Start/Stop/Clear controls, maximum 40 instruments, quote state, timestamp, age, and arrival-time quality presentation.
- No new screen, no synthetic prices, no trading action, and no RiskEngine integration.
- Hosted macOS and owner-Mac verification remain pending; no real provider quote is claimed.

## ATP-MKT-003 MainActor build remediation — 2026-11-17

The initial Intel macOS job for PR #34 reached Debug compilation and failed because Swift 5.8 evaluates actor-isolated service default arguments from a nonisolated caller context. The Market Explorer view and view-model now accept optional injected clients and instantiate the default URLSession client inside the MainActor-isolated view-model initializer. This is a source remediation only; exact-head hosted requalification remains pending. PR #34 remains open/draft and unmerged.

## ATP-MKT-004 branch replacement and CI evidence — 2026-11-17

- Original PR #35 was closed as superseded after its branch became divergent from the corrected PR #34 head.
- Replacement PR #36: https://github.com/atheertrading/atheer-trading-platform/pull/36.
- Branch: feat/macos-market-explorer-live-quotes-qualified; exact head at this checkpoint: 80912e8b1e80479afaa694f3bbf0e04ab5e1fce8.
- Base: feat/capital-demo-market-streaming at exact head 2baf8a2b026566846825a18e9b9af9a918c0d864; comparison is 11 commits ahead / 0 behind.
- Exact-head CI #44177274649: Repository Hygiene passed; Backend Toolchain passed; TypeScript build and 31/31 API tests passed. Mermaid diagram validation #44177274622 passed; Local Sync Safety #44177274600 passed.
- Intel and Apple Silicon macOS Debug/XCTest/Release/Swift CodeQL jobs remain queued. Owner-Mac runtime, visual, keyboard/focus, VoiceOver, and real DEMO provider verification remain pending.
- Source includes epic validation, 100 ms UI presentation coalescing, and cancellation of the presentation throttle when streaming becomes ineligible. No risk/execution integration or LIVE capability is introduced.

## PR chain consolidation — 2026-11-17

PR #33 now consolidates the original Market Explorer and search-lifecycle hardening directly on PR #26, including the Swift 5.8 MainActor dependency-construction fix. PR #31 is closed as superseded. PR #37 is the replacement Capital.com DEMO streaming backend, based directly on corrected PR #33 head 3b609eb259f8961d1e4c1b350a7e8edce1cf1ef1 (16 ahead / 0 behind). Exact-head verification is pending.

## ATP-MKT-005 — Historical Market Data Contracts — 2026-11-17

**Status:** Implemented on focused branch; source correction backend verified; final documentation-updated PR head requires exact-head revalidation.

- Added provider-neutral historical candle normalization in `services/api/src/market-data/historical-prices.ts`.
- Bid and Ask OHLC are represented independently; UTC provider timestamp and local receipt timestamp remain distinct.
- Preserved optional `lastTradedVolume` as provider lineage without assigning unsupported volume semantics.
- Exact duplicate candles are counted/dropped; conflicting duplicate timestamps are rejected.
- Observed time gaps are reported but remain unclassified until an authoritative market-session calendar is available.
- Extended DEMO history requests with paired UTC `from/to` bounds and provider `max` limit 1–1000.
- Updated `GET /market-data/history` to return normalized candles and validation/quality metadata.
- Added normalization, provider request, and API route tests.
- Review correction: `pagination.limitReached` now uses the raw provider record count before exact-duplicate removal. Regression coverage verifies two identical provider records at `max=2` normalize to one candle while preserving `limitReached=true`.
- Current PR #39 head: `d6bca573c28ca71b38cb10c9313e86c517b68f08`.
- Exact-head Backend Toolchain passed Node 24.22.2 type-check/build and **37/37 API tests** (run #44182796685, job #134391313681); Repository Hygiene passed; Local Sync Safety passed (run #44182796765).
- Mermaid validation remains in progress (run #44182796666); Intel x86_64 and Apple Silicon arm64 macOS jobs remain queued (jobs #134391313683 and #134391313955). The prior 37/37 result on head `5cc73cca...` is superseded by this exact-head run.
- Pagination review thread `PRRT_kwDOVv-R8M64qo9E` was resolved after the correction and regression test passed.
- Documentation: `ATHEER_HISTORICAL_MARKET_DATA_ARCHITECTURE.md`, Mermaid diagram 10, session report 025.
- Persistence is not implemented in this work package. PostgreSQL remains the recorded direction, with deployment/workload qualification pending.
- No live provider test, Charting integration, market calendar, or durable storage is claimed.
- Safety: DEMO read-only; `CAP_ALLOW_TRADING=false` unchanged; no order/dealing or RiskEngine/OMS integration.


## PR #38 / PR #39 Swift 5.8 stream-test remediation — 2026-11-18

- Hosted Intel XCTest compilation on PR #38 head `0d37f11a8f91d09c82b39c443e346622a7df3530` exposed an async test missing `throws` and two incorrectly constructed quote-event values. The exact failure is recorded in CI run #44178484275, job #134376144630.
- Corrected the test declaration and quote factory calls; applied the same tested source patch to `MarketSearchClient.swift` using `@preconcurrency import Foundation` on both branches.
- PR #38 new source head: `f07548eb0233e5113de794f69a8840b3bdd6841f`; PR #39 source head: `59ddc5eaf5881930e37ba8ee10074faf1b5d3337`.
- Owner-reported Intel Debug/XCTest evidence: 48/48 tests passed on macOS 13.7.8 / Xcode 14.3.1 / Swift 5.8.1 against PR #39 base plus the two local source-file changes; report is recorded in PR #39 comment 6962746664. It is not an exact-clean-commit hosted result.
- New exact-head CI was pending/in progress; Local Sync Safety passed on both source heads; Mermaid validation was running. Release, arm64, visual/accessibility QA and real DEMO provider verification remain outstanding.
- PRs #38 and #39 remain OPEN / DRAFT. No merge or history rewrite. `CAP_ALLOW_TRADING=false` remains unchanged.
- Detailed record: `SESSION_2026-11-18_027_SWIFT58_MARKET_STREAM_QUALIFICATION.md`.


## ATP-DOMAIN-001 — Canonical Trading Domain Foundation — 2026-11-18

**Status:** Foundational contract slice implemented on PR #40; exact-head verification pending. PR #40 remains OPEN / DRAFT and is stacked on PR #39.

- Added `services/api/src/domain/` with branded identifiers, exact decimal values, UTC timestamps, environment isolation, source provenance, instrument identity/specification, broker account identity/snapshots, immutable order-intent envelopes, risk assessments, generic lifecycle-policy validation, broker order/position observations, execution fills/events, reconciliation and audit records.
- Instrument metadata preserves broker identity + environment + exact broker instrument identifier. Price precision and tick increment remain distinct; minimum/maximum deal size, quantity increment, lot size and contract size remain separate and unit-bearing.
- Financial values use canonical base-10 strings and BigInt comparison/alignment. No float coercion or implicit rounding.
- Common intent envelopes include intent/command/correlation/idempotency identity, account/instrument/specification/environment, origin, optional strategy/agent provenance, signal time, and market-snapshot reference/time.
- Risk decisions are separate records bound to intent and policy version. No domain function transmits broker commands.
- Added `services/api/test/domain.test.mjs` and Mermaid diagram 11.
- Original ADR-0004/ADR-0005/ADR-0006 texts were not present in the accessible Library archives. UUIDv7 remains a Q&A recommendation, not an adopted identifier implementation; detailed OMS/position states and rounding modes remain open. No unsupported state machine was invented.
- Initial CI #44193072976 on earlier head `13bc60e...` passed Repository Hygiene but failed backend typecheck on two branded-ID comparisons. Those were corrected; current source head `f295023e...` has not yet received exact-head CI. Node 24 local verification is not claimed.
- No PostgreSQL schema/migration/outbox, broker dealing, account mutation, LIVE, or production capability added. `CAP_ALLOW_TRADING=false` unchanged.
- Detailed report: `SESSION_2026-11-18_028_ATP_DOMAIN_001_FOUNDATION.md`.


### ATP-DOMAIN-001 follow-up — strict UTC timestamp parsing (2026-11-18)

- Added calendar-aware validation to `utcTimestampFromIso`; invalid dates such as February 31 can no longer normalize into a different UTC instant.
- Added regression tests for leap-year validity, month lengths, invalid month, and clock ranges.
- Fix commit: `7ebe46ce7abd104cb74345169e16dbe64cb87998`.
- Exact-head CI is pending for this commit. Prior head `34015bda...` had 46/46 backend tests and Intel x86_64 qualification passed; Apple Silicon remained queued. Do not carry those results onto the new head.

## ATP-PERSISTENCE-001 — PostgreSQL durable trading journal — 2026-11-18

- PR: #41, stacked on PR #40 (`feat/trading-domain-foundation`).
- Added pinned `pg` 8.23.1 runtime dependency and generated npm lockfile.
- Added PostgreSQL schema for instruments/specifications, broker accounts/snapshots, order intents, risk assessments, reconciliation events, audit events, and domain outbox.
- Added transaction-scoped advisory-lock migration runner with version ledger and SHA-256 checksum drift rejection.
- Added environment-pinned repository adapter, canonical JSON hashing, idempotent intent/risk persistence, conflict detection, and transactional audit/outbox writes.
- Added PostgreSQL integration tests and PostgreSQL 17 CI service. Exact-head results remain pending; no local PostgreSQL, Node 24, production database, or Mac qualification is claimed.
- Outbox event allow-list is restricted to durable domain-record events. No dispatcher, broker order submission, or execution-dispatch event is implemented.
- `CAP_ALLOW_TRADING=false` remains unchanged. No LIVE or production operation is enabled.
- Remaining before batch completion: inspect exact-head CI, resolve all source/test findings, add failure/recovery and concurrency evidence, and update operational database setup/backup/restore guidance.

- Operational safety refinement: API startup verifies the applied migration ledger/checksums and never auto-applies schema changes. Pending migrations are applied only through explicit `npm run migrate`; PostgreSQL setup and migration instructions are in `docs/operations/POSTGRESQL.md`.
## ATP-PERSISTENCE-001 — PostgreSQL follow-up qualification — 2026-11-18

| ID | Priority | Task | Status | Acceptance evidence / dependency |
|---|---|---|---|---|
| ATP-PERSISTENCE-002 | P0 | Align migration runner with NOINHERIT migrator and canonical `atheer` schema | DONE ON PR #41; HOSTED VERIFIED | `SET LOCAL ROLE atheer_db_owner` within migration transaction; all ledger, migration and repository SQL schema-qualified |
| ATP-PERSISTENCE-003 | P0 | Add least-privilege PostgreSQL integration tests | DONE ON PR #41; HOSTED VERIFIED | NOINHERIT migrator and app role; table ownership verified; migrator/app direct table CREATE denied; app repository DML exercised |
| ATP-PERSISTENCE-004 | P1 | Qualify owner-local PostgreSQL 18.7 after exact-head CI | BLOCKED / NOT RUN | Controlled local migration qualification plan; preserve current database and grants; no `npm run migrate` until exact-head CI is green and plan reviewed |
| ATP-PERSISTENCE-005 | P1 | Verify default sequence privileges and document operational recovery | IN PROGRESS | Regression test added for owner-created sequence, app `nextval`, and app/migrator CREATE denial; exact-head CI pending. Backup/restore, retention, PITR, TLS, role provisioning and restore-drill docs remain outstanding |

### Evidence and guardrails

- Code-bearing head `94cc13d13f56fd1f2efa450747e72dc841f65017`: run `44207522335` passed Backend type-check and 49/49 PostgreSQL 17.12 integration tests; Repository Hygiene, Mermaid, and Local Sync Safety passed; Apple Silicon Debug/XCTest/Release passed (CodeQL skipped); Intel Debug/XCTest passed with Release in progress and CodeQL pending at last inspection.
- Sequence privilege regression test was added afterward in commit `78a774289de6ccea0fe49c89c7877f65c8246828`; it is not covered by the previous 49/49 result.
- Owner local foundation: Postgres.app PostgreSQL 18.7 on macOS 13.7.8 Intel, loopback-only at 127.0.0.1:5432; database `atheer_trading`, schema `atheer`, roles `atheer_db_owner`, `atheer_migrator`, `atheer_app`.
- Do not run local migrations until ATP-PERSISTENCE-004 exit conditions are met. Do not grant CREATE to `atheer_app` or PUBLIC; do not weaken role separation; keep `CAP_ALLOW_TRADING=false`.
- PR #41 remains OPEN / DRAFT and stacked on PR #40; no merge or approval is recorded.

### Follow-up batch snapshot — branch HEAD `434ae1191c6a66cafe30e98f21c5ee03a8a4faf8`

- Sequence privilege regression test and documentation reconciliation are committed; this branch HEAD is newer than the previously reported code-bearing head `94cc13d...`.
- Current exact-head workflows: Mermaid run `44209957024` in progress; Local Sync Safety run `44209957152` passed; CI run `44209957185` has Backend queued and Intel/Apple Silicon/Repository Hygiene in progress at inspection.
- The 49/49 Backend result applies to `94cc13d...` only and does not include the new sequence regression test. Do not carry it forward to `434ae119...`.

### Verified GitHub snapshot — 2026-11-18 (current PR #41 HEAD)

- PR #41 is OPEN / DRAFT; current HEAD `dba73544a768006bb8535f72c0a615fda42c88dd`, base is PR #40 HEAD `8d4afc4e59b2787a9252269cbcf11fa379bc65b6`.
- Backend toolchain run `44210034147`: completed successfully. The exact-head backend report is 49/49 PostgreSQL 17.12 integration tests, including the sequence privilege regression; TypeScript type-check passed.
- Repository Hygiene (`44210034147`): passed.
- Mermaid render (`44210034098`): passed.
- Local Sync Safety (`44210034195`): passed.
- Apple Silicon arm64 job `134485862385`: XcodeGen and project generation passed; Debug build is currently in progress; XCTest and Release are pending. CodeQL init is skipped by workflow configuration and is not a pass/fail result.
- Intel x86_64 job `134485862456`: XcodeGen installation is in progress; project generation, Debug, XCTest, Release, and CodeQL are pending.
- These platform results are still incomplete; do not mark PR #41 fully qualified until both architecture jobs finish and the final HEAD is rechecked.
- The 49/49 result is specific to this exact HEAD; do not transfer it to a later commit without rerunning CI.
- Local PostgreSQL 18.7 remains untouched; do not run `npm run migrate` until hosted exact-head qualification is complete and a controlled local qualification plan is approved.
- `CAP_ALLOW_TRADING=false` remains unchanged. No OMS worker, durable outbox consumer, Execution Gateway dispatcher, or broker order dispatch is implemented by this persistence PR.

### Architecture and next-batch notes

- Treat Mermaid diagram 05's Outbox → Execution Gateway path as target architecture, not implemented behavior. PR #41 currently persists domain outbox records only.
- Concrete OMS Order/Position state sets and transition semantics remain blocked on reconciliation with the authoritative formal ADR/specification sources; do not invent states.
- Preserve the invariant that workspace/panel visibility and trading runtime state are independent: hiding/closing a panel must not stop strategies, cancel orders, or close positions.
- The full Workstation reference `Professional Trading Screens, Workspace Architecture & User Experience.md` and the historical 52-block Mermaid export were not available in the current Library retrieval. Their complete reconciliation remains pending; do not claim otherwise.
- Next batch: complete Intel/arm64 qualification, recheck the exact PR head, then reconcile authoritative OMS/Execution specifications before designing ATP-OMS-001. No broker dispatch in that batch without separately approved controls.


## M01 / ATP-OMS-001 — Authorized OMS lifecycle persistence (PR #42)

| ID | Priority | Task | Status | Acceptance evidence / dependency |
|---|---|---|---|---|
| ATP-OMS-001A | P0 | Define OEL-12 state vocabulary and source-specific transition authority | IMPLEMENTED; CI PENDING | `services/api/src/domain/order-lifecycle.ts`; Q&A Section 18 Q1/Q11/Q12/Q16/Q17/Q18/Q20; domain tests |
| ATP-OMS-001B | P0 | Add environment-scoped durable OMS orders and append-only lifecycle events | IMPLEMENTED; CI PENDING | Migration `002_oms_lifecycle.sql`; exact risk-assessment/intent/account/instrument FKs; PostgreSQL integration tests |
| ATP-OMS-001C | P0 | Persist OMS order only from exact persisted AUTHORIZED assessment | IMPLEMENTED; CI PENDING | `persistAuthorizedOrder`; atomic order/event/audit/outbox transaction; idempotent replay and conflict tests |
| ATP-OMS-001D | P1 | Implement durable outbox lease/claim, fencing, and internal consumer | PENDING | Must prevent stale workers and duplicate delivery; no broker dispatch in this task |
| ATP-OMS-001E | P1 | Implement broker observation ingestion, execution fill ledger, and reconciliation | PENDING | Broker-authoritative state, duplicate/out-of-order protection, uncertain submission handling |
| ATP-OMS-001F | P1 | Implement Execution Gateway and DEMO-only qualification | BLOCKED BY SAFETY GATES | Only after outbox ownership, RiskEngine scope/expiry, capability checks, broker docs, reconciliation, and execution safety controls are qualified; preserve `CAP_ALLOW_TRADING=false` |

### ATP-OMS-001 guardrails

- `oms.order.persisted` is a domain notification only; no publisher, dispatch event, Execution Gateway, or broker dealing is implemented.
- No broker acknowledgement is represented as a fill. Only broker-confirmed execution reports may create fills.
- `UNKNOWN` and `RECONCILIATION_REQUIRED` are unresolved exception states. Never blindly retransmit uncertain submissions.
- Manual, strategy, algorithmic, and AI intents remain on the same centralized RiskEngine → OMS path.
- LIVE, broker permissions, and production financial actions remain protected.


## ATP-MARKET-001 — Command Center live Market Watch integration (PR #43)

| ID | Priority | Task | Status | Acceptance evidence / dependency |
|---|---|---|---|---|
| ATP-MARKET-001A | P0 | Implement versioned persistent watchlist with EPIC validation, deduplication, ordering, 40-item cap, and non-destructive recovery | IMPLEMENTED; CI PENDING | `MarketWatchlistStore.swift`; unit tests for round-trip, invalid/duplicate values, cap, ordering, recovery and persistence failure |
| ATP-MARKET-001B | P0 | Share one app-scoped market-data model between Market Explorer and Command Center | IMPLEMENTED; CI PENDING | `ContentView`, `WorkspaceHomeView`, `CommandCenterView`, `MarketExplorerView`; dependency injection and shared model tests |
| ATP-MARKET-001C | P0 | Replace Command Center Market Watch placeholder with real DEMO quote panel | IMPLEMENTED; CI PENDING | `MarketWatchPanelView`; provider Bid/Ask, spread, quote age, freshness, explicit stream controls |
| ATP-MARKET-001D | P0 | Keep market-data runtime independent from screen/panel visibility | IMPLEMENTED; CI PENDING | Stream model app-scoped; removed screen-disappearance pause; explicit Start/Stop and removal behavior |
| ATP-MARKET-001E | P1 | Implement native chart/candle engine with authenticated historical and live series | PENDING | Requires verified candle contract, timestamp normalization, aggregation, rendering and deterministic chart tests |
| ATP-MARKET-001F | P1 | Implement account/positions/risk panels from broker-authoritative snapshots | PENDING | Requires authenticated account API, canonical account/position persistence, RiskEngine integration |
| ATP-MARKET-001G | P1 | Implement governed order entry and OMS workflow | BLOCKED BY EXECUTION SAFETY GATES | Must use shared RiskEngine → OMS → Execution Gateway path; no UI direct broker calls |

### ATP-MARKET-001 guardrails

- Search and quotes are Capital.com DEMO read-only data.
- Market-data connection does not imply broker account authentication.
- No fake price, balance, position, P&L, market depth or fill is displayed.
- Removing a watchlist instrument removes its subscription; hiding a panel does not stop the app-scoped market-data runtime.
- No order creation or broker dealing action is exposed. `CAP_ALLOW_TRADING=false` remains unchanged.

## Cross-PR engineering review — verified 2026-11-18

### Repository governance
- Default branch `main` was observed at `4875fc30e68b3611c036f4e9b1c9bbe9f0fb59c6` during this review.
- GitHub repository rulesets endpoint returned no rulesets; `main` branch protection was not enabled at review time. Treat this as a governance gap: require PR review/status checks, block force-push and branch deletion, and define merge policy before production collaboration.
- Repository is public and no repository license was identified in the reviewed metadata. Public visibility does not itself grant reuse rights; owner should select an appropriate license before inviting external reuse.
- README contains stale PR status references (for example PR #10 still described as unmerged although it is merged). Reconcile project-facing documentation against actual merged history.

### Current PR state and exact-head CI evidence
- PRs #24–#43 in the current delivery chain remain OPEN / DRAFT / unmerged at review time.
- PR #24 HEAD `e34c7155c45e9108e5f95156fb8f2e1363d63e60`: Backend and Repository Hygiene passed; Apple Silicon passed; Intel job remains in progress. CodeQL workflow passed, but Intel job completion is still pending.
- PR #25 HEAD `3112637a014e1573078056dee5fefc61b495ff4f`: Backend and Repository Hygiene passed; Intel job remains in progress; Apple Silicon job in the inspected CI run was cancelled. Do not qualify until a complete current-head run passes both architectures.
- PR #26 HEAD `9f46a5ce9fc313e73dbff9e78680804c4dd1692f`: CI and Local Sync Safety passed. However its declared base SHA `bdcdab3592347473ff9ec0ca0a9d4f99d6eccc5b` does not equal PR #25 current HEAD `3112637a014e1573078056dee5fefc61b495ff4f`; reconcile/rebase the stack and re-run exact-head CI before ordered merge.
- PRs #33, #37, #38, #39, and #40: previously inspected current-head CI suites passed. They remain open/draft and must be merged only after their upstream base chain is reconciled.
- PR #41 HEAD `c9eb73d28c24398dfcb435525118f971aae221e8`: current-head CI now passed. Intel x86_64, Apple Silicon arm64, Backend, and Repository Hygiene all completed successfully; Mermaid architecture and Local Sync Safety also passed. Backend includes 49/49 PostgreSQL integration tests. This supersedes the earlier note that its new documentation HEAD had no CI.
- PR #42 HEAD `ff7af23585b8d7272d826fd29b03111ed57492bf`: current-head CI passed on Intel x86_64, Apple Silicon arm64, Backend, and Repository Hygiene; Mermaid and Local Sync Safety passed. Backend test suite reported 52/52.
- PR #43 current HEAD `25599a3c65ad21ee71871c64759118ad98a63619`: Backend and Repository Hygiene passed; Mermaid and Local Sync Safety passed; Intel and Apple Silicon jobs are queued. Do not mark macOS qualification complete until both jobs and their Debug/XCTest/Release steps pass.
- PR #43 documentation previously mentioned code head `42ee04d878f0554f17bef54a5abfd688ffe9a016`; that is superseded by current HEAD `25599a3c65ad21ee71871c64759118ad98a63619`. Reconcile the snapshot after the queued jobs complete.
- These CI statements are SHA-specific. Any subsequent documentation or code commit creates a new HEAD and requires fresh exact-head verification.

### Implementation maturity
- Merged baseline includes engineering governance, platform foundation, backend/macOS health, safe local sync, navigable workspace, shared visual foundation, and adaptive workspace layout (PRs #1, #2, #6–#11, #17, #18, #22).
- PRs #24–#26 establish the macOS Command Center/workspace and Capital.com DEMO REST/credential foundations, but they are not yet merged or owner-runtime qualified.
- PRs #33, #37–#39 establish Market Explorer, Capital.com DEMO streaming, native timestamped quote consumption, and historical candle/UTC normalization. They do not establish a completed chart engine, indicators, or drawing engine.
- PR #40 establishes canonical trading-domain contracts; it is not a complete RiskEngine or execution system.
- PR #41 establishes PostgreSQL migration/repository foundations and domain-record outbox persistence. It does not implement an outbox consumer, OMS worker, Execution Gateway dispatcher, or broker order dispatch.
- PR #42 establishes risk-gated OEL-12 order persistence and atomic lifecycle/audit/outbox records. It is OMS persistence foundation, not a complete lifecycle processor, fill processor, position projection, or broker reconciliation worker.
- PR #43 integrates a persisted local watchlist and app-scoped DEMO quote consumer into the Command Center. Its latest code includes stream lifecycle, unsubscribe, row actions, and quote freshness presentation; it remains unmerged and current-head macOS CI is pending.
- No PR in this chain establishes production readiness or LIVE execution. `CAP_ALLOW_TRADING=false` remains mandatory.

### Outstanding owner / operational qualification
- No owner-side Capital.com DEMO authentication/session validation or end-to-end live quote acceptance is established by hosted CI alone.
- Local PostgreSQL 18.7 has not been migrated or qualified. Do not run `npm run migrate` without an approved backup/restore and controlled migration qualification plan.
- Owner-side macOS visual, accessibility/VoiceOver, Keychain, multi-display, and runtime acceptance remain pending.
- No broker execution, production deployment, credential permission change, or LIVE trading action was performed.

### Next actions (ordered)
1. Complete PR #24 Intel job and PR #25 Intel/arm64 qualification.
2. Reconcile PR #26 base to the intended current PR #25 head; then re-run exact-head CI for #26 and descendants as needed.
3. Complete PR #43 Intel and arm64 jobs on exact HEAD `25599a3...`; update the implementation snapshot after qualification.
4. Reconcile stale README and engineering status snapshots; ensure all docs identify exact commit SHAs and distinguish current implementation from target architecture.
5. Establish main-branch protection/rulesets and an explicit repository license decision.
6. Merge the dependency chain only in verified order, rechecking each base/head and required checks after each merge.
7. Continue ATP-OMS-002 design only after authoritative OMS/Execution source reconciliation; keep domain-event outbox distinct from broker-command outbox. No broker dispatch in that batch.
