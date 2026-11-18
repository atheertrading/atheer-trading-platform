# ATHEER Trading Pro — 12-Screen Pixel Specification v1

**Work package:** ATP-UI-IPDS-012  
**Team:** A — UI / Frontend Engineering  
**Tracking:** GitHub Issues #72, #77, #79  
**Parent implementation:** PR #89 — native application shell  
**Review status:** **Design-review candidate; not yet approved**  
**Revision:** 2026-11-19

## 1. Scope and precision model

This package supplies twelve screen-specific, vector-native compositions. Every SVG has a fixed logical coordinate system and an exact 2× raster-export size:

| Property | Value |
|---|---:|
| Logical design viewport | **1440 × 900 pt** |
| SVG viewBox | `0 0 1440 900` |
| 2× export canvas | **2880 × 1800 px** |
| Scale | 2 physical pixels per logical point |
| Appearance / locale / density | Dark / English LTR / Balanced |
| Asset format | SVG (editable vector source) |

The existing native app declares a 900 × 600 pt content-layout minimum. It is retained as the responsive source baseline, not reclassified as fully visually qualified. The 1440 × 900 pt canvas is the wide design target, not a new minimum window requirement. SwiftUI uses logical points; the PNG export dimension is not an NSWindow size.

The SVG coordinate geometry is deterministic. Native pixel-perfect qualification is a separate activity because SwiftUI font baselines, system controls, title-bar chrome, backing scale, accessibility sizing and adaptive layout can differ from vector artwork.

## 2. Authority and status

D-001 (dark-first), D-002 (adaptive information density) and D-003 (English/Arabic full RTL) remain the owner-approved design direction. The current semantic palette is inherited from the code foundation; this package does not resolve the outstanding `#40E0D0` vs `#00CEC8` brand-turquoise conflict.

The four supplied showcase boards are composite visual inspiration, not approved screen-specific frames or measurement sources. Illustrative prices, balances, P&L, probabilities, performance and broker states in those references are not copied into these assets or production code.

**No screen in this package is marked Approved.** Owner/design-authority review, Light and Arabic/RTL variants, native macOS screenshot comparison, accessibility and minimum-window qualification remain required.

## 3. Twelve-screen inventory and crosswalk

The official TEAM A assignment enumerates separate Trading, Positions, Orders, Risk and Portfolio destinations. The screen blueprint groups Positions & Portfolio, while also splitting Intelligence & Research from Atheer Mind OS and listing Performance & Analytics separately. This package follows the twelve destinations in the Team A assignment and records the following proposed crosswalk so no operational area is silently discarded:

| Design | Team A screen | Blueprint mapping |
|---|---|---|
| SCR-01 | Command Center | SCR-01 Command Center |
| SCR-02 | Markets | SCR-02 Markets |
| SCR-03 | Charts & Analysis | SCR-03 Charts & Analysis |
| SCR-04 | Trading & Execution | SCR-07 Trading & Execution |
| SCR-05 | Positions | Positions portion of SCR-08 |
| SCR-06 | Orders | OMS/order lifecycle within SCR-07 |
| SCR-07 | Risk Management | SCR-09 Risk Management |
| SCR-08 | Portfolio & Performance | Portfolio portion of SCR-08 + SCR-10 Performance & Analytics |
| SCR-09 | Strategy Center | SCR-05 Strategy Center |
| SCR-10 | Automated Trading | SCR-06 Automated Trading |
| SCR-11 | Intelligence & Atheer Mind OS | Combined SCR-04 Intelligence & Research + SCR-11 Atheer Mind OS |
| SCR-12 | System & Administration | SCR-12 System & Administration |

This is a documented reconciliation proposal, not a declaration that the competing screen taxonomies have been formally approved. The production app still exposes only implemented navigation destinations. These design files do not add placeholder routes.

## 4. Shared shell geometry

All twelve SVGs use the same wide-canvas shell coordinates (logical points):

