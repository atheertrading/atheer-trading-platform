# Engineering Session 031 — PostgreSQL qualification continuation and sequence privileges

**Date:** 2026-11-18  
**Repository:** `atheertrading/atheer-trading-platform`  
**PR:** [#41 — PostgreSQL trading persistence foundation](https://github.com/atheertrading/atheer-trading-platform/pull/41)  
**Branch:** `feat/postgres-persistence-foundation`  
**Starting code-bearing head:** `94cc13d13f56fd1f2efa450747e72dc841f65017`  
**First follow-up commit:** `78a774289de6ccea0fe49c89c7877f65c8246828`

## 1. Continuation rule

This is a continuation of ATP-PERSISTENCE-001. No re-bootstrap, schema redesign, or replacement of the existing PostgreSQL implementation is intended.

## 2. Current code and CI evidence inspected

- Actual migration runner uses transaction-local `SET LOCAL ROLE atheer_db_owner` after advisory lock acquisition.
- Migration ledger, migration DDL, and repository statements explicitly target schema `atheer`.
- Least-privilege integration tests provision `atheer_db_owner`, NOINHERIT `atheer_migrator`, and `atheer_app`; test migration execution through migrator and repository operations through app; verify migrated table ownership and direct table CREATE denial for migrator/app.
- Code-bearing head `94cc13d...`, run `44207522335`: Backend type-check and PostgreSQL 17.12 integration 49/49 passed; Repository Hygiene, Mermaid, and Local Sync Safety passed; Apple Silicon Debug/XCTest/Release passed; Intel Debug/XCTest passed with Release in progress and CodeQL pending.
- Separate workflow runs `44207530976` and `44207634600` were cancelled and are not passing evidence.

## 3. Sequence privilege regression test added

Commit `78a774289de6ccea0fe49c89c7877f65c8246828` updates `services/api/test/persistence.test.mjs` to:
- Create a sequence under `SET ROLE atheer_db_owner`.
- Verify `atheer_app` can call `nextval` using the owner-default sequence USAGE grant.
- Verify `atheer_app` cannot create a sequence.
- Verify `atheer_migrator` cannot create a sequence directly.
- Drop the probe sequence through the owner role.

This extends the prior table ownership/CREATE denial tests. The previous 49/49 result predates this test and must not be presented as its verification. Exact-head CI is required.

## 4. Documentation reconciliation

Updated:
- `docs/engineering/PROJECT_CONTINUITY.md`
- `docs/engineering/IMPLEMENTATION_STATUS.md`
- `docs/engineering/TASK_REGISTER.md`
- `docs/engineering/ENGINEERING_DECISION_LOG.md`
- `docs/architecture/ATP_PERSISTENCE_ARCHITECTURE.md`
- `docs/operations/POSTGRESQL.md`

The earlier Session 030 is retained as an immutable historical record of the original blocker discovery. Current state is superseded by this session and the current continuity/status/runbook entries.

## 5. Workstation and Mermaid references

- Repository `AGENTS.md` was reviewed. It identifies the historical owner workstation baseline as macOS 13.7.8, Xcode 14.3.1, Swift 5.8.1, Intel x86_64; those values require rechecking before local build qualification.
- The governing Library reference previously identified is **Professional Trading Screens, Workspace Architecture & User Experience.md**. The exact file was not present in the currently visible Library listing/search, so its full text was not independently re-read in this session. The remembered invariant is that workspace/panel visibility and customization must not mutate strategy runtime, risk controls, orders, or positions; treat that as a cross-domain constraint pending retrieval of the actual document.
- Current GitHub Mermaid diagram 12, `docs/architecture/diagrams/12-postgres-transactional-persistence.mmd`, was inspected. It depicts the persistence data flow and explicitly labels future OMS/Execution Gateway dispatch as not implemented. Its CI syntax validation passed on the code-bearing head `94cc13d...`.
- The historical 52-diagram Mermaid source export was not available as a directly inspected current repository source in this session. Do not claim reconciliation of all 52 historical diagrams.

## 6. Remaining work and safety gates

1. Complete exact-head CI after commit `78a7742...`, including Intel Release and CodeQL.
2. Re-inspect current PR head, workflow jobs, review threads, and Mermaid validation.
3. Retrieve/reconcile the full Workstation reference and applicable source diagrams when available; do not infer missing specification content.
4. Prepare a controlled local PostgreSQL 18.7 qualification plan. Do not run `npm run migrate` on the owner's database until final exact-head CI is green and the plan is reviewed.
5. Backup/restore, retention, PITR, production TLS, role provisioning, and restore drills remain open.
6. PR #41 remains Draft/Open and stacked on PR #40. No merge or approval is claimed.
7. Keep `CAP_ALLOW_TRADING=false`; no OMS worker, outbox publisher, Execution Gateway, or broker dealing capability is added.

No owner-local database migration, permission change, credential change, production deployment, or broker operation was performed.
