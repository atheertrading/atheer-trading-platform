# ATP-OMS-001 — Authorized Order Persistence and Lifecycle Foundation

**Status:** Implemented on a stacked review branch; hosted qualification pending  
**Branch:** `feat/oms-authorized-order-persistence`  
**Parent:** PR #41 — PostgreSQL Persistence Foundation  
**Scope:** Persist an OMS order only after the exact intent and an `AUTHORIZED` RiskEngine assessment are already durable. No broker dispatch is included.

## 1. Authority and source reconciliation

This increment applies the delegated internal decision authority recorded in the Library document **Atheer Q&A Repository / Owner and Developer Approval / Owner and Developer Approval.md**. Routine product, architecture, engineering, and professional-trading decisions are delegated; protected financial actions remain separately gated.

The order lifecycle is derived from the Library Q&A archive:

- **PART VI / Section 18 / Q1 — What are the stages that a trading order goes through?** defines the 12-stage Order Execution Lifecycle (OEL-12), its canonical state vocabulary, broker-authoritative fills, and the distinction between broker acknowledgement and execution.
- **Q11 — How is idempotency managed?** requires persistent, account-scoped, atomic idempotency and reconciliation before uncertain resubmission.
- **Q12 — How is the order sent to the broker?** requires one centralized Execution Gateway; frontend, strategies, agents, and charting do not call broker dealing endpoints.
- **Q16 — How is a timeout handled?** distinguishes read-only retries from unsafe submission/cancel/modify/close retries.
- **Q17 — How should an unknown execution result be handled?** keeps uncertain outcomes unresolved until broker evidence is obtained.
- **Q18 — How can the submission of a duplicate order be prevented?** requires atomic registration, transactional outbox, leases/fencing, broker-event deduplication, and position-version controls.
- **Q20 — What happens when the Execution Gateway fails?** requires safety lockdown, preservation of exposure, reconciliation, and progressive restoration.

The source archive labels several individual Q&A recommendations as recommendations for approval. The delegated Owner and Developer Approval record grants authority to make these internal design decisions under delegated authority. This document records the selected engineering baseline; it does not grant permission to execute financial transactions or enable LIVE trading.

## 2. OEL-12 canonical lifecycle states

| State | Meaning | Authority |
|---|---|---|
| `CREATED` | Intent generated | Intent intake |
| `VALIDATING` | Structural and market validation | Order Execution Engine |
| `RISK_CHECKING` | Risk evaluation in progress | RiskEngine boundary |
| `AUTHORIZED` | Required risk/policy authorization passed for this intent | RiskEngine |
| `PERSISTED` | Authorized order committed to the OMS journal | OMS |
| `SUBMITTED` | Execution Gateway initiated broker transmission | Execution Gateway |
| `PENDING` | Broker processing/response pending | Broker observation |
| `ACCEPTED` | Broker accepted the order | Broker observation |
| `WORKING` | Broker reports active working order | Broker observation |
| `PARTIALLY_FILLED` | One or more confirmed partial fills | Broker execution evidence |
| `FILLED` | Requested quantity fully executed | Broker execution evidence |
| `CANCEL_PENDING` | Cancellation command is pending confirmation | OMS / Execution Gateway |
| `CANCELLED` | Broker confirms cancellation | Broker observation |
| `REJECTED` | Rejected by validation, policy, risk, or broker; reason is retained | Owning authority |
| `EXPIRED` | Broker confirms expiry | Broker observation |
| `UNKNOWN` | Outcome cannot yet be established | Execution safety control |
| `RECONCILIATION_REQUIRED` | Internal and broker state requires investigation | Reconciliation |

`UNKNOWN` and `RECONCILIATION_REQUIRED` are exception states, not successful completion states. A timeout is not proof of failure. An acknowledgement is not proof of a fill. A partially filled order that is later cancelled retains both its executed quantity and cancelled remainder.

## 3. Transition authority

