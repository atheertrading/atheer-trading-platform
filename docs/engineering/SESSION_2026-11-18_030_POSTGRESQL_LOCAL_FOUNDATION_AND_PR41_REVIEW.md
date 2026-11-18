# Engineering Session 030 — Owner-local PostgreSQL foundation and PR #41 review

**Date:** 2026-11-18  
**Repository:** `atheertrading/atheer-trading-platform`  
**PR:** [#41 — PostgreSQL trading persistence foundation](https://github.com/atheertrading/atheer-trading-platform/pull/41)  
**Branch:** `feat/postgres-persistence-foundation`  
**Reviewed source head:** `012ea149749312b5146ee1b8dce900e0d7bba848`  
**Status:** Documentation synchronized; local migration compatibility BLOCKED.

## 1. Objective

Record the owner's completed local PostgreSQL foundation, preserve the earlier PostgreSQL implementation decisions and verification history, and reconcile PR #41's actual migration behavior with the local least-privilege database roles and schema.

## 2. Owner-local PostgreSQL foundation — verified from owner terminal output

- macOS 13.7.8, Intel x86_64.
- Postgres.app; PostgreSQL 18.7.
- Loopback listener: `127.0.0.1:5432`; `listen_addresses=localhost`.
- Data directory: `~/Library/Application Support/Postgres/var-18`.
- Config: `~/Library/Application Support/Postgres/var-18/postgresql.conf`.
- Database: `atheer_trading`; canonical schema: `atheer`.
- Roles: `atheer_db_owner` NOLOGIN; `atheer_migrator` LOGIN/NOINHERIT with explicit SET ROLE membership; `atheer_app` LOGIN with no CREATE.
- PUBLIC CONNECT and schema CREATE revoked; explicit database CONNECT grants configured. App schema USAGE and owner-default DML/sequence grants configured.
- Passwords were set interactively; no credentials are recorded.
- SSL is off only on this loopback development instance.
- Verified: app can connect/use schema but cannot create; migrator can log in and explicitly SET ROLE; owner-created probe table had app DML privileges; probe transaction rolled back and probe objects are absent.
- Default sequence privileges have been configured but not yet independently tested.
- No trading migration or project table has been applied locally.

## 3. PR #41 implementation and prior decisions

PR #41 implements a bounded PostgreSQL persistence layer using `pg` 8.23.1, explicit SQL migrations, a migration ledger with advisory locking and SHA-256 checksum validation, repository contracts, environment-pinned persistence, idempotent intent/risk persistence, transactional audit/outbox records, and PostgreSQL integration tests.

Previously recorded architecture decisions remain:
- PostgreSQL is the approved transactional persistence direction.
- Domain contracts remain provider/database independent.
- Financial values remain canonical decimal strings; no binary floating-point coercion or implicit rounding.
- Intent, risk, audit, and domain-record outbox writes are transactional.
- Outbox events are limited to persisted domain records. No publisher, OMS worker, Execution Gateway dispatcher, or broker dealing call is included.
- An intent or stored AUTHORIZED risk assessment is not execution permission.
- API startup verifies migrations/checksums but does not auto-apply DDL.
- `CAP_ALLOW_TRADING=false` remains unchanged.

## 4. Exact-head GitHub qualification checkpoint

CI run `44203457118` on source head `012ea149749312b5146ee1b8dce900e0d7bba848`:
- Node.js 24.22.2 / npm 11.19.1.
- Ephemeral PostgreSQL 17.12.
- TypeScript typecheck and backend suite passed: 49 tests, 0 failures.
- Repository Hygiene, Mermaid architecture validation, and Local Sync Safety passed.
- Intel x86_64: project generation, Debug build, and XCTest passed; Release was in progress and CodeQL pending at inspection.
- Apple Silicon arm64: project generation, Debug, XCTest, and Release passed; CodeQL was skipped.
- PR #41 was OPEN / DRAFT and had no approval review at inspection.

This hosted result is specific to the recorded source head and ephemeral CI role setup. It does not establish compatibility with the owner's local PostgreSQL 18.7 instance or role model. Any later commit requires fresh exact-head qualification.

## 5. Blocking source finding — migration role and schema mismatch

Inspected:
- `services/api/src/persistence/migrate.ts`
- `services/api/src/persistence/postgres.ts`
- `services/api/migrations/001_trading_persistence.sql`
- `docs/operations/POSTGRESQL.md`

Findings:
1. The CLI connects with `DATABASE_URL` and invokes `runSqlMigrations(pool)`; it does not switch to `atheer_db_owner`.
2. The migration runner starts a transaction and acquires an advisory lock, but does not issue `SET LOCAL ROLE atheer_db_owner`.
3. The migration ledger `atheer_schema_migrations`, migration DDL objects, and repository SQL relations are unqualified. They do not explicitly target schema `atheer`.
4. The local `atheer_migrator` role is NOINHERIT and has no direct CREATE grant on schema `atheer`. The local grants are intentional and must not be weakened as a workaround.
5. Consequently, the current CLI is not compatible with the local role/schema contract and may fail or resolve objects outside the intended schema.

**Decision / gate:** Do not run `npm run migrate` on the owner's local database until the implementation is corrected and tested.

Required engineering correction:
- Keep schema `atheer` canonical.
- Assume `atheer_db_owner` transaction-locally for migration DDL and ledger writes.
- Schema-qualify migration ledger, DDL, and repository SQL (or prove a strictly controlled equivalent).
- Add least-privilege PostgreSQL tests for `atheer_migrator` and `atheer_app`; app CREATE must remain denied.
- Re-run exact-head CI before attempting a controlled local qualification.

## 6. Operational gaps

Backup/restore, PITR, retention, restore drills, production TLS, environment-specific credentials/database-role isolation, and production role provisioning remain unimplemented or unqualified. PostgreSQL 17 CI does not by itself certify PostgreSQL 18.7 local or production behavior.

## 7. Documentation updated

- `docs/engineering/PROJECT_CONTINUITY.md`
- `docs/engineering/IMPLEMENTATION_STATUS.md`
- `docs/engineering/TASK_REGISTER.md`
- `docs/engineering/CONVERSATION_INDEX.md`
- `docs/operations/POSTGRESQL.md`
- This session report.

## 8. Next actions

1. Fix migration role switching and schema qualification.
2. Add least-privilege integration tests and verify default sequence privileges.
3. Re-run exact-head CI and inspect all architecture jobs.
4. Only after those gates pass, prepare a controlled local migration test against the owner's database.
5. Keep PRs in dependency order and preserve `CAP_ALLOW_TRADING=false`.

No local project migration, production migration, broker dealing, permission change, credential change, or merge was performed in this session.
