# ATP-PERSISTENCE-001 — PostgreSQL Persistence Architecture

**Status:** Implemented as a bounded backend persistence slice; exact-head CI and database integration qualification pending.
**Runtime:** Node.js 24, TypeScript, PostgreSQL 17 CI service, `pg` 8.23.1.

## 1. Responsibilities and boundaries

The persistence adapter stores provider-independent domain records. Domain contracts remain independent of PostgreSQL, HTTP, SwiftUI, and Capital.com SDKs. PostgreSQL is the durable system of record for the records covered by this package; broker-confirmed facts remain authoritative for broker-managed state.

Implemented repositories persist instrument identities/specifications, broker account identities and balance snapshots, immutable order-intent envelopes, risk assessments, reconciliation events, audit events, and domain outbox events.

Persistence is not an execution authorization boundary. A stored intent or an `AUTHORIZED` risk assessment does not itself authorize a broker command. This package creates no execution-dispatch outbox event, dispatcher, order-submission route, or broker dealing call. The outbox allow-list is limited to durable domain-record events.

## 2. Relational model

- `instruments` and `instrument_specifications`: environment-scoped canonical instrument identity and versioned broker specification, retaining provenance and the complete normalized source payload.
- `broker_accounts` and `account_balance_snapshots`: broker-scoped account identity and immutable, timestamped snapshots. Balance and margin amounts remain decimal strings inside JSONB; no JavaScript `number` or implicit SQL numeric coercion is introduced.
- `order_intents`: immutable envelope, account/instrument/specification references, command/correlation/idempotency identities, schema version, payload hash, and full payload.
- `risk_assessments`: immutable assessment bound by foreign key to its intent, with policy version, outcome, timestamp, hash, and full payload.
- `reconciliation_events` and `audit_events`: append-only, environment-scoped records with provenance or actor/action context and payload hashes.
- `domain_outbox`: transactional domain-event records with environment, aggregate, correlation, idempotency, payload, creation time, publication marker, and attempt count.
- `atheer_schema_migrations`: applied migration version, SHA-256 checksum, and timestamp.

All business tables carry an explicit `DEMO`, `SIMULATION`, `BACKTEST`, or `LIVE` environment key. Repository instances are pinned to one environment and reject records from another. This is logical environment partitioning within a database; separate credentials/database instances and database-role isolation remain deployment configuration work and are not claimed by this package.

## 3. Migration execution

SQL migrations are ordered by numeric filename prefix. The runner obtains a PostgreSQL transaction-scoped advisory lock, creates the migration ledger, compares stored SHA-256 checksums, applies unapplied migrations, and records each migration in the same transaction. A changed checksum for an already-applied version fails closed. Concurrent startup is serialized by the advisory lock.

Migrations are forward-only. Do not edit an applied migration; add a new versioned migration for later schema changes. No production database has been migrated by this work.

## 4. Transaction and idempotency semantics

`persistIntentAndRiskAssessment` validates both domain records, checks their identity/environment binding, then performs the following in one database transaction:

1. Insert the intent using `(environment, account_id, idempotency_key)` uniqueness.
2. On duplicate, compare the persisted intent ID and canonical SHA-256 payload hash; return an idempotent replay only for the exact same intent. Reuse with different content is a conflict.
3. Insert the risk assessment and compare its hash on duplicate identity.
4. Insert the intent and risk-assessment domain outbox events.
5. Insert the audit record.
6. Commit all records together; any database or validation failure rolls the entire unit of work back.

Financial values remain canonical base-10 strings. The adapter canonicalizes JSON keys for deterministic hashing but does not parse, round, or convert financial values to binary floating point.

## 5. Outbox boundary

The outbox is durable and transactional, but no publisher/lease worker is implemented in this batch. The schema accepts only `order.intent.persisted`, `risk.assessment.persisted`, `reconciliation.event.persisted`, and `audit.event.persisted`. It explicitly excludes broker-submit and execution-dispatch events. A later OMS/Execution Gateway batch must introduce a separate authorization-gated dispatch command, prove that its risk decision is current and bound to the intent, and preserve the same transaction/idempotency invariants.

## 6. Security and operations

- `DATABASE_URL` is consumed only by the backend runtime; connection strings are never logged.
- CI uses an ephemeral PostgreSQL 17 service and a test-only credential.
- Do not put broker credentials, session tokens, or signing material in these tables.
- Production TLS, database roles, backup/restore, retention, and environment-specific secret provisioning require deployment-specific configuration and qualification.
- `CAP_ALLOW_TRADING=false` remains unchanged. No order dispatch or LIVE operation is enabled.

## 7. Verification

The PostgreSQL integration suite is enabled by `DATABASE_URL` and covers repeated/concurrent migration startup, checksum drift rejection, foreign-key rollback, exact idempotent replay, conflicting idempotency reuse, risk-decision journaling, audit/reconciliation persistence, environment rejection, and the absence of execution-dispatch events. Hosted results must be attached to the exact PR head before qualification is claimed.


## 8. Startup and migration safety

The API does not mutate the database schema during startup. When `DATABASE_URL` is present, it verifies the migration ledger/checksums and performs a connectivity check; missing or mismatched schema prevents startup readiness. Schema changes are applied only through the explicit `npm run migrate` command. Production migration execution requires a separately reviewed operational change. See `docs/operations/POSTGRESQL.md`.

## 8. Least-privilege migration and schema contract — implemented on PR #41

The canonical project schema is `atheer`. Migration execution acquires a transaction-scoped advisory lock and then executes `SET LOCAL ROLE atheer_db_owner` inside the same transaction before creating the migration ledger or applying DDL. This preserves the NOINHERIT property of `atheer_migrator`: the migrator can assume owner authority only for the bounded migration transaction and cannot create schema objects directly outside it.

All migration ledger, DDL, foreign-key/index targets, and repository relations are explicitly schema-qualified with `atheer.`; the persistence adapter does not rely on ambient `search_path` for project tables.

The application role `atheer_app` receives schema USAGE and owner-default table DML and sequence USAGE/SELECT privileges, but no schema CREATE. Integration tests verify owner table ownership, direct table CREATE denial for migrator/app, and repository operations under the app role. A dedicated sequence privilege regression test is added after the initial 49/49 hosted run and awaits exact-head CI.

This is a bounded hosted integration qualification. It does not prove the owner's local PostgreSQL 18.7 migration has been run or operationally qualified. Do not execute local migrations until the final exact-head CI and controlled local qualification plan are complete.
