# ATP-DOMAIN-001 — Trading Domain Foundation

**Status:** IN PROGRESS — first implementation package committed on a stacked feature branch; integration is blocked on PR #10 and subsequent qualification.  
**Implementation package:** ATP-DOMAIN-001A — broker-independent domain core.  
**Owner:** Engineering.  
**Runtime target:** Existing Node.js 24 / TypeScript 5.8 API package.  
**Scope:** Domain types, value objects, state transitions, risk contracts, OMS intake contract, reconciliation primitives, deterministic tests.

## 1. Objective

Establish a broker-independent, deterministic, testable trading domain that can be used by later application, persistence, risk, execution, market-data, backtesting, and broker-adapter work. The domain package must not depend on HTTP handlers, Node HTTP transport, PostgreSQL, SwiftUI, Capital.com SDKs, or broker-specific request/response models.

## 2. Authority and source constraints

- Owner execution directive ATP-DOMAIN-001, dated 2026-11-17.
- Repository `AGENTS.md`, current source and tests.
- EDL-004 modular monorepo decision.
- Library `TRADING_LIFECYCLE.md`, `MARKET_DATA_AND_INSTRUMENTS.md`, `API_AND_EVENT_CONTRACTS.md`, and the recovered execution/risk Q&A archive.
- The Master Document Registry lists ATP-ARCH-002, ATP-ARCH-002-OMS, ATP-ARCH-002-PM, ATP-ARCH-005, ATP-ARCH-016 and ATP-ARCH-019, but their full original specification texts were not retrievable from the connected Library index in this execution. Original ADR-0004, ADR-0005 and ADR-0006 text was also unavailable for direct inspection. No content or approval status is inferred or silently replaced.
- Detailed risk formulas, broker-specific contract semantics, order-type behavior, financing/fee treatment, netting, FX conversion, persistence schema, and event transport remain unspecified until their source specifications are reconciled.

## 3. Implemented in ATP-DOMAIN-001A

- Exact base-10 `Decimal` backed by `bigint`; explicit quantization and rounding mode; no binary floating-point financial arithmetic.
- Currency-checked `Money`, validated ISO-style three-letter currency codes, UTC-only timestamp value object, domain errors, and branded identifiers.
- `TradingInstrument`, `InstrumentSpecification`, generic broker instrument references, `MarketQuote`, `TradingAccount`, `TradingBalance`, and `TradingSession`.
- `OrderIntent` with origin, operation, environment, idempotency key, correlation/causation, order type, precision-sensitive quantity/price parameters, and optional stop references.
- `TradingOrder` state machine with risk authorization/rejection, submission, broker acceptance, partial/full fills, cancellation, unknown submission outcome, and reconciliation-required state.
- `OrderExecution` validation, duplicate execution suppression, overfill rejection, and weighted average fill price.
- `TradingPosition` long/short, weighted average entry, partial close, linear calculated realized/unrealized P&L, gross exposure, and stop references.
- `Portfolio`, `Trade`, broker order/position snapshots, and reconciliation comparisons that retain broker snapshots as authoritative.
- `RiskEngine` contract and fail-closed baseline checks; configurable maximum order quantity, instrument exposure, and account exposure policies.
- `OrderManagementService` as one manual/strategy/algorithm/AI intent intake, with an atomic idempotency/persistence adapter contract and transactional-outbox obligations.
- Versioned domain-event envelope and event names required by the phase.

## 4. Safety invariants

1. `LIVE` intent is rejected unconditionally in this implementation baseline.
2. An account cannot be platform-enabled for LIVE dealing.
3. No broker transport or dealing method exists in the domain package.
4. Every order intent reaches the same OMS intake and risk assessment contract.
5. No configured risk policies means rejection.
6. Stale quotes, inactive instruments/accounts, halted exposure-increasing intents, mismatched context, missing exposure snapshots, and unsupported valuation/FX inputs fail closed.
7. Emergency halt blocks new exposure; the risk policy baseline permits explicitly identified `REDUCE`/`CLOSE` intents to continue through the same risk assessment, without providing an execution bypass.
8. Broker acknowledgement is not a fill. Fills require execution reports.
9. Unknown submission outcome is distinct from rejection and requires reconciliation; no blind resubmission transition exists.
10. Broker-reported account, order, execution, position, balance, and P&L snapshots remain authoritative for broker activity.
11. Calculated position P&L is explicitly labelled calculated and limited to the declared linear valuation model.
12. No credentials, broker permissions, approved risk limits, production state, or LIVE gate were changed.

