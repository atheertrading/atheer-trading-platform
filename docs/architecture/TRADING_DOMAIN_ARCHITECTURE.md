# Trading Domain Architecture

**Status:** Implemented foundation with explicit incomplete boundaries. This document describes the current code, not a deployed trading system.

## Dependency direction

```text
HTTP / IPC / SwiftUI / Strategy / AI adapters (not implemented)
                         |
                  Application layer
                         |
        +----------------+----------------+
        |                |                |
     OMS intake       RiskEngine      Portfolio projection
        |                |                |
        +----------------+----------------+
                         |
               Domain model and events
                         |
     Repository / outbox / broker ports (contracts only)
                         |
       PostgreSQL / Execution Gateway / broker adapters
                    (not implemented)
```

The current domain package is under `services/api/src/domain/`. It imports no HTTP server, persistence framework, Capital.com package, or UI code. The API server remains a loopback-only health service and does not expose trading routes.

## Module responsibilities

| Module | Responsibility |
|---|---|
| `shared.ts` | Exact decimal, currency-safe money, UTC timestamps, domain errors |
| `models.ts` | Instrument, quote, account, balance, session, intent, order, execution, position, portfolio, trade, reconciliation |
| `risk.ts` | Risk context, policy contracts, fail-closed engine, configured volume/exposure policies |
| `order-management.ts` | Unified intent registration, idempotency boundary, risk authorization and repository/outbox contracts |
| `events.ts` | Versioned event envelope and controlled event construction |
| `index.ts` | Public domain exports |

## Architectural invariants

- Domain values are strongly typed and immutable at their public boundaries.
- Financial values use `Decimal`/`Money`, not JavaScript `number`.
- Instrument precision and tick/step constraints are validated against versioned specification metadata.
- All source-originated data carries provenance and timestamps.
- All timestamps are UTC instants.
- Broker-specific instrument references are opaque mappings keyed by generic broker identity.
- Manual, strategy, algorithm, AI-agent, position-management and risk-control sources converge on `OrderManagementService`.
- `OrderManagementService` has no broker client or submission method.
- Only an eventual Execution Gateway adapter may communicate with broker dealing APIs; it is not present here.
- A persistence adapter must atomically register intent/idempotency/outbox and atomically persist risk decision/order transition/outbox. The interface contract documents this; no adapter exists yet.
- Event delivery is at-least-once compatible; consumers must be idempotent. No delivery guarantee is claimed by the current in-memory tests.

## Precision and valuation boundaries

`Decimal` stores a base-10 integer coefficient and scale using `bigint`. Division requires an explicit target scale and rounding mode. Currency arithmetic rejects mismatched currencies. `InstrumentSpecification` defines price precision, quantity precision, tick, step, min/max quantity, contract multiplier, valuation model and provenance.

Only the explicitly selected `LINEAR` valuation model supports the current notional and P&L helpers. `BROKER_REPORTED` or unknown non-linear models fail closed in exposure policies. No automatic FX conversion is performed. Cross-currency portfolio exposure is grouped by quote currency; account-level exposure rejects missing FX conversion or incomplete exposure snapshots.

## Trading safety

- `LIVE` is unconditionally rejected by the current RiskEngine.
- The platform account model cannot enable LIVE dealing.
- No real broker credentials, broker account permissions, or execution adapters are present.
- Emergency halt rejects exposure-increasing intents. Risk-reducing `REDUCE`/`CLOSE` intents remain within the same authorization path; this is not an execution exception.
- Unknown broker submission outcomes require reconciliation and cannot be converted into blind resubmission.

## Current sequencing constraint

ATP-DOMAIN-001A is a stacked branch on PR #10's current head because PR #10 is still open and the prescribed local Mac qualification is incomplete. This is parallel implementation preparation only. Do not retarget or merge the domain branch into `main` before PR #10 integration and local engineering qualification.
