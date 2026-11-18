# Repository and System Architecture
**Status:** Foundation baseline; bounded-context contracts remain under specification.

## Architectural style
Use a modular, domain-oriented architecture with explicit contracts and dependency inversion. Begin as a modular monolith; extract deployable services only when operational, scaling, security, or team boundaries justify the cost.

## Intended bounded contexts
1. Platform Foundation — configuration, lifecycle, identity abstractions, eventing, observability.
2. Market Data — provider adapters, instrument metadata, historical and streaming data, normalization, freshness, recovery.
3. Trading Domain — order intents, orders, fills, positions, account and portfolio projections.
4. Strategy OS — strategy definitions, signals, eligibility, evaluation, scheduling.
5. Risk and Authorization — deterministic limits, pre-trade checks, authorization policies, kill switches.
6. OMS — durable order state, idempotency, outbox, broker command orchestration, reconciliation.
7. Execution Gateway — only controlled boundary for broker dealing APIs.
8. Broker Connectivity — provider-neutral contracts and Capital.com adapter.
9. AI and Agent Platform — Model Gateway, model registry, agent runtime, tool contracts, knowledge retrieval, evaluation.
10. Research and Simulation — historical datasets, backtesting, simulation, experiment tracking.
11. Portfolio and Analytics — account views, exposure, P&L projections, analytics.
12. Workstation and IPDS — SwiftUI application, design tokens, charting and workspace experience.

These are target ownership areas, not claims that modules already exist.

## Dependency rules
- Domain logic must not depend on SwiftUI, HTTP frameworks, database vendors, or provider SDKs.
- Adapters implement domain-owned ports; dependency direction points inward.
- UI submits application commands and renders projections; it does not own financial policy.
- Strategies and AI agents produce typed intents; neither calls broker dealing endpoints.
- Risk authorization is deterministic, independently testable, and mandatory for risk-affecting operations.
- OMS owns durable order lifecycle; Execution Gateway owns broker command transmission and reconciliation interfaces.
- Broker-confirmed facts remain authoritative for external order/fill/account state.
- Model/provider SDKs and credentials stay behind backend-managed adapters and the Model Gateway.
- DEMO, SIMULATION, BACKTEST, and LIVE use explicit isolated configuration and data provenance.

## Cross-cutting contracts
Every external or asynchronous boundary defines identity/correlation, timestamp semantics, validation, timeout, retry policy, idempotency, error taxonomy, observability, and versioning. Financial state transitions are auditable and deterministic where required.


## Implemented domain foundation slice — ATP-DOMAIN-001

The first provider-independent TypeScript domain contract slice is implemented under `services/api/src/domain/` (shared value objects/provenance, instruments, accounts, trading intents, risk assessments, lifecycle-policy validation, broker observations, fills, execution events, reconciliation, and audit). It is a bounded foundation, not a claim that all bounded contexts or production state machines are complete.

The domain package has no dependency on HTTP, SwiftUI, database vendors, broker SDKs, or provider-specific execution clients. Detailed OMS/position state lists, order-type semantics, rounding policies, and identifier generation remain subject to formal ADR/specification reconciliation. PostgreSQL persistence is the next separate package after this domain slice is qualified.


## PostgreSQL persistence adapter — ATP-PERSISTENCE-001

The backend persistence adapter implements versioned PostgreSQL migrations, environment-scoped instrument/account records, immutable account snapshots, order-intent and risk-assessment journals, reconciliation/audit records, and a transactional domain-event outbox. Application/domain services depend on repository contracts rather than SQL. Intent, risk, audit, and outbox writes share transaction boundaries; broker dealing remains outside this package. See `ATP_PERSISTENCE_ARCHITECTURE.md` and Mermaid diagram 12. The outbox currently accepts domain-record events only and has no dispatcher.
