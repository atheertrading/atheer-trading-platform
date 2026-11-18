# Engineering Session 067 — Persisted Pre-Trade Authorization Coordinator

**Date:** 2026-11-18  
**Assignment:** ATP-TEAM-B-001 — Backend Engineering  
**Batch:** ATP-2026-11-18-067  
**Repository:** `atheertrading/atheer-trading-platform`  
**Branch:** `feat/pretrade-authorization-coordinator`  
**Parent:** PR #82 — `feat/oms-lifecycle-on-canonical-persistence`  
**Parent head at branch creation:** `b8a465f7a80dd1ca96f9f213977f2caa97b4fdf8`

## Objective

Add a backend application boundary that coordinates typed order-intent validation, centralized RiskEngine evaluation, and durable recording of the exact decision. All order-intent origins must use the same authority path. A completed decision must not be returned before its intent and risk assessment are persisted.

## Implemented

- Added `PreTradeAuthorizationService` in `services/api/src/trading/pre-trade-authorization.ts`.
- Introduced dependency-inversion ports for risk evaluation and durable pre-trade journaling. The service owns orchestration, not risk policy, market valuation, broker connectivity, or SQL.
- Validates and deep-freezes the incoming `OrderIntentEnvelope` before evaluation.
- Validates the RiskAssessment through the canonical domain boundary and rejects an assessment whose intent identity or environment differs from the submitted intent.
- Persists `AUTHORIZED`, `REJECTED`, and `HELD` decisions through the same journal port. The persistence adapter remains responsible for the atomic intent/assessment/audit/outbox transaction and idempotency constraints.
- Returns a completed pre-trade result only after the journal call succeeds. Evaluator and persistence exceptions propagate; neither is converted into authorization.
- Added deterministic tests for authorized/rejected/held outcomes, common HUMAN/STRATEGY/AI_AGENT entry, intent and environment mismatches, malformed input, risk-evaluator failure, persistence failure, and immutable intent handling.
- Added the canonical sequence diagram `14-pretrade-authorization-coordinator.mmd`.

## Deliberately outside this batch

- No HTTP route or external command endpoint was added.
- No credentials, broker sessions, account state, dealing API, order submission, cancellation, or fill processing were accessed.
- The coordinator does not create an OMS order. It durably records the pre-trade decision only; authorized-order persistence remains a separate command boundary requiring the exact stored assessment and an idempotent order identity.
- No outbox publisher, lease/fencing worker, Execution Gateway, broker dispatcher, or reconciliation worker was added.
- No composition-root wiring is claimed. Concrete RiskEngine and PostgreSQL adapters must be injected after their dependency PRs are integrated and qualified.
- `CAP_ALLOW_TRADING=false` remains unchanged. No LIVE permission or trading capability is introduced.

## Verification status

- Source, tests, and Mermaid source are committed on the branch.
- Exact-head hosted CI has not yet been observed for this new head; no test pass is claimed in this session record.
- No owner-Mac build, local PostgreSQL migration, authenticated DEMO session, or broker qualification is claimed.
- The branch is stacked on PR #82, which itself depends on the canonical-domain and PostgreSQL branches. Its checks do not independently qualify those parent branches.

## Next engineering gates

1. Review and qualify this exact branch head with TypeScript build/tests, PostgreSQL integration, repository hygiene, and Mermaid validation.
2. Qualify the dependency chain (#76 → #81 → #82) and the concrete RiskEngine implementation (#86) on their respective exact heads.
3. Bind `PreTradeAuthorizationService` to the concrete RiskEngine and `PostgresTradingRepository` in the backend composition root, with an authenticated local IPC boundary.
4. Add request-level idempotency/replay retrieval before exposing an order-intent command route.
5. Keep OMS persistence distinct from broker dispatch; add execution only after durable outbox ownership/fencing, the centralized risk gate, and broker-state reconciliation are qualified.

