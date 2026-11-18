# ATP-RISK-001 — Centralized Pre-Trade RiskEngine Foundation

**Status:** Implemented on a stacked backend feature branch; exact-head verification pending  
**Work package:** ATP-RISK-001A  
**Owner:** Team B — Backend Engineering  
**Source:** `services/api/src/risk/risk-engine.ts`  
**Tests:** `services/api/test/risk-engine*.test.mjs`  
**Dependency:** PR #81 — PostgreSQL persistence on the canonical domain (itself stacked on PR #76)

## 1. Purpose and boundary

Establish one backend pre-trade risk evaluation boundary for manual, strategy, algorithm, position-management, risk-management, AI-agent and system-originated order intents. The engine consumes the canonical `OrderIntentEnvelope`, explicit versioned policy, account/instrument/market evidence, and an exact-intent projected portfolio-risk snapshot. It returns a canonical `RiskAssessment`.

This increment is an application-service foundation only. It does not add an HTTP route, UI contract, order submission, dealing adapter, outbox consumer, OMS transition worker or Execution Gateway. No caller is granted broker-dealing authority by receiving an assessment. OMS persistence remains a separate dependent capability and must persist the exact immutable intent and matching `AUTHORIZED` assessment before creating an OMS order.

## 2. Decision contract

The engine produces the canonical outcomes:

| Outcome | Meaning |
|---|---|
| `AUTHORIZED` | All configured policy constraints and evidence requirements passed, and the injected trading-control boundary explicitly reports the environment enabled and not halted |
| `REJECTED` | A deterministic policy, instrument, market, order, exposure, or emergency-halt constraint was breached |
| `HELD` | Policy/context is missing or invalid, authority/evidence is incomplete or stale, currencies/provenance do not match, or trading controls are unavailable/disabled |

An invalid policy, missing context, missing account field, stale account/portfolio data, untrusted or mismatched quote, missing required broker quantity metadata, unavailable control provider, or disabled trading is never converted into implicit authorization. Provider exceptions are sanitized into stable reason codes; raw exception text is not exposed in the assessment.

Every assessment records:
- the exact order-intent ID;
- the policy version;
- evaluation timestamp;
- deterministic reason codes;
- source/evidence references for the decision;
- internal RiskEngine provenance and environment.

## 3. Dependency-injected contracts

### Policy provider

`RiskPolicyProvider` supplies a versioned policy scoped by broker account and trading environment. It is responsible for authoritative policy loading, version selection and policy lifecycle. The engine does not invent account limits, position limits, loss limits, risk percentages, margin thresholds, stop-loss parameter names or policy defaults.

The policy includes explicit account currency, permitted intent origins and permission-profile references, risk-increasing operation codes, required account fields, maximum order quantity, broker-size/tick requirements, position counts, per-trade/account/instrument risk and exposure limits, daily-loss/drawdown limits, spread limits, quote/account/portfolio freshness thresholds, optional minimum available funds/margin and maximum used-margin constraints, and stop-loss requirements.

All money-valued risk limits must use the configured account currency. Cross-currency comparison is not performed by this engine. A mismatch is held; no implicit FX conversion or rate source is assumed.

### Risk context provider

`RiskContextProvider` supplies provenance-bearing evidence for the exact intent:
- broker account identity and broker-authoritative account snapshot;
- provider/broker instrument identity and versioned trading specification;
- provider quote with Bid and Ask kept separate, source identity and event/receipt timestamps;
- `PortfolioRiskSnapshot`, internally sourced and bound to the exact intent, account, instrument and environment.

The portfolio snapshot contains projected post-intent open-position counts, per-trade risk, account/instrument gross exposure, daily loss and drawdown, plus the valuation-model version and provenance. It is an input contract for a future deterministic portfolio/valuation service, not a calculation implemented by this increment. The RiskEngine validates those values against the policy; it does not manufacture contract multipliers, FX conversions, derivative valuations, notional exposure, stop distance, slippage, fees, financing or position-sizing formulas.

The intent must reference the exact market quote ID and event timestamp supplied to the risk evaluation. The internal portfolio projection must reference the same intent. Cross-environment or cross-instrument evidence cannot be reused.

### Trading controls and deterministic dependencies

Clock, assessment-ID generation, risk-policy lookup, risk-context lookup and trading/emergency controls are injected interfaces. Control-provider failure produces `HELD`. The supplied `DisabledRiskTradingControls` reports trading disabled in every environment and is a fail-closed default; no production or DEMO runtime wiring is included here.

## 4. Implemented deterministic checks

