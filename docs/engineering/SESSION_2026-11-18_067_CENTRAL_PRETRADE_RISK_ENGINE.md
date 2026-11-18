# Engineering Session 067 — Central Pre-Trade RiskEngine Foundation

**Date:** 2026-11-18  
**Assignment:** ATP-TEAM-B-001  
**Work package:** ATP-RISK-001A  
**Repository:** `atheertrading/atheer-trading-platform`  
**Branch:** `feat/central-risk-engine-foundation`  
**Parent:** PR #81 — `feat/postgres-persistence-on-canonical-domain`  
**Upstream dependency:** PR #76 — canonical multi-asset trading domain

## Objective

Implement a provider-independent, deterministic pre-trade risk assessment boundary using the canonical trading-domain contracts, without inventing owner risk limits or introducing an unqualified dealing path.

## Implemented

- Added `services/api/src/risk/risk-engine.ts` with a policy-driven `RiskEngine` and injected policy, context, clock, assessment-ID and trading-control interfaces.
- Consumes the canonical `OrderIntentEnvelope` and creates canonical `RiskAssessment` records with `AUTHORIZED`, `REJECTED` or `HELD` outcome, policy version, reasons, source references and internal RiskEngine provenance.
- Added identity/environment/provenance and exact-intent checks across account, account snapshot, instrument, broker specification, provider quote and projected portfolio-risk evidence.
- Requires the intent to reference the precise quote ID and provider event timestamp used by the decision.
- Validates account/portfolio snapshot age and configurable quote-age bands. The engine has no embedded freshness thresholds; tests use illustrative 5s/10s/15s values only.
- Validates positive, non-crossed Bid/Ask and maximum spread using exact base-10 subtraction and decimal comparison.
- Validates order direction, quantity units/precision, policy maximum, broker minimum/maximum, quantity increments, quote price precision/tick size and policy-named protective stop-loss.
- Validates explicit policy limits for projected positions, per-trade risk, account/instrument gross exposure, daily loss and drawdown; all monetary risk values must use the configured account currency.
- Added explicit optional policy boundaries for minimum available funds, minimum available margin and maximum used margin. When a configured constraint requires an account field, its absence produces `HELD`.
- Restricts intent origins, permission-profile references and risk-increasing operation codes using the supplied policy.
- Missing/invalid policy or context, stale/mismatched evidence, missing broker minimum-size metadata, unavailable controls, disabled trading and control-provider exceptions fail closed.
- Added `DisabledRiskTradingControls` which does not authorize trading in any environment.
- Added deterministic unit/contract-style tests in `services/api/test/risk-engine.test.mjs` and `services/api/test/risk-engine-policy-boundaries.test.mjs`.
- Added architecture documentation `docs/architecture/ATP_RISK_ENGINE_PRETRADE_FOUNDATION.md`, Mermaid diagram 15, diagram index entry and backend README explanation.

## Deliberate non-implementation

- No HTTP route or API contract for risk evaluation has been exposed.
- No runtime policy provider, account/position repository or portfolio valuation service is wired.
- The `PortfolioRiskSnapshot` is an input contract from a future deterministic valuation boundary. This engine does not calculate FX conversions, CFD/derivative contract values, notional exposure, margin formulas, stop-distance sizing, fees, financing, stress or correlation.
- No database policy registry, risk-assessment persistence adapter or OMS transaction wiring is included.
- No outbox dispatcher, order-submission endpoint, Execution Gateway, broker dealing call or DEMO order has been added.
- No production risk percentages or financial limits are hardcoded. The earlier 0.25% strategy reference is not generalized into a universal limit.
- LIVE remains disabled; `CAP_ALLOW_TRADING=false` remains unchanged.

## Architecture decisions and assumptions

- Risk policies are explicit, versioned, scoped by environment/account and supplied through a provider port.
- Currency conversion is not inferred. A mismatch between account/policy/valuation currencies is held.
- Portfolio projected risk values must be computed elsewhere using a named, provenance-bearing valuation model and be bound to the exact order intent.
- The configured risk policy is the sole authority for limits and freshness thresholds; no universal defaults are introduced.
- This branch is stacked on PR #81, itself stacked on PR #76. It must not merge to `main` before the canonical domain and persistence dependencies are integrated and requalified.

## Changed files

- `services/api/src/risk/risk-engine.ts`
- `services/api/test/risk-engine.test.mjs`
- `services/api/test/risk-engine-policy-boundaries.test.mjs`
- `services/api/README.md`
- `docs/architecture/ATP_RISK_ENGINE_PRETRADE_FOUNDATION.md`
- `docs/architecture/diagrams/15-risk-engine-pretrade-foundation.mmd`
- `docs/architecture/diagrams/README.md`

## Verification status

- Source and test files are committed to the feature branch.
- No Node.js 24 local execution is available in this environment; the API package requires Node >=24.
- Hosted TypeScript build/type-check, full API suite, repository hygiene, CodeQL, Mermaid and Local Sync Safety must be run on the exact PR head.
- No test pass is claimed until exact-head CI results are retrieved and inspected.
- No owner-Mac build/runtime, live Keychain, authenticated Capital.com DEMO or trading lifecycle qualification is claimed.

## Next dependencies

1. Run exact-head backend TypeScript build and full test suite on Node.js 24.
2. Resolve any compile/test findings; rerun all relevant checks after the last commit.
3. Qualify Mermaid, repository hygiene, CodeQL and Local Sync Safety.
4. Keep PR stacked on #81 and draft until #76/#81 are qualified and the dependency order is reconciled.
5. Implement authoritative policy storage and portfolio valuation/read models as subsequent work packages before wiring RiskEngine into order-intake/OMS.
6. Persist the exact risk assessment and order intent transactionally; preserve the OMS exact-assessment requirement.
7. Only later implement the single Execution Gateway and controlled DEMO dealing; no LIVE activation.

## Exact-head hosted CI checkpoint — `e19897895b179d47c4ffee7b5fe68857fc20080f`

- GitHub CI run `44394828144`:
  - Backend Toolchain: **passed** — Node.js 24 setup; TypeScript type-check and build; complete API suite.
  - API tests: **59 passed, 0 failed** (workflow backend job `135121823729`).
  - Repository Hygiene: **passed** (job `135121823904`).
- Mermaid architecture diagram workflow `44394828042`: **passed**.
- Local Sync Safety workflow `44394827971`: **passed**.
- Intel x86_64 macOS build/XCTest/Swift CodeQL job `135121823003`: **queued** at last inspection.
- Apple Silicon arm64 macOS build/XCTest/Swift CodeQL job `135121824981`: **queued** at last inspection.
- The PR remains Draft. No full cross-architecture qualification or merge-readiness claim is made until both macOS jobs and the exact dependency chain are complete.

