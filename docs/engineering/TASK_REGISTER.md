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
| M02-003 | P2 | Establish backend service foundation and API contracts | PENDING |
| M02-004 | P2 | Establish automated tests and local developer workflows | PENDING |

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

- M00-018 — Normalize legacy Markdown formatting across the historical engineering registry and knowledge-source documents, then re-enable the temporarily disabled markdownlint spacing/link rules. The initial CI lint run found 82 formatting-only findings across 22 files; the current config keeps other default rules active while this baseline cleanup remains pending.

## Mermaid documentation and architecture source recovery — 2026-11-16

| ID | Priority | Task | Status | Acceptance evidence / dependency |
|---|---|---|---|---|
| M00-019 | P0 | Correct continuity records for PR #2 merge and active repository identity | IN PROGRESS | Session 008 addendum; update stale implementation and decision snapshots |
| M00-020 | P0 | Recover and migrate all original Mermaid blocks from the Library archive | IN PROGRESS | 31 source Markdown documents / 52 blocks; extractor committed; generated files, provenance manifest, rendering and review still pending |
| M01-007 | P1 | Establish canonical architecture diagram sources and Mermaid CI rendering | IN PROGRESS | Eight canonical `.mmd` files, diagram README and workflow on `docs/architecture-diagram-baseline`; PR/checks pending |
| M00-021 | P1 | Reconcile the 47 formal documents, 517 Q&A sources and approval metadata | IN PROGRESS | Existing source inventory; document-level authority/revision/approval traceability pending |

The historical Mermaid count is 31 source documents containing 52 Mermaid blocks, not 31 individual diagrams. Do not mark M00-020 or M01-007 DONE until generated legacy sources are committed, all Mermaid files render in CI, and provenance is verified.

## Documentation readiness and scaling follow-up — 2026-11-16

- Added `docs/engineering/REPOSITORY_DOCUMENTATION_READINESS.md`: identifies present bootstrap documentation, historical references absent from the current tree, and future production/scaling documentation.
- Added `docs/architecture/PLATFORM_SCALING_AND_DEPLOYMENT_STRATEGY.md`: proposed modular-monolith-first scaling strategy; no cloud provider, capacity target, SLO, RPO or RTO is invented.
- Added `docs/engineering/REQUIREMENTS_TRACEABILITY_MATRIX.md`: initial traceability structure; formal requirement mapping and verification links remain pending.
- M00-009 (Requirements Traceability Matrix) is IN PROGRESS, not DONE; a template exists, but formal requirement mapping and verification links remain outstanding.
- PR #6 is open; do not mark Mermaid baseline or repository documentation changes DONE until the full latest CI run is green and the PR is merged.

## Phase 1 qualification — 2026-11-16

- PR #7 records repository identity, CI, branch and source-control findings.
- Phase 1 remains IN PROGRESS: active main ruleset, local Git author/authentication, and repository-level Actions/security settings remain unresolved or unverified.
- The owner has explicitly authorized Phase 2 to proceed as a sequencing exception. This does not close or waive Phase 1 findings.

## Phase 2 Xcode configuration — 2026-11-16

- M02-001 is IN PROGRESS.
- Branch `build/phase-2-xcode-configuration` introduces explicit Debug/Release build settings, targeted Swift concurrency diagnostics, generated scheme inspection, and a hosted Release build.
- Developer setup documentation records the configuration policy and known signing/sandbox/architecture limitations.
- Verification, PR review, local Mac build/test/launch, and arm64 qualification remain pending. Do not mark M02-001 DONE until those acceptance criteria are evidenced.