- Policy schema/version/environment and permitted origin/permission-profile/operation checks.
- Exact account, instrument, broker specification, environment and source-provenance correlation.
- Required account-value presence and currency checks; explicit policy-bound minimum funds, minimum available margin and maximum used-margin checks.
- Account and portfolio snapshot freshness.
- Provider quote event-age classification using policy-supplied thresholds; future-dated quotes are held, automated non-human risk-increasing entries are blocked beyond the configured entry threshold, and stale quotes are rejected for new risk-increasing intents.
- Positive, non-crossed Bid/Ask validation; exact base-10 spread calculation with integer coefficients (no binary floating-point arithmetic).
- Spread unit/currency compatibility.
- Required BUY/SELL direction and positive order quantity.
- Quantity unit, precision, policy maximum, broker minimum/maximum deal size and broker quantity-increment validation.
- Price precision, optional broker tick-size and quote tick-alignment validation.
- Policy-configured stop-loss parameter presence, unit/currency/precision/tick alignment and protective direction relative to the provider quote.
- Projected open-position counts, per-trade risk, gross account/instrument exposure, daily loss and drawdown compared with explicit policy limits.
- Emergency trading halt and disabled/unavailable trading-control behavior.

## 5. Freshness and numeric policy

The engine contains no baked-in numeric freshness or financial policy values. Freshness thresholds are supplied by the policy provider and validated for monotonic ordering. The historical five-second normal / ten-second automated-entry block / fifteen-second stale reference is retained as a requirement to reconcile, not a hardcoded runtime default. Test fixtures may use those example values solely to exercise the logic.

Likewise, the historical 0.25% strategy-risk reference is not used as a universal account or per-trade limit. No financial limit is activated by this module without an explicit policy.

Decimal quantities, prices and monetary values use the canonical string-decimal domain. Spread subtraction and comparison avoid JavaScript floating-point arithmetic.

## 6. Security and trading controls

- The module has no broker SDK, dealing operation, order-submission operation, database connection or HTTP route.
- No Strategy or AI-originated intent gains permission unless its origin and permission-profile reference are explicitly permitted by policy.
- Every source converges on the same evaluation interface; no source-specific bypass is added.
- `AUTHORIZED` is only an assessment result. It is not a broker order, execution command, OMS persistence record or fill.
- `CAP_ALLOW_TRADING=false` remains unchanged. Production/default controls remain disabled.
- DEMO, SIMULATION, BACKTEST and LIVE are environment-bound. This increment does not enable LIVE, or claim any broker DEMO dealing qualification.
- No credentials, real account data or actual market prices are committed.

## 7. Deliberately outstanding capabilities

The following remain separate work packages and are not claimed implemented by ATP-RISK-001A:
- authoritative persisted policy registry and policy approval/version lifecycle;
- broker account, position, order and balance read models wired into the context provider;
- deterministic multi-asset valuation service that computes exact post-intent portfolio projections;
- approved FX conversion sources, instrument-specific valuation, margin model and derivatives/CFD semantics;
- market-session calendars, instrument trading-state/capability restrictions and session constraints;
- portfolio-level correlated exposure, concentration and stress scenarios;
- RiskAssessment persistence and transactional OMS integration on the canonical PostgreSQL branch;
- authenticated API/IPC exposure and the single governed intent intake path;
- Execution Gateway, broker dealing, broker-state reconciliation and controlled DEMO lifecycle qualification.

No production risk limits or calculation semantics are inferred to fill these gaps. The engine remains disconnected from runtime execution until each dependency is supplied and separately qualified.

## 8. Acceptance and verification

The deterministic tests cover allowed and denied intents, disabled controls, control-provider failure, policy/context unavailability, exact quantity/price increments, spread/crossed quotes, quote freshness, stale account/portfolio evidence, currency mismatch, per-trade/account/instrument exposure, open-position counts, daily-loss/drawdown, stop-loss requirements, missing instrument metadata, and environment/permission boundaries.

Hosted Node.js 24 TypeScript type-check/build and the complete API test suite on this feature branch are the required first verification. Repository hygiene, CodeQL, Mermaid rendering and Local Sync Safety are also required on the exact final PR head. No local Node.js 24 execution, owner-Mac runtime, authenticated broker DEMO or trading lifecycle pass is claimed.

## 9. Integration sequence

PR #85 is intentionally stacked on PR #81, which is stacked on PR #76. Do not merge this RiskEngine foundation to `main` before the canonical domain and persistence dependencies are integrated and requalified. After integration, a subsequent bounded work package must provide real policy/context adapters and persist the exact risk assessment through the governed intent/OMS transaction. A further gate is required for Execution Gateway and DEMO dealing; LIVE remains separately prohibited.