The domain module `services/api/src/domain/order-lifecycle.ts` defines source-specific transition policies:

- **OMS:** validation/risk workflow and `AUTHORIZED → PERSISTED`; cancellation requests may enter `CANCEL_PENDING`.
- **Execution Gateway:** `PERSISTED → SUBMITTED` only. The gateway implementation is not part of this increment.
- **Broker:** broker-observed processing, acknowledgement, working, fill, cancel, rejection, expiry, and uncertain states.
- **Reconciliation:** resolves `UNKNOWN` or `RECONCILIATION_REQUIRED` only using broker-confirmed evidence.

The policy rejects invalid transitions, source-authority violations, and normal-state regression from terminal states. Broker corrections that conflict with a terminal record must first enter reconciliation.

## 4. Implemented in this increment

1. Typed OEL-12 state vocabulary and source-scoped transition policy.
2. Immutable order-lifecycle event validation.
3. `createOmsOrder` requires:
   - a valid immutable intent envelope;
   - the exact matching RiskAssessment;
   - outcome `AUTHORIZED`;
   - matching trading environment;
   - an explicit positive quantity.
4. PostgreSQL migration `002_oms_lifecycle.sql` adds:
   - environment-scoped `atheer.orders`;
   - one order per intent and one order per risk assessment;
   - composite foreign keys binding order, intent, risk assessment, account, and environment;
   - exact PostgreSQL `numeric` quantity columns and a requested = filled + remaining invariant;
   - append-only `atheer.order_lifecycle_events` with unique order-version sequence;
   - domain outbox event types for OMS persistence/lifecycle notifications only.
5. `PostgresTradingRepository.persistAuthorizedOrder` locks and verifies the exact persisted intent and exact persisted `AUTHORIZED` assessment before creating the order, lifecycle event, audit record, and `oms.order.persisted` outbox record in one transaction.
6. Replays of the same intent/order are idempotent. Conflicting order identities/payloads are rejected.
7. The application role receives SELECT/INSERT on OMS orders and lifecycle events; UPDATE and DELETE are revoked on both tables. Orders remain immutable until a later qualified transition command can atomically update the projection and append its event.

## 5. Deliberately not implemented

- No outbox lease/claim worker or publisher.
- No execution-dispatch event.
- No Execution Gateway or broker dealing API.
- No Capital.com order submission, modification, cancellation, or close operation.
- No broker status ingestion, fill processing, position updates, or reconciliation worker.
- No LIVE or DEMO financial transaction.

The outbox records produced here are internal domain notifications. They are not executable broker commands. The next bounded increment must add durable outbox ownership/fencing and an internal consumer boundary before any broker adapter is connected.

## 6. Transaction and safety invariants

- An order cannot be persisted without a matching, durable `AUTHORIZED` risk assessment for the exact intent and environment.
- Intent, assessment, order, first lifecycle event, audit record, and outbox notification commit atomically.
- An idempotency replay cannot create a second OMS order.
- Broker acknowledgements and fills remain separate states.
- No uncertain submission is blindly retried.
- Broker state remains authoritative for accepted orders, fills, cancellations, and positions.
- DEMO, SIMULATION, BACKTEST, and LIVE remain environment-scoped.
- `CAP_ALLOW_TRADING=false` remains unchanged.

## 7. Verification plan

- Domain tests: risk authorization binding, environment isolation, quantity validation, valid/invalid transitions, source authority, uncertain-state reconciliation.
- PostgreSQL 17 CI integration: migration, role grants, exact persisted intent/risk binding, atomic OMS persistence, idempotent replay, conflicting identity rejection, exact quantity preservation, append-only lifecycle journal, and absence of dispatch events.
- macOS Intel x86_64 and Apple Silicon arm64 CI: build/test/release qualification for the current PR head.
- Owner-local PostgreSQL 18.7 migration and Mac runtime remain separate qualification steps; no local migration is performed by this PR.
