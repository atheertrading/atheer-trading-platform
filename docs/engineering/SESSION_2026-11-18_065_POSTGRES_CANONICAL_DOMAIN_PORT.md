# Engineering Session 065 — PostgreSQL Persistence Port on Canonical Domain

**Date:** 2026-11-18  
**Assignment:** ATP-TEAM-B-001  
**Batch:** ATP-2026-11-18-065  
**Repository:** `atheertrading/atheer-trading-platform`  
**Parent domain PR:** [#76](https://github.com/atheertrading/atheer-trading-platform/pull/76)  
**Persistence PR:** [#81](https://github.com/atheertrading/atheer-trading-platform/pull/81)  
**Branch:** `feat/postgres-persistence-on-canonical-domain`

## Objective

Advance the backend from provider-independent domain contracts to durable PostgreSQL-backed trading records while preserving the current canonical broker and market-data server boundary.

## Implementation

Ported the existing ATP-PERSISTENCE-001 implementation from legacy PR #41 without merging, rewriting or closing the legacy branch:

- Pinned PostgreSQL driver `pg@8.23.1` and reproducible lockfile.
- Versioned SQL migration and SHA-256 migration-ledger verification.
- Explicit `npm run migrate`; backend startup verifies applied migrations and does not execute DDL.
- Environment-scoped instrument/specification, broker-account and balance records.
- Durable order-intent and risk-assessment records.
- Reconciliation, append-only audit and transactional domain-event outbox.
- Transaction-scoped repository operations, idempotent replay and conflict detection.
- Least-privilege PostgreSQL integration fixtures, runbook and Mermaid architecture diagram 12.
- Separate persistence-readiness state injected into the existing health response.

## Integration defect and correction

The first port copied legacy `main.ts` and `server.ts` that depended on older streaming and historical-price modules absent from the current PR #76 parent. Exact-head CI caught the mismatch before merge.

Corrective integration:
- Retained the current canonical-parent broker runtime and market-data routes.
- Added only PostgreSQL pool initialization, migration verification, readiness injection and graceful pool shutdown.
- Removed the obsolete legacy feature-branch push trigger from the workflow.
- Preserved explicit migration execution and fail-closed schema verification.

## Verification evidence

**Initial corrected code head:** `9ac64f65eb628fc45df6517432c314fe0044655a`  
**GitHub Actions CI run:** `44373617588`  
**Backend Toolchain job:** `135046764282`

- Node.js: **24.22.2**
- PostgreSQL integration service: **17.12**
- TypeScript strict type-check: **passed**
- Complete API suite: **37 passed, 0 failed**
- PostgreSQL migration/durable-journal integration test: **passed**
- Repository Hygiene: **passed**
- Mermaid architecture rendering: **passed**
- Local Sync Safety: **passed**
- Intel x86_64 and Apple Silicon arm64 jobs: **queued at the time of this record**

The documentation-only continuity commits that follow this code head require a final-head CI rerun. The successful code-head result is not represented as proof for a later SHA.

## Boundaries and safety

- No PostgreSQL migration was executed against the owner's local database.
- No production database credentials or broker credentials were used.
- The outbox has no publisher/dispatcher in this package.
- No OMS order submission, Execution Gateway, broker dealing endpoint or LIVE capability was added.
- Persistence of an intent or authorized risk assessment is not execution permission.
- `CAP_ALLOW_TRADING=false` remains unchanged.
- Owner-local PostgreSQL 18.7, backup/restore and owner-Mac qualification remain pending.

## Next engineering action

1. Re-run and inspect exact-head CI after the documentation updates.
2. Complete Intel/Apple Silicon qualification and parent PR #76 integration gates.
3. Reconcile the OEL-12 lifecycle persistence implementation from legacy PR #42 against PR #81's canonical persistence branch, preserving its source-authority and no-dispatch boundary.
4. Only then proceed to the RiskEngine, OMS lifecycle application service and controlled DEMO execution integration.

PR #81 remains Draft and stacked on PR #76. No merge is claimed.
