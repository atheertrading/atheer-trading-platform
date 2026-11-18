# ATHEER Trading Pro — Screen Design Blueprint v1

> Status: Proposed visual and interaction baseline. This document does not approve production trading, Phase 01, or any unverified screen implementation.
> Parent design foundation: [IPDS v1 Foundation](./IPDS_V1_FOUNDATION.md).

## 1. Purpose and authority

This blueprint translates the owner-approved design direction into a reviewable screen system for the native macOS application. It is a design contract for future implementation, not evidence that all listed modules already exist.

Authority order:
1. Explicit owner-approved decisions and signed-off product requirements.
2. Accepted architecture and domain specifications in this repository.
3. Existing implementation and tests as evidence of current behavior only.
4. This blueprint for proposed visual composition and interaction contracts.
5. Generated concept artwork as inspiration only; it is not a source of truth for prices, account state, controls, or execution behavior.

The four generated concept compositions from the design session are represented by a companion visual reference board. Their fabricated quotes, account values, win rates, risk limits, AI probabilities, and broker status are illustrative placeholders and must never be copied into production UI or tests.

## 2. Design principles

### P-01 — Clarity Under Pressure
Prioritize decision-relevant information, stable hierarchy, legible numeric values, and unambiguous action states. Avoid decorative effects that reduce data density or contrast.

