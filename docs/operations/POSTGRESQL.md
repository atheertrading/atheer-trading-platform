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

