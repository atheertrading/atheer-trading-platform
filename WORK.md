# ATHEER Trading — Sequential Work Queue

**Document ID:** ATP-WORK-001  
**Version:** 1.0  
**Status:** Active operational queue  
**Authority:** Owner-approved execution workflow; governed by root `AGENTS.md`, the Continuous Engineering Operating Directive (CEOD), accepted decisions, and approved Library specifications.  
**Last reconciled:** 2026-11-17

## 1. Purpose and operating contract

This file defines the ordered engineering work to be executed next in ATHEER Trading. It is the active execution queue, not a general backlog, specification repository, or substitute for the task and continuity records.

The queue is sequential by default:

1. Execute the first eligible item that is not `DONE`, `DEFERRED`, or `SUPERSEDED`.
2. Do not start a dependent item until its prerequisite is verified complete.
3. Independent work may proceed only when it does not invalidate the sequence or create conflicting changes.
4. If blocked, record the exact blocker and unblock condition, then continue only with explicitly independent work.
5. At session start, recover repository state and verify this queue against current GitHub branches, PRs, issues, source, and CI. This file is not proof that a listed state remains current.
6. At each material checkpoint, update this queue and the relevant task, decision, implementation, conversation, and continuity records.
7. Never repeat completed work unless new evidence, a changed commit/environment, regression, or an explicit owner request requires it.

A task is `DONE` only when its acceptance criteria are supported by recorded evidence. A commit or open PR alone is not completion.

## 2. Status vocabulary

Use the CEOD status vocabulary:

- `PENDING` — not started.
- `IN PROGRESS` — active execution.
- `BLOCKED` — a named dependency prevents progress.
- `OWNER DECISION` — explicit owner direction is required.
- `VERIFICATION REQUIRED` — implementation exists but acceptance evidence is incomplete.
- `DONE` — all acceptance criteria are evidenced.
- `DEFERRED` — intentionally postponed with rationale.
- `SUPERSEDED` — replaced by a referenced task or decision.

Every active work item must identify its objective, priority, dependencies, acceptance criteria, current evidence, and next action.

## 3. Active sequential queue

### WORK-001 — Qualify and close the engineering governance documentation change

- **Priority:** P0
- **Status:** IN PROGRESS
- **Dependencies:** Existing UI/UX directive branch and CEOD branch history.
- **Scope:** Review the complete current diff for PR #19 and its dependency chain; verify links, consistency, Markdown/documentation checks, and exact-head CI. Confirm the intended base/head relationship and ensure no unrelated files or claims are included.
- **Acceptance criteria:**
  - Current PR #19 metadata, base, head SHA, changed files, and dependency are inspected directly.
  - Complete diff is reviewed against `AGENTS.md`, CEOD, and approved governance.
  - Applicable documentation checks and exact-head CI are verified; unavailable checks are explicitly recorded.
  - Required corrections are committed to the existing review branch without rewriting history.
  - PR review/merge readiness is recorded accurately; merge only when policy, dependencies, checks, and acceptance criteria permit.
- **Next action:** Re-fetch PR #19 and its latest head, inspect the complete diff and check runs, then resolve any findings.

### WORK-002 — Revalidate the macOS workspace PR chain and owner-confirmed two-screen test

- **Priority:** P0
- **Status:** PENDING
- **Dependencies:** WORK-001 governance review may proceed independently; preserve the existing stacked PR chain.
- **Scope:** Revalidate the current state of PRs #10, #17, and #18, their branch ancestry, exact heads, CI, and the owner-reported macOS runtime smoke test that included use with two screens.
- **Acceptance criteria:**
  - Current PR/branch/base/head relationships and exact-head checks are inspected.
  - The two-screen runtime test remains explicitly classified as owner-confirmed, not independently reproduced; no unverified build SHA is assigned.
  - The recorded test evidence is linked to its existing GitHub record and is not conflated with other tests or issues.
  - Remaining visual, accessibility, functional, and local-runtime acceptance gaps are stated precisely.
  - No PR is merged, retargeted, or reordered unless its dependency and merge gates are satisfied.
- **Next action:** Inspect current PR and CI state, then prepare a dependency-aware verification/merge sequence.

### WORK-003 — Complete governing-source and requirements reconciliation

- **Priority:** P0
- **Status:** PENDING
- **Dependencies:** Preserve the existing source-reconciliation registers and approved Library authority model.
- **Scope:** Continue the formal-document, Q&A, approval-metadata, architecture-decision, and requirement traceability work already recorded in the source and conflict registers.
- **Acceptance criteria:**
  - Source identity, revision, approval state, authority, and provenance are recorded for reviewed sources.
  - Conflicts are resolved only by the authority entitled to resolve them; unresolved items remain explicit.
  - Requirements are traceable to authoritative sources, architecture decisions, implementation modules, and verification evidence.
  - No architecture or design contract is declared final while material source conflicts remain unresolved.
