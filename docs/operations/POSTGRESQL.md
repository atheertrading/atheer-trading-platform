# PostgreSQL Operations — ATHEER API

## Scope

This runbook applies to the backend persistence foundation introduced by ATP-PERSISTENCE-001. PostgreSQL 17 is the CI integration-test service version; it is not yet an approved production deployment baseline.

## Configuration

- Provide `DATABASE_URL` through the local secret manager or deployment secret injection. Never commit it to `.env`, shell history, CI output, source control, or diagnostic reports.
- Configure TLS and certificate verification in the connection string/provider environment according to the target database service. Do not disable certificate validation to work around connectivity errors.
- Use separate database credentials/instances and least-privilege roles for DEMO, SIMULATION, BACKTEST, and LIVE. The current schema also keys records by environment and repository instances reject cross-environment records, but database-role isolation is still an operational prerequisite.
- Do not store broker API keys, session tokens, passwords, or signing material in trading-domain tables.

## Explicit schema migration

API startup never applies migrations. If `DATABASE_URL` is configured, startup verifies that the migration ledger exists, every bundled migration is applied with the expected SHA-256 checksum, and no unknown newer migration is present. A mismatch prevents the API from becoming ready.

To apply pending migrations in a non-production development/test database, run from `services/api`:

```bash
npm ci
npm run migrate
```

The command requires `DATABASE_URL`, obtains a PostgreSQL advisory lock, applies ordered SQL migrations transactionally, and records checksums. It does not print the connection string. Production migrations must be reviewed and executed through a separately approved operational change; do not run the migration command against production as an incidental application startup action.

## Verification

```bash
npm run typecheck
npm test
```

When `DATABASE_URL` is set, `test/persistence.test.mjs` runs against the configured PostgreSQL instance. CI provisions an ephemeral PostgreSQL 17 service and injects a test-only connection string. The test suite applies migrations, verifies concurrent startup and checksum drift handling, exercises intent/risk idempotency and transaction rollback, and confirms the outbox contains no execution-dispatch event.

## Backup, restore, retention, and recovery

Backup scheduling, encryption/key custody, off-site retention, point-in-time recovery, restore drills, data-retention policy, and production role provisioning are not implemented or qualified by ATP-PERSISTENCE-001. They are release blockers for any production database. Do not treat a successful migration or database connection as operational readiness.

## Trading safety

Persistence records are not broker confirmations. An intent or risk assessment is not an order submission. The outbox currently stores domain-record events only and has no publisher or broker dispatcher. `CAP_ALLOW_TRADING=false` remains mandatory; no LIVE dealing is enabled.
## Owner-local development database — verified baseline (2026-11-18)

The owner has provisioned a local Postgres.app PostgreSQL 18.7 instance on macOS 13.7.8 / Intel x86_64. It listens only on `127.0.0.1:5432`; its data directory is `~/Library/Application Support/Postgres/var-18`. The local database is `atheer_trading` and the canonical project schema is `atheer`.

The local role model is deliberately least-privilege:

- `atheer_db_owner`: NOLOGIN object owner.
- `atheer_migrator`: LOGIN, NOINHERIT, with explicit permission to SET ROLE to `atheer_db_owner`.
- `atheer_app`: LOGIN, schema USAGE and default DML/sequence privileges on owner-created objects; no CREATE privilege.
- PUBLIC database CONNECT and schema CREATE are revoked; explicit database CONNECT is granted to the project roles.
- Passwords are configured interactively and are not recorded here. Never put them in shell commands, source control, logs, or this document.
- SSL is disabled only for this loopback-only development instance. Do not expose the service beyond localhost without TLS and a separate security review.

The owner verified app connectivity and CREATE denial, migrator authentication and explicit role switching, owner ownership of a temporary probe table, app DML permissions, and rollback/removal of probe objects. Default sequence privileges are configured but still need an explicit test. No project trading migration has been applied locally.

## Local migration compatibility gate — BLOCKED

**Do not run `npm run migrate` against this local database with the current PR #41 implementation.**

The current migration CLI connects as `atheer_migrator`, but the migration runner does not execute `SET ROLE atheer_db_owner`. Because the role is NOINHERIT, owner privileges are not inherited automatically. In addition, the migration ledger, migration DDL, and repository statements use unqualified relation names; they do not explicitly target the owner's canonical `atheer` schema. The runbook's generic `DATABASE_URL` instruction is therefore insufficient for this role/schema configuration.

Required correction before local migration:

1. Keep `atheer` as the canonical schema; do not weaken the local grants.
2. Have the migration transaction explicitly assume `atheer_db_owner` (for example, transaction-local role switching) before creating or recording schema objects.
3. Schema-qualify the migration ledger, every migration object, and repository SQL, or prove an equally strict and consistently applied schema configuration.
4. Add PostgreSQL integration tests using least-privilege `atheer_migrator` and `atheer_app` roles. Verify app DML on owner-created tables and continued CREATE denial.
5. Re-run CI on the corrected exact PR head, then prepare a separate controlled local migration qualification.

The existing PostgreSQL 17 CI integration pass does not prove this owner's PostgreSQL 18.7 role/schema configuration. Do not create production tables, alter role grants as a workaround, or infer local compatibility from CI.

## Hosted PR #41 verification checkpoint — 2026-11-18

On source head `012ea149749312b5146ee1b8dce900e0d7bba848`, CI run `44203457118` reported Node 24.22.2 / npm 11.19.1, PostgreSQL 17.12, and 49/49 backend tests passing. Repository Hygiene, Mermaid validation, and Local Sync Safety passed. Intel Debug/XCTest passed with Release and CodeQL still pending; Apple Silicon Debug/XCTest/Release passed, with CodeQL skipped. PR #41 remained OPEN / DRAFT with no approval review at inspection. Refresh all results after subsequent commits.
