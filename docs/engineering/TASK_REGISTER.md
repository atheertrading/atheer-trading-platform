# ATHEER Trading — Task Register

**Snapshot date:** 2026-11-16  
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
| M02-001 | P2 | Qualify macOS/Xcode/Swift compatibility and app structure | IN PROGRESS |
| M02-002 | P2 | Specify and implement IPDS primitives and semantic tokens | PENDING |
| M02-003 | P2 | Establish backend service foundation and API contracts | IN PROGRESS |
| M02-004 | P2 | Establish automated tests and local developer workflows | IN PROGRESS |
| M02-005 | P2 | Integrate backend health into the macOS workspace | IN PROGRESS — PR #10 exact head `06bd496d957b6cd2f999209cf5dc83cae54251cf` passed hosted CI #117; owner Mac XcodeGen/Debug/XCTest/launch are owner-confirmed; owner supplied /health/live 200 and /health/ready 503 expected payload. App-panel verification remains pending in PR #17. |
| M02-006 | P2 | Implement non-destructive local synchronization and workstation bootstrap | IN PROGRESS |
| M02-007 | P2 | Implement first native multi-screen navigation and API Connection screen | IN PROGRESS — PR #17 `feat/macos-workspace-api-connection`; hosted macOS CI and owner runtime QA pending |
| M02-008 | P2 | Establish native application-wide copy/paste foundation | IN PROGRESS — Issue #16 first increment in PR #17; full control audit and owner runtime QA pending |

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
