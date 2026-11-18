# Engineering Session 029 — ATP-PERSISTENCE-001

**Date:** 2026-11-18  
**PR:** [#41 — PostgreSQL trading persistence foundation](https://github.com/atheertrading/atheer-trading-platform/pull/41)  
**Base:** PR #40 branch `feat/trading-domain-foundation`  
**Implementation checkpoint parent SHA:** `e8c9ff7908c167959ae48b6b3690883e6366d264`  
**Status:** Draft; exact-head CI qualification pending.

## 1. Objective

Implement the first durable PostgreSQL persistence boundary after the provider-independent domain contracts in PR #40. Keep SQL and PostgreSQL-specific concerns in the backend adapter; do not introduce broker dealing or execution dispatch.

## 2. Implemented

- Pinned `pg` 8.23.1 and committed the API npm lockfile.
- Added a PostgreSQL schema for canonical instruments and versioned broker specifications, broker accounts, account balance snapshots, order intents, risk assessments, reconciliation events, audit events, and a transactional domain outbox.
- Added migration ledger, transaction-scoped advisory lock, ordered/unique numeric migration versions, SHA-256 checksum validation, checksum-drift rejection, and an explicit `npm run migrate` command.
- API startup verifies that the expected migration ledger/checksums exist and performs a database connectivity check. It does not automatically apply DDL.
- Added `TradingPersistenceRepository` and `PostgresTradingRepository` with environment pinning, immutable identity/snapshot checks, canonical JSON hashing, exact idempotent replay, conflicting idempotency-key rejection, and transaction-scoped intent/risk/audit/outbox persistence.
- Preserved financial decimal values as canonical strings in JSONB; no monetary values are parsed or rounded through JavaScript `number`.
- Restricted outbox event types to persisted domain records. No publisher, lease worker, OMS transition processor, Execution Gateway, broker submit API, or execution-dispatch event exists in this package.
- Added a PostgreSQL 17 service to the backend CI job and an integration test covering concurrent migration startup, checksum drift, duplicate migration versions, FK rollback, immutable instrument/account snapshot behavior, decimal-string preservation, idempotent intent/risk replay, conflicting idempotency reuse, reconciliation/audit persistence, environment rejection, and no dispatch event.
- Added `ATP_PERSISTENCE_ARCHITECTURE.md`, `POSTGRESQL.md`, Mermaid diagram 12, EDL-012, and task/implementation/continuity records.

## 3. Safety and operational boundaries

- `CAP_ALLOW_TRADING=false` remains unchanged.
- No broker credentials, session tokens, signing keys, risk limits, or permissions were changed.
- No production database was provisioned or migrated.
- Production database roles/credentials per environment, TLS configuration, backups, restore drills, retention, and point-in-time recovery remain release blockers.
- Logical environment keys and repository pinning are implemented. Hard isolation through separate database instances/roles is still deployment configuration work.
- No local Mac access was available in this execution context. No local pull, Intel/Apple Silicon workstation build, visual QA, or broker DEMO execution test is claimed.

## 4. Qualification checkpoint

### Existing dependency chain

- PRs #24, #25, and #26: latest observed workflow runs completed successfully; all remain Draft/open.
- PR #33: CI completed successfully on Intel x86_64, Apple Silicon arm64, Backend Toolchain, and Repository Hygiene.
- PR #37: CI, Mermaid, and Local Sync Safety completed successfully.
- PR #38: Intel, Backend, Repository Hygiene, Mermaid, and Local Sync Safety passed; Apple Silicon arm64 was re-queued and was still running at the last poll.
- PR #39: CI, Mermaid, and Local Sync Safety completed successfully. The owner-provided local Intel report remains limited to its documented tested source state; it does not qualify the latest PR head or Apple Silicon.
- PR #40: Backend Toolchain and Repository Hygiene passed; Intel build/tests passed and CodeQL was still running; Apple Silicon had a cancelled job with no steps and required a retry after the run completed.

### PR #41

- Initial Mermaid run failed because diagram 12 used invalid Mermaid cylinder delimiters. The diagram was corrected.
- On the corrected predecessor head `631c1e2e3bd69db076af301c521515c1686910cd`, Mermaid and Local Sync Safety passed; the CI run was cancelled during a workflow refresh.
- Source and integration-test refinements continued after that checkpoint. The current branch must be re-opened/re-qualified on the exact final head before any CI result is claimed.
- No PostgreSQL integration test, TypeScript build, Intel/Apple Silicon build, or exact-head CI success is claimed yet for the current PR #41 head.

## 5. Merge and local synchronization decision

No PRs were merged in this session. The dependency chain remains `#24 → #25 → #26 → #33 → #37 → #38 → #39 → #40 → #41`. The PRs remain Draft and there are no approval reviews on the chain (PRs #39 and #40 have comment-only reviews). A green subset of jobs is not sufficient to merge a Draft PR with outstanding exact-head CI and local qualification. Do not merge out of order or bypass required reviews/protection.

The local Mac path `~/Developer/AtheerTradingPlatform` was not accessible from this environment. The repository's Local Sync Safety workflow passed for PR #41, but that does not execute a pull on the owner's Mac.

## 6. Next actions

1. Trigger and inspect exact-head CI for PR #41 after the final code/test changes; fix all TypeScript, PostgreSQL, Mermaid, and hygiene findings.
2. Verify the integration test logs report Node.js 24 and the exact PostgreSQL server version.
3. Allow PR #38 Apple Silicon and PR #40 Intel jobs to finish; retry only cancelled jobs that contain no source execution steps.
4. Re-run PR #40 Apple Silicon after its workflow run completes.
5. Complete independent review and owner-Mac qualification before converting Draft PRs to ready and merging the dependency chain in order.
6. After approved merges, use the repository's non-destructive local sync workflow on the owner's Mac; preserve uncommitted work and verify the resulting local SHA.
7. Continue with OMS lifecycle transitions, durable outbox consumption, reconciliation, and a RiskEngine-gated Execution Gateway as a separate batch. No broker dealing path is included in ATP-PERSISTENCE-001.

