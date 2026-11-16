# ATHEER Trading — Task Register

**Snapshot date:** 2026-11-16  
**Active milestone:** M00 — Knowledge, governance, and source reconciliation

Statuses: `DONE` = verified complete; `IN PROGRESS` = active work; `PENDING` = not started; `BLOCKED` = dependency prevents progress; `OWNER DECISION` = requires explicit owner direction.

## M00 — Knowledge, governance, and source reconciliation

| ID | Priority | Task | Status | Acceptance evidence / dependency |
|---|---|---|---|---|
| M00-001 | P0 | Inspect new repository identity, visibility, default branch, and initial commit | DONE | GitHub metadata and commit inspected |
| M00-002 | P0 | Establish root engineering instructions and security baseline | IN PROGRESS | Bootstrap branch and PR; review/merge outstanding |
| M00-003 | P0 | Establish project continuity, conversation index, decision log, and task register | IN PROGRESS | Bootstrap branch and PR; review/merge outstanding |
| M00-004 | P0 | Reconcile Library Engineering Operating Standards and governance references | IN PROGRESS | Full document/source review and conflict register |
| M00-005 | P0 | Inventory Library archives, source documents, and historical specifications | IN PROGRESS | Inventory with source IDs, versions, and provenance |
| M00-006 | P0 | Inspect surviving repositories and local source-code history | IN PROGRESS | Repository/source inventory; inaccessible sources marked |
| M00-007 | P0 | Create Master Document Registry and Source Provenance Register | IN PROGRESS | Initial 47-document registry created; approval/provenance reconciliation remains pending |
| M00-008 | P0 | Create Specification Conflict Register | IN PROGRESS | Conflicts, source authority, resolution, and owner questions |
| M00-009 | P1 | Create Requirements Traceability Matrix | PENDING | Requirement → source → architecture → implementation → test |
| M00-010 | P1 | Establish architecture baseline and bounded-context map | PENDING | Reviewed architecture document and diagrams |
| M00-011 | P1 | Reconcile historical ADRs and OOP standard | IN PROGRESS | ADR inventory; no identifier collisions |
| M00-012 | P1 | Define IPDS v1.0 specification and token governance | IN PROGRESS | Primitive, semantic, component, theme, accessibility contracts |
| M00-013 | P1 | Establish documentation validation and CI baseline | PENDING | Reproducible workflow and passing checks |
| M00-014 | P1 | Configure repository security automation and branch rules | PENDING | Rulesets endpoint returned an empty list; branch-protection read returned 403 to the integration; owner-side verification and configuration evidence required |
| M00-015 | P2 | Plan source migration and historical Git preservation | PENDING | Owner-reviewed migration and provenance plan |

| M00-016 | P0 | Reconcile four-repository architecture with current repository strategy | IN PROGRESS | ATP-ARCH-042 and owner-endorsed current repository model |
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
| M02-001 | P2 | Qualify macOS/Xcode/Swift compatibility and app structure | PENDING |
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

The initial governance baseline is available for owner review in [PR #1](https://github.com/atheertrading/atheer-trading-platform/pull/1). Tasks M00-002 and M00-003 remain IN PROGRESS until the pull request is reviewed and merged. File retrieval verification is complete; merge and default-branch verification remain outstanding.


## Source-reconciliation progress update — 2026-11-16

Structural inspection of the two Library ZIP archives is complete. Tasks M00-004, M00-005, M00-006, M00-008, M00-011, and M00-012 are now IN PROGRESS. The 47 formal documents and 517 Q&A documents have not yet been reconciled individually. The four-repository versus monorepo conflict is recorded as M00-016 and remains unresolved.