## 5. Deliberate non-goals for 001A

- PostgreSQL schema, migrations, transaction implementation, outbox dispatcher, inbox/deduplication store, or production repository adapter.
- Execution Gateway, Capital.com authentication, broker order submission/cancellation, or broker WebSocket/API transport.
- Production API endpoints, IPC, WebSocket, or UI wiring.
- Broker catalogue ingestion, real market-data feed, FX conversion, margin calculation, fees, financing, dividends, options/inverse/quanto valuation, netting/hedging semantics, or tax accounting.
- Final account/instrument/daily-loss/drawdown policy limits; these require approved values and formulas.
- Production trading readiness or any claim of DEMO/LIVE execution.

## 6. Acceptance status

| Criterion | Status | Evidence |
|---|---|---|
| Domain code is independent of HTTP/DB/broker frameworks | IMPLEMENTED | `services/api/src/domain/` imports only domain modules |
| Exact decimal and currency-safe arithmetic | IMPLEMENTED / TESTED | `shared.ts`; unit tests |
| Instrument/quote/account/session validation | IMPLEMENTED / TESTED | `models.ts`; unit tests |
| Order lifecycle, partial fills, duplicate fills | IMPLEMENTED / TESTED | `TradingOrder`; unit tests |
| Unknown outcome and reconciliation state | IMPLEMENTED / TESTED | order state machine; unit tests |
| Position long/short/partial close and linear P&L | IMPLEMENTED / TESTED | `TradingPosition`; unit tests |
| Broker snapshot reconciliation | IMPLEMENTED / TESTED | `reconcileOrder`, `reconcilePosition`; unit tests |
| Fail-closed risk contracts | IMPLEMENTED / TESTED | `risk.ts`; unit tests |
| OMS idempotency contract | IMPLEMENTED / TESTED with in-memory test adapter | `order-management.ts`; unit tests |
| Durable idempotency and transactional outbox | CONTRACT ONLY | production persistence adapter not implemented |
| Node 24 CI verification | PENDING | PR checks required |
| Local Mac/Node qualification | PENDING | owner workstation not accessed |
| PR #10 integration | BLOCKED | PR #10 open and unmerged |

## 7. Next packages

- ATP-DOMAIN-001B: durable repository adapter, transactional outbox/inbox, concurrency and recovery semantics, and order history persistence.
- ATP-DOMAIN-001C: complete position/account reconciliation projections and broker-authoritative balance/position snapshot contracts.
- ATP-DOMAIN-001D: expanded risk policy framework after formal risk formula/limit reconciliation.
- ATP-DOMAIN-001E: versioned application/API/event DTO mapping and integration tests, still without broker execution until separately authorized and qualified.

## 8. Integration gate and phase sequencing

PR #10 was freshly revalidated at head `06bd496d957b6cd2f999209cf5dc83cae54251cf`: CI #117, CodeQL #117 and Local Sync Safety #48 passed. PR #10 remains open and unmerged. Physical Mac qualification remains outstanding, and branch-protection policy could not be read by the connected integration. The current domain branch is therefore stacked on the PR #10 branch, not based on `main`; this permits bounded parallel engineering without representing the work as integrated.

The Master Project Construction directive places local engineering qualification after PR #10 integration and before the Trading Domain phase. The owner has now directed ATP-DOMAIN-001 execution. This package is prepared in parallel, but its pull request must not be merged into `main` until PR #10 is integrated and the required local engineering qualification and repository approvals are satisfied.