| Region | x | y | width | height | Contract |
|---|---:|---:|---:|---:|---|
| Sidebar | 0 | 0 | 224 | 900 | PR #89 ideal 224; min 190 / max 280 |
| Global command bar | 224 | 0 | 1216 | 64 | Existing shell value |
| Detail content inset | 248 | — | — | — | 24 pt from detail edge |
| Screen eyebrow baseline | 248 | 91 | — | — | 8 pt monospaced |
| Screen title baseline | 248 | 118 | — | — | 23 pt bold |
| Screen subtitle baseline | 248 | 140 | — | — | 10 pt |
| Main content origin | 248 | 164 | 1168 | 666 | Screen-specific composition |
| Persistent status strip | 224 | 858 | 1216 | 42 | Wide design target; current native strip sizes adaptively |

The sidebar in the assets visualizes the full *target IA* for review. It does not represent working navigation today; the app shell is intentionally limited to its four implemented destinations until more screens are real and qualified.

### 4.1 Component metrics

- Content inset: 24 pt.
- Panel stroke: 1 pt; panel radius: 9–10 pt; panel surface: `#1A1E1F`.
- Panel header reservation: 54 pt.
- Panel title: 13 pt semibold; panel metadata: 9 pt.
- Panel horizontal inset: 16 pt.
- Compact status labels: 8–9 pt; support copy: 9–10 pt.
- Financial identifiers use monospaced alignment when a verified value exists.
- Semantic roles inherit the current token baseline: canvas `#121212`, sidebar `#093732`, panel `#1A1E1F`, elevated surface `#242A2B`, separator `#354044`, primary text `#F1F5F5`, secondary `#AAB6B8`, accent `#00CEC8`, attention `#FFD700`, danger `#EF5350`, positive `#00C853`.

The 42 pt status-strip allocation is a wide-layout design target in the SVG; the actual native component currently uses adaptive intrinsic height and must be screenshot-measured before this is treated as an implementation pixel contract.

## 5. Screen design contracts

### SCR-01 — Command Center
Four service/account status tiles, market overview, operational alerts, configurable workspace panels and recent activity. Missing market/account/event sources remain explicitly unavailable. No quote, position, balance or P&L sample is shown.

### SCR-02 — Markets
Instrument discovery/search, authenticated DEMO session context, provider-backed catalogue table and instrument inspector. The present search contract returns identity metadata; no bid/ask/last quote is introduced without timestamp/freshness data.

### SCR-03 — Charts & Analysis
Instrument/timeframe/price-basis toolbar, primary chart canvas, indicator inspector and data-quality rail. No synthetic candles, volume, prices, indicator outputs or drawings are drawn.

### SCR-04 — Trading & Execution
Separate intent intake, identity, risk-authorization and Execution Gateway states; order ticket, risk preview and OMS lifecycle. No default side, size, stop, target, price or account. All dealing affordances remain unavailable until the governed domain path is implemented and qualified.

### SCR-05 — Positions
Broker-confirmed position summary and position ledger with quantity, average price, P&L, protection and lifecycle columns. No assumed zero position or synthetic valuation.

### SCR-06 — Orders
OMS overview, lifecycle filters and order ledger. Open, pending/unknown, completed, rejected, cancelled and partial-fill states must remain distinct when supported by the verified contract. No sample order rows.

### SCR-07 — Risk Management
RiskEngine state, policy version, account valuation, policy/limit table, exposure view and emergency-control region. No risk value is estimated or invented; emergency controls are unavailable without permissioned backend operations.

### SCR-08 — Portfolio & Performance
Account equity, portfolio valuation, performance, currency basis, allocation/exposure and portfolio ledger. No curve, return, drawdown, allocation or P&L figure is fabricated.

### SCR-09 — Strategy Center
Strategy library, configuration workspace, parameters/rules, validation and reproducibility rail. No unverified strategy definitions, parameters, backtest returns or suitability claims.

### SCR-10 — Automated Trading
Strategy supervisor, lifecycle state, schedule/allocation/health, permission profile and new-entry gate. Pause-new-entries, stop-strategy and close-positions remain distinct workflows; no lifecycle action is enabled.

### SCR-11 — Intelligence & Atheer Mind OS
Research source rail, evidence-led analysis workspace, evidence provenance and agent supervision. No news, sentiment, AI output, confidence percentage, provider or agent state is fabricated.

