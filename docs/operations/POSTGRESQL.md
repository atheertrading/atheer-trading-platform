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

The command requires `DATABASE_URL` to authenticate as `atheer_migrator` (or an equivalently constrained migration principal that is a member of `atheer_db_owner`). It obtains a PostgreSQL advisory lock, executes `SET LOCAL ROLE atheer_db_owner` inside the migration transaction, applies ordered SQL migrations, and records checksums in the explicitly qualified `atheer.atheer_schema_migrations` ledger. The canonical schema `atheer` must already exist and be owned by `atheer_db_owner`; migrations and repository statements explicitly qualify every project relation with `atheer.`. The runtime `atheer_app` role needs schema USAGE and table DML/default sequence privileges only; it must not have CREATE. The command does not print the connection string. Production migrations must be reviewed and executed through a separately approved operational change; do not run the migration command against production as an incidental application startup action.

## Verification

```bash
npm run typecheck
npm test
```

When `DATABASE_URL` is set, `test/persistence.test.mjs` runs against the configured PostgreSQL instance. The integration test provisions an owner role, a NOINHERIT migrator with explicit owner membership, an app role without CREATE, the canonical `atheer` schema, and owner default table/sequence grants; it applies migrations as migrator and exercises repository reads/writes as app. CI provisions an ephemeral PostgreSQL 17 service and injects a test-only connection string. The test suite applies migrations, verifies concurrent startup and checksum drift handling, exercises intent/risk idempotency and transaction rollback, and confirms the outbox contains no execution-dispatch event.

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

## Local migration compatibility gate — role/schema fix implemented; final qualification pending

The former role/schema incompatibility has been corrected in PR #41 code-bearing head `94cc13d13f56fd1f2efa450747e72dc841f65017`:

- `runSqlMigrations` starts a transaction, obtains its advisory lock, then executes `SET LOCAL ROLE atheer_db_owner` before creating or recording schema objects.
- The migration ledger, migration DDL, and repository SQL explicitly target the canonical `atheer` schema.
- PostgreSQL integration tests provision a NOINHERIT `atheer_migrator` with explicit owner membership and an `atheer_app` role with schema USAGE and owner-default table DML/sequence privileges only.
- The tests assert migrated table ownership and direct table CREATE denial for migrator and app.
- A further regression test for sequence grants has been added after the 49/49 run; it still requires exact-head CI.

**Do not run `npm run migrate` against the owner's local database yet.** The code fix and PostgreSQL 17 hosted role tests are positive evidence, but the final head (including the sequence regression) must first pass CI, and a controlled PostgreSQL 18.7 local qualification plan must be recorded. This is a qualification gate, not a request to change local grants.

Required local configuration remains:
1. `atheer` exists and is owned by `atheer_db_owner`.
2. `atheer_migrator` is NOINHERIT and a member allowed to SET ROLE to `atheer_db_owner`.
3. `atheer_app` has schema USAGE and owner-default DML/sequence grants, without CREATE.
4. Passwords remain external to source control and logs; SSL-off is acceptable only for the current loopback-only development listener.
5. Verify the target database identity and backup/rollback plan before any schema-changing action.

## Hosted PR #41 verification checkpoint — code-bearing head

On `94cc13d13f56fd1f2efa450747e72dc841f65017`, run `44207522335`:
- Backend type-check and PostgreSQL 17.12 integration suite: 49/49 passed, zero failures/skips.
- Repository Hygiene, Mermaid architecture diagrams, and Local Sync Safety: passed.
- Apple Silicon arm64: project generation, Debug, XCTest, Release passed; CodeQL skipped by workflow configuration.
- Intel x86_64: project generation, Debug and XCTest passed; Release in progress and CodeQL pending at last inspection.
- Later runs `44207530976` and `44207634600` were cancelled; do not treat them as successful qualification.
- Sequence privilege regression test was added in commit `78a774289de6ccea0fe49c89c7877f65c8246828`; the above results predate that test and must not be carried forward to the new head.

Hosted PostgreSQL 17 tests do not certify the owner's PostgreSQL 18.7 operational environment. Backup/restore, PITR, retention, restore drills, production TLS, and production role provisioning remain unqualified.

### Follow-up batch snapshot — branch HEAD `434ae1191c6a66cafe30e98f21c5ee03a8a4faf8`

- Sequence privilege regression test and documentation reconciliation are committed; this branch HEAD is newer than the previously reported code-bearing head `94cc13d...`.
- Current exact-head workflows: Mermaid run `44209957024` in progress; Local Sync Safety run `44209957152` passed; CI run `44209957185` has Backend queued and Intel/Apple Silicon/Repository Hygiene in progress at inspection.
- The 49/49 Backend result applies to `94cc13d...` only and does not include the new sequence regression test. Do not carry it forward to `434ae119...`.

### Verified GitHub snapshot — 2026-11-18 (current PR #41 HEAD)

- PR #41 is OPEN / DRAFT; current HEAD `dba73544a768006bb8535f72c0a615fda42c88dd`, base is PR #40 HEAD `8d4afc4e59b2787a9252269cbcf11fa379bc65b6`.
- Backend toolchain run `44210034147`: completed successfully. The exact-head backend report is 49/49 PostgreSQL 17.12 integration tests, including the sequence privilege regression; TypeScript type-check passed.
- Repository Hygiene (`44210034147`): passed.
- Mermaid render (`44210034098`): passed.
- Local Sync Safety (`44210034195`): passed.
- Apple Silicon arm64 job `134485862385`: XcodeGen and project generation passed; Debug build is currently in progress; XCTest and Release are pending. CodeQL init is skipped by workflow configuration and is not a pass/fail result.
- Intel x86_64 job `134485862456`: XcodeGen installation is in progress; project generation, Debug, XCTest, Release, and CodeQL are pending.
- These platform results are still incomplete; do not mark PR #41 fully qualified until both architecture jobs finish and the final HEAD is rechecked.
- The 49/49 result is specific to this exact HEAD; do not transfer it to a later commit without rerunning CI.
- Local PostgreSQL 18.7 remains untouched; do not run `npm run migrate` until hosted exact-head qualification is complete and a controlled local qualification plan is approved.
- `CAP_ALLOW_TRADING=false` remains unchanged. No OMS worker, durable outbox consumer, Execution Gateway dispatcher, or broker order dispatch is implemented by this persistence PR.

### Architecture and next-batch notes

- Treat Mermaid diagram 05's Outbox → Execution Gateway path as target architecture, not implemented behavior. PR #41 currently persists domain outbox records only.
- Concrete OMS Order/Position state sets and transition semantics remain blocked on reconciliation with the authoritative formal ADR/specification sources; do not invent states.
- Preserve the invariant that workspace/panel visibility and trading runtime state are independent: hiding/closing a panel must not stop strategies, cancel orders, or close positions.
- The full Workstation reference `Professional Trading Screens, Workspace Architecture & User Experience.md` and the historical 52-block Mermaid export were not available in the current Library retrieval. Their complete reconciliation remains pending; do not claim otherwise.
- Next batch: complete Intel/arm64 qualification, recheck the exact PR head, then reconcile authoritative OMS/Execution specifications before designing ATP-OMS-001. No broker dispatch in that batch without separately approved controls.