### P-02 — Dark-first, adaptive appearance
Dark is the first-run appearance. Light is a fully supported semantic theme, not a color inversion. Every component must use semantic tokens rather than hard-coded colors. The canonical brand-turquoise discrepancy (#40E0D0 vs #00CEC8) remains unresolved and must not be silently normalized.

### P-03 — Adaptive information density
Support Compact, Balanced, and Spacious presentation modes. Density may alter spacing and row height, but must not suppress risk warnings, environment identity, quote freshness, order state, or confirmation details.

### P-04 — Persistent operational context
The application shell keeps broker/account/environment identity, connection health, data freshness, notifications, and critical risk state visible regardless of workspace customization.

### P-05 — Workspace/presentation separation
Panels are views over domain services. Hiding, closing, detaching, or deleting a panel must not stop a strategy, cancel an order, close a position, or terminate a feed. Layout changes are validated and versioned; invalid layouts retain the last valid snapshot.

### P-06 — Governed financial actions
Manual, strategy, and permissioned-agent requests converge into an immutable order intent, then identity/capability checks, domain and broker-spec validation, central RiskEngine authorization, OMS persistence, Execution Gateway, broker observation, and reconciliation. UI code never calls dealing endpoints directly.

### P-07 — Data provenance and freshness
Every market/account value must retain source, timestamp, environment, and freshness state. Distinguish live, delayed, stale, unavailable, simulated, and historical data. Never render mock data as broker-confirmed data.

### P-08 — Explainable AI, no execution authority by default
Atheer Mind OS presents evidence, assumptions, confidence, limitations, and recommendations. Agents cannot bypass identity, RiskEngine, OMS, or Execution Gateway. AI outputs are not broker facts.

### P-09 — Accessibility and localization
Keyboard-first navigation, VoiceOver labels, scalable typography, adequate contrast, reduced-motion behavior, and English/Arabic RTL layout are architectural requirements. RTL must be validated at component and screen level.

### P-10 — Operational failure is a first-class state
Design loading, empty, disconnected, stale, permission-denied, partial, rejected, pending, unknown-outcome, and reconciliation-required states. A timeout is not proof that an order failed; reconcile before retry.

## 3. Application shell

Persistent regions:
- Primary navigation: task-oriented product areas.
- Global command/search region: instrument search and command discovery; destructive or financial actions require explicit confirmation.
- Environment/account context: broker, account label, DEMO/LIVE identity, connection state.
- Workspace tabs and panel canvas.
- Persistent operational strip: market-data freshness, broker connectivity, RiskEngine/OMS/Execution Gateway health, alerts.
- Native window controls remain distinct from panel controls.

Target information architecture (12 groups):
1. Command Center
2. Markets
3. Charts & Analysis
4. Intelligence & Research
5. Strategy Center
6. Automated Trading
7. Trading & Execution
8. Positions & Portfolio
9. Risk Management
10. Performance & Analytics
11. Atheer Mind OS
12. System & Administration

This is target IA, not a claim that all 12 areas are implemented.

## 4. Screen contracts

| ID | Screen | Primary composition | Critical states and interactions |
|---|---|---|---|
| SCR-01 | Command Center | account summary, market overview, positions, alerts, service health | no account, partial broker data, stale quote, margin warning, disconnected |
| SCR-02 | Markets | watchlists, instrument explorer, quote detail, movers, feed quality | searching, no results, market closed, delayed/stale/unavailable quote |
| SCR-03 | Charts & Analysis | chart canvas, timeframe/toolbars, indicators, drawings, instrument context | loading history, stream gap, reconnect, unsupported interval, saved layout |
| SCR-04 | Intelligence & Research | news, calendar, fundamentals, sentiment, volatility, event impact | source timestamp, conflicting sources, stale research, unavailable provider |
| SCR-05 | Strategy Center | strategy library, builder, parameters, versions, backtest summary | draft/validated/invalid, reproducibility metadata, out-of-sample warning |
| SCR-06 | Automated Trading | running strategies, allocations, permissions, schedule, health | armed/paused/stopped/error; pause-new-entries must be distinct from close positions |
| SCR-07 | Trading & Execution | order ticket, preview, risk assessment, OMS timeline, execution report | validation failure, risk rejection, pending, partial fill, rejected, unknown outcome |
| SCR-08 | Positions & Portfolio | positions, exposure, P&L, protection, lifecycle actions | broker reconciliation, partial close, market unavailable, stale valuation |
| SCR-09 | Risk Management | limits, drawdown, margin, exposure map, alerts, emergency controls | warning/breach/locked; emergency actions require strong confirmation and audit |
| SCR-10 | Performance & Analytics | equity curve, returns, drawdown, trade stats, attribution, journal | sample-size warning, incomplete history, currency/timezone basis |
| SCR-11 | Atheer Mind OS | agents, analysis workspace, evidence, recommendations, model/permission state | confidence and provenance, model unavailable, stale context, human approval required |
| SCR-12 | System & Administration | brokers, accounts, environments, connections, security, audit, diagnostics, preferences | secret masked, permission denied, connection lifecycle, DEMO/LIVE unmistakable |

### Shared screen anatomy
- Header: screen title, selected context, key scope, non-destructive actions.
- Main work area: task-specific analytical content.
- Context rail or inspector: details for current selection, collapsible without losing state.
- Footer/status region: source/freshness and operational state where relevant.
- Empty/error/loading states are designed intentionally, not left to generic placeholders.

## 5. Trading-specific UI invariants

- DEMO/LIVE identity is always explicit and visually distinct; never infer environment from color alone.
- No default order size, stop distance, target, risk amount, or account value may be fabricated.
- Order preview must disclose instrument, side, order type, quantity, price constraints, stop/limit values, estimated costs if available, account, environment, and risk decision.
- A user action creates an intent; it does not imply broker acceptance or fill.
- OMS lifecycle states must distinguish draft, pending authorization, authorized, submitted, acknowledged, partially filled, filled, cancelled, rejected, expired, and unknown.
- Unknown outcome triggers broker reconciliation before retry.
- Position display must distinguish broker-confirmed quantity/average price from derived analytics.
- Emergency controls must be separated from routine controls, confirmed, permission-checked, and audited.
- AI and strategy screens may request actions only through the same governed intent path.

## 6. Visual language and component rules

- Use the existing IPDS semantic-token hierarchy: brand primitives → semantic roles → component variants → screen composition → visual QA.
- Color is redundant encoding, never the only status signal; pair it with text/icon/shape.
- Green/red semantics must account for locale, instrument convention, and accessibility; never rely on color alone.
- Financial numerals use tabular/monospaced alignment where comparison matters.
- Tables need stable column alignment, sorting, filtering, row selection, virtualization for large datasets, and explicit stale/loading states.
- Charts must identify instrument, timeframe, timezone, price basis, and data status; indicators must be independently configurable.
- Tooltips explain uncommon metrics and actions without hiding essential labels.
- Native macOS conventions apply to window lifecycle, menus, keyboard shortcuts, focus, accessibility, and settings behavior.
- Avoid gratuitous gradients, glow, excessive rounded cards, decorative animal imagery, and high-saturation surfaces that compete with live data.

## 7. Visual reference status

The companion concept board is a low-fidelity-to-mid-fidelity visual direction reference, not a pixel-perfect specification. It combines multiple screen concepts and intentionally uses placeholder data. Before implementation, each screen requires its own approved high-fidelity frame at defined window sizes, plus compact/wide layouts, light appearance, and RTL review.

Do not derive spacing, font sizes, colors, or component dimensions from generated artwork. Extract them into measured IPDS tokens and validate against actual macOS rendering.

## 8. Design decisions and unresolved questions

| ID | Decision / question | Status | Rule |
|---|---|---|---|
| D-001 | Dark-first appearance | Owner-approved | Preserve |
| D-002 | Adaptive information density | Owner-approved | Preserve; no critical data suppression |
| D-003 | English + Arabic full RTL | Owner-approved | Preserve |
| D-004 | 12-area task-oriented IA | Architecture target | Screen ownership and naming require design review |
| D-005 | Persistent operational strip | Proposed | Validate against shell/navigation spec |
| D-006 | Compact/Balanced/Spacious modes | Proposed detail under D-002 | Define exact token deltas and user preference |
| Q-001 | Canonical brand turquoise #40E0D0 vs #00CEC8 | Unresolved | Do not silently change existing token |
| Q-002 | Exact screen breakpoints/minimum window sizes | Pending | Measure on supported macOS versions and displays |
| Q-003 | Which controls belong in shell vs contextual screen | Pending | Resolve in screen-level interaction specs |
| Q-004 | Live trading affordance policy and approval UX | Pending | Must follow trading governance and explicit owner approval |
| Q-005 | Charting engine/library and performance budget | Pending | Architecture decision required before implementation |
| Q-006 | Arabic typography/font and number-format policy | Pending | Validate shaping, bidi, financial numerals, and mixed-direction data |

## 9. Engineering estimates

Estimates are engineering planning ranges, not commitments. They assume the existing SwiftUI app and IPDS foundation remain usable, domain services expose stable contracts, and no major broker/backend redesign is required. One engineer, focused full-time; excludes owner review latency.

| Work package | Estimate | Confidence | Dependencies / exit evidence |
|---|---:|---|---|
| Design-system token/component audit and gap closure | 3–5 engineer-days | Medium | accepted token decisions, contrast/accessibility audit |
| App shell, navigation, global context, status strip | 5–8 engineer-days | Medium | navigation and window lifecycle contracts |
| Command Center | 4–6 engineer-days | Medium | account/market/position/health read models |
| Markets | 5–8 engineer-days | Medium | instrument catalog, quote provenance/freshness |
| Charts & Analysis | 8–15 engineer-days | Low | chart technology decision, historical + streaming data |
| Intelligence & Research | 5–9 engineer-days | Low | source contracts, timestamps, provider policy |
| Strategy Center | 6–10 engineer-days | Low | strategy domain, validation and backtest APIs |
| Automated Trading | 6–10 engineer-days | Low | strategy lifecycle and permission model |
| Trading & Execution UI | 8–12 engineer-days | Low | OMS, RiskEngine, broker specs, reconciliation contracts |
| Positions & Portfolio | 5–8 engineer-days | Medium | broker-confirmed positions and valuation model |
| Risk Management | 6–10 engineer-days | Low | central risk policies, exposure and margin model |
| Performance & Analytics | 5–9 engineer-days | Low | normalized trade history and calculation definitions |
| Atheer Mind OS | 6–10 engineer-days | Low | agent governance, provenance, model observability |
| System & Administration | 5–8 engineer-days | Medium | broker connection and secure settings contracts |
| Visual/accessibility/localization QA across screens | 8–12 engineer-days | Medium | implemented screens, owner Mac/device matrix |

Indicative sequential implementation total: 81–140 engineer-days, excluding major backend/domain work, design approval delays, and broker certification. Parallel work may reduce calendar duration but increases integration and review overhead. Re-estimate after shell + first two data screens are implemented and measured.

## 10. Delivery sequence and gates

1. Foundation: approve IPDS tokens, shell contract, navigation and window/panel lifecycle.
2. Read-only operational core: Command Center + Markets, with authentic broker data and freshness.
3. Analysis: Charts + Research, with source/timezone/data-quality semantics.
4. Governed trading: Positions + order preview + OMS/RiskEngine integration; DEMO only.
5. Strategy and automation: strategy lifecycle, simulation/backtest evidence, permissioning.
6. Risk, analytics, Mind OS, administration.
7. Release qualification: build/test, launch, visual QA, accessibility, RTL, multi-display, security, DEMO reconciliation.

No phase is complete by mockup approval alone. Each screen requires: design review, domain contract review, implementation, automated tests, owner-machine build/launch evidence, screenshot comparison, accessibility/RTL review, and operational-state verification.

## 11. Acceptance checklist

- [ ] Owner approves screen-level high-fidelity designs and unresolved decisions.
- [ ] All screen states listed in section 4 have explicit designs.
- [ ] All displayed values carry source, timestamp, environment, and freshness semantics.
- [ ] Manual/strategy/agent actions converge on the governed order-intent path.
- [ ] No UI module bypasses RiskEngine, OMS, or Execution Gateway.
- [ ] DEMO/LIVE identity cannot be confused.
- [ ] Dark and Light are independently contrast-checked.
- [ ] English and Arabic RTL are tested on every shared component and screen.
- [ ] Keyboard, VoiceOver, focus, reduced motion, and scalable text are verified.
- [ ] Layout restoration and multi-display recovery are tested.
- [ ] CI and owner-machine build/test/launch evidence are attached.
- [ ] Generated concept artwork is not treated as approved implementation specification.

## 12. Change control

Changes to approved principles, trading-action semantics, broker/environment indicators, risk visibility, or data provenance require an explicit decision-log entry and review by the relevant design/engineering authority. Visual refinements that do not alter behavior may be grouped into focused design PRs. Keep screen implementation PRs bounded and independently testable.