- **Next action:** Resume from the existing reconciliation registers and their first incomplete source group; do not rebuild the inventory.

### WORK-004 — Establish the verified platform architecture and domain contracts

- **Priority:** P1
- **Status:** PENDING
- **Dependencies:** WORK-003 for material requirements and source conflicts; current source inspection.
- **Scope:** Define bounded contexts, dependency direction, canonical trading-domain contracts, market-data semantics, centralized risk authorization, OMS/Execution Gateway boundaries, and AI-agent permissions.
- **Acceptance criteria:**
  - Each contract has authoritative requirement links, ownership, inputs/outputs, lifecycle, failure behavior, and test strategy.
  - Manual, strategy, and AI-originated intents converge on one governed execution path.
  - Broker-confirmed data remains authoritative; DEMO, SIMULATION, BACKTEST, and LIVE are isolated.
  - AI agents cannot bypass authorization, RiskEngine, OMS, or Execution Gateway.
  - Architecture decisions and diagrams agree with the reconciled sources and actual repository structure.
- **Next action:** Start with the bounded-context and dependency map after WORK-003 provides sufficient authority.

### WORK-005 — Qualify the product design system and macOS workspace experience

- **Priority:** P1
- **Status:** PENDING
- **Dependencies:** WORK-003 source reconciliation; WORK-004 architecture boundaries; current PR #17/#18 review findings.
- **Scope:** Operationalize the approved UI/UX directive and IPDS sources into native macOS navigation, semantic tokens, shared components, workspace behavior, responsive multi-display behavior, accessibility, and visual QA.
- **Acceptance criteria:**
  - Design choices trace to approved product/design sources, not invented placeholder layouts.
  - Shared SwiftUI contracts define ownership, state, interaction, lifecycle, and accessibility.
  - Window lifecycle, panel visibility, panel sizing, and service/trading controls remain distinct.
  - Multi-display behavior is tested on the actual supported Mac environment and recorded with precise evidence.
  - Empty, loading, error, unavailable, and connected states are truthful; no fabricated broker or account data is displayed.
- **Next action:** Reconcile formal design sources and IPDS tokens before expanding UI implementation.

### WORK-006 — Advance the backend and broker foundation under trading safety gates

- **Priority:** P1
- **Status:** PENDING
- **Dependencies:** WORK-003 and WORK-004; current backend health PR/issue state.
- **Scope:** Qualify the existing health/readiness foundation, then define service/API, persistence, market-data, broker adapter, and reconciliation contracts before implementation.
- **Acceptance criteria:**
  - Liveness and readiness semantics are correct and fail closed for unconfigured dependencies.
  - Backend checks run on the exact reviewed head and supported Node.js version.
  - No fabricated broker state or credentials are introduced.
  - Broker integration remains DEMO-only until its contracts, security, reconciliation, and risk gates are verified.
  - No dealing endpoint, LIVE activation, or production deployment is introduced without its separate explicit approval.
- **Next action:** Revalidate the current backend PR/issue and exact-head checks after the higher-priority queue items.

## 4. Task completion record

For each completed item, append a concise record containing:

- Completion date and task ID.
- Repository branch and exact commit SHA.
- PR/issue references where applicable.
- Changed paths.
- Acceptance criteria and evidence.
- Checks executed, exact target SHA, environment, and result.
- Owner-reported evidence separately from independently verified evidence.
- Follow-up tasks or residual risks.

Do not delete historical completion records. If scope changes, supersede the item with a reference and rationale.

## 5. Governance and safety gates

This queue operates under `AGENTS.md` and `docs/engineering/ATHEER_CONTINUOUS_ENGINEERING_OPERATING_DIRECTIVE.md`.

Routine engineering and reversible repository work are delegated within those boundaries. Stop for task-specific owner approval before LIVE trading, broker-account permission or credential changes, risk-policy/limit changes, production deployment/release, destructive or irreversible repository operations, Apple private signing/security-sensitive actions, or legal/regulatory/privacy commitments.

No queue item authorizes bypassing these gates. A later task cannot silently waive an earlier dependency or a higher-authority requirement.

## 6. Relationship to other project records

| Record | Responsibility |
|---|---|
| `AGENTS.md` | Permanent repository engineering and safety instructions |
| `docs/engineering/ATHEER_CONTINUOUS_ENGINEERING_OPERATING_DIRECTIVE.md` | How work is recovered, decided, executed, verified, and handed over |
| `WORK.md` | Ordered active execution queue: what to do next |
| `docs/engineering/TASK_REGISTER.md` | Project-wide task inventory, milestone tracking, and dependencies |
| `docs/engineering/PROJECT_CONTINUITY.md` | Latest verified project checkpoint and next resumption point |
| `docs/engineering/ENGINEERING_DECISION_LOG.md` | Material engineering decisions and rationale |
| `docs/engineering/IMPLEMENTATION_STATUS.md` | Evidence-backed implementation state |

These records must link to one another where useful, but must not duplicate or contradict their authoritative facts.
