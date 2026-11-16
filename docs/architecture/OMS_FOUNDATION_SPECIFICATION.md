# OMS Foundation Specification

**Status:** Domain intake and lifecycle implemented; durable storage and broker dispatch are not implemented.

## Responsibilities

The OMS is the single logical owner of order-intent registration, order aggregate lifecycle, idempotency identity, order history contracts, execution association and reconciliation state. It accepts intents from manual, strategy, algorithmic, AI-agent, position-management and risk-control origins through one path.

## Current lifecycle states

`INTENT_RECEIVED` → `RISK_AUTHORIZED` or `RISK_REJECTED` → `SUBMISSION_PENDING` → `BROKER_ACCEPTED` → `PARTIALLY_FILLED` → `FILLED`.

Alternative outcomes include `REJECTED`, `CANCEL_PENDING`, `CANCELLED`, `SUBMISSION_UNKNOWN` and `RECONCILIATION_REQUIRED`.

Transitions require the designated actor (`RISK_ENGINE`, `EXECUTION_GATEWAY`, `BROKER_REPORT`, `OMS`, `BROKER_RECONCILIATION`). Terminal states cannot be reopened by ordinary transitions. A broker acknowledgement is not a fill.

## Idempotency and persistence boundary

`OrderIntentRegistry.register` must atomically persist the intent, initial order and `OrderIntentCreated` outbox event while enforcing a unique idempotency key. Reuse of the same key with a different payload fingerprint is a conflict. A duplicate with the same fingerprint returns the existing aggregate and does not re-run risk assessment. A duplicate observed while the original is still in `INTENT_RECEIVED` returns a pending result rather than creating another order. A durable recovery worker must resume pending assessments after process failure; that worker is not implemented in 001A.

`recordRiskDecisionAndEvents` must atomically persist the risk decision, updated order and `OrderValidated`/`OrderRejected` outbox event(s). The current package defines these interfaces but does not provide PostgreSQL or another durable implementation.

## Execution and reconciliation

- Fills are accepted only against the matching order ID and valid order state.
- Duplicate execution ID or broker execution reference is ignored idempotently.
- Cumulative fill quantity cannot exceed order quantity.
- Average fill price is quantity-weighted using exact decimal arithmetic.
- A submission timeout/ambiguous result is `SUBMISSION_UNKNOWN`, not `REJECTED`.
- `RECONCILIATION_REQUIRED` is explicit; blind resubmission is not a permitted transition.
- Broker order snapshots are authoritative inputs to reconciliation.

## Not implemented

PostgreSQL schema/transactions, outbox dispatcher, inbox deduplication, durable idempotency registry, broker adapter, Execution Gateway, order submission/cancellation, broker event transport, and production order history API remain future work. The in-memory test registry is test-only and is not a production persistence adapter.

## Recovery note

A duplicate request that finds an `INTENT_RECEIVED` aggregate returns `pending` and does not repeat risk assessment. A durable adapter must expose pending-intent recovery/claim semantics so a worker can safely resume after a process crash. The recovery worker, lease/claim semantics and multi-process race tests are not implemented in 001A.