### SCR-12 — System & Administration
Appearance, locale, density, accessibility, broker/environment, runtime diagnostics, security and audit. Secrets remain masked and in secure storage; API liveness, platform readiness, broker session and trading authorization are separate state dimensions.

## 6. Data and execution invariants

- Every market/account value retains provider, environment, instrument/account identity, event timestamp, receipt timestamp and freshness/quality where applicable.
- Distinguish zero, nil, missing, unknown, unavailable, delayed, stale and not-yet-loaded.
- A user action is an intent, not broker acceptance. Acknowledgement is not a fill.
- An unknown order outcome requires reconciliation before retry.
- Manual, strategy and agent requests must converge through identity/capability validation, domain validation, central RiskEngine, OMS, Execution Gateway, broker observation and reconciliation.
- The UI never calls broker dealing APIs and never authorizes its own RiskEngine decision.
- DEMO, SIMULATION, BACKTEST and LIVE remain distinct; LIVE activation remains separately gated.
- Hiding a panel may not stop a service, strategy, feed or broker connection.

## 7. Accessibility and responsive qualification

This first asset set covers Dark / English LTR / Balanced only. Required approval variants and tests:
- Light appearance with contrast checks across every state/surface.
- Arabic RTL with mixed-direction instruments, EPICs, UUIDs, numeric values and timestamps.
- Keyboard traversal, visible focus, VoiceOver labels/values/order and state announcements.
- Non-color status encoding and scalable text.
- 900 × 600 pt minimum, intermediate width, 1440 × 900 pt wide and multi-display recovery.
- Compact/Balanced/Spacious density without hiding critical risk, broker, environment, order or data-quality information.

## 8. Native pixel qualification and approval

Before any screen is marked Approved:
1. Generate native screenshots on the supported owner Mac at the same logical viewport.
2. Compare native rendering with its SVG reference, document font/baseline and backing-pixel tolerances, and retain screenshot hashes.
3. Verify minimum/intermediate/wide windows, resize behavior, Light theme and RTL.
4. Complete keyboard/VoiceOver/accessibility and operational-state review.
5. Obtain owner and Design/Engineering Authority sign-off.

**Approval rule:** SVG geometry is measured design source, not proof of native pixel-perfect runtime. These assets are Review Candidates only.

## 9. Asset index

- [SCR-01](assets/scr-01-command-center/scr-01-command-center-dark-en-balanced-v1.svg)
- [SCR-02](assets/scr-02-markets/scr-02-markets-dark-en-balanced-v1.svg)
- [SCR-03](assets/scr-03-charts-analysis/scr-03-charts-analysis-dark-en-balanced-v1.svg)
- [SCR-04](assets/scr-04-trading-execution/scr-04-trading-execution-dark-en-balanced-v1.svg)
- [SCR-05](assets/scr-05-positions/scr-05-positions-dark-en-balanced-v1.svg)
- [SCR-06](assets/scr-06-orders/scr-06-orders-dark-en-balanced-v1.svg)
- [SCR-07](assets/scr-07-risk-management/scr-07-risk-management-dark-en-balanced-v1.svg)
- [SCR-08](assets/scr-08-portfolio-performance/scr-08-portfolio-performance-dark-en-balanced-v1.svg)
- [SCR-09](assets/scr-09-strategy-center/scr-09-strategy-center-dark-en-balanced-v1.svg)
- [SCR-10](assets/scr-10-automated-trading/scr-10-automated-trading-dark-en-balanced-v1.svg)
- [SCR-11](assets/scr-11-intelligence-mind-os/scr-11-intelligence-mind-os-dark-en-balanced-v1.svg)
- [SCR-12](assets/scr-12-system-administration/scr-12-system-administration-dark-en-balanced-v1.svg)

## 10. Immediate implementation sequence

Implement each screen as a bounded SwiftUI feature against a verified UI-facing domain contract. Keep current production navigation restricted to functioning modules; do not duplicate PR #70 charting/data work. Update Issue #72 only when implementation and the relevant acceptance evidence exist.
