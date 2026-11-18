# IPDS Screen Design — Decision and Engineering Notes

## Record metadata
- Scope: ATHEER Trading Pro macOS screen design system and 12-area target information architecture.
- Parent baseline: `docs/design/IPDS_V1_FOUNDATION.md`.
- Screen specification: `docs/design/ATHEER_SCREEN_DESIGN_BLUEPRINT_V1.md`.
- Status: proposed; owner and Design/Engineering Authority sign-off pending.
- Evidence class: generated concept artwork and authored structural wireframe; neither proves implementation.

## Approved inputs carried forward
- D-001: Dark-first appearance.
- D-002: Adaptive information density.
- D-003: English/Arabic full RTL.
- Capital.com is the primary recorded broker integration.
- Broker-confirmed values are authoritative; do not invent market/account state.
- Manual and automated requests share central RiskEngine, OMS, and Execution Gateway governance.
- `CAP_ALLOW_TRADING=false` remains in force pending the required DEMO qualification and explicit LIVE authorization.

## Engineering observations
1. The generated images are useful for mood, hierarchy, and broad composition. They contain invented quotes, balances, performance, risk figures, probabilities, and status indicators. Those values are not requirements, fixtures, defaults, or broker evidence.
2. The concept boards mix multiple product areas in single compositions. They must be decomposed into individual screen specifications before implementation.
3. Some concept imagery suggests direct Buy/Sell or Place Order affordances. The production design must insert order review, identity/capability validation, broker-spec validation, RiskEngine authorization, OMS persistence, and broker reconciliation. A button click is not an execution confirmation.
4. The persistent environment label must be textual (DEMO/LIVE) and visible; color alone is insufficient.
5. A stale or disconnected feed must not visually resemble a live feed. Quote age and provenance are first-class UI data.
6. Risk, account identity, pending/unknown orders, and critical alerts must remain visible when workspace panels are hidden or rearranged.
7. Window lifecycle, panel lifecycle, and domain-service lifecycle are separate state machines.
8. The visual system must be measured in tokens and tested in native SwiftUI; generated image pixels are not authoritative measurements.

## Decisions proposed for review
- Adopt the 12 screen contracts and target IA in the blueprint as the screen inventory.
- Adopt a persistent operational strip and shared screen anatomy, subject to shell review.
- Use Compact/Balanced/Spacious density profiles while preserving all safety-critical information.
- Require per-screen Dark, Light, and Arabic RTL review before screen acceptance.
- Use a status taxonomy that distinguishes live, delayed, stale, unavailable, simulated, and historical data.

## Unresolved decisions (do not infer)
- Canonical brand turquoise: Q39.1 `#40E0D0` versus Phase 00/code `#00CEC8`.
- Supported minimum window dimensions and adaptive breakpoints.
- Exact placement of global vs contextual commands.
- Chart rendering technology, licensing, and performance envelope.
- Arabic font, bidi handling, mixed-direction instrument labels, and numeral formatting.
- Detailed LIVE order confirmation and step-up authorization UX.

## Risk register
| Risk | Impact | Mitigation / gate |
|---|---|---|
| Treating concept artwork as a specification | Inconsistent or unsafe UI | Screen contracts, measured tokens, explicit approvals |
| Fabricated sample figures copied into UI | Misrepresentation of financial state | No mock values in production; provenance-bound view models |
| Direct dealing affordance bypasses governance | Unauthorized order path | Intent-only UI API; centralized RiskEngine/OMS/Gateway |
| Status encoded only by color | Accessibility and environment confusion | Text + icon + color + accessible label |
| Panel close stops service unexpectedly | Hidden operational side effects | Separate panel and domain-service lifecycles |
| RTL applied only at string level | Broken financial layouts | Component-level and screen-level RTL QA |
| Scope too broad for one delivery | Integration and quality risk | Screen-by-screen vertical slices and focused PRs |

## Estimate notes
The 81–140 engineer-day total in the blueprint is an initial sequential planning range for UI-focused work, not a delivery promise. Confidence is low for charting, execution, risk, automation, and agent screens until backend/domain contracts and technology choices are inspected. Estimates exclude substantial backend work, broker qualification, production security review, and owner approval latency.

Re-estimation gate: after the shell, Command Center, and Markets have been implemented and measured against the actual repository, Xcode toolchain, and broker data contracts.

## Required review evidence
- Owner approval of the screen inventory and unresolved design decisions.
- Design Authority review of hierarchy, tokens, accessibility, and localization.
- Engineering Authority review of lifecycle, performance, state ownership, and domain boundaries.
- Trading-systems review of order lifecycle, risk visibility, broker provenance, and reconciliation.
- CI results on exact PR head.
- Native macOS build, launch, screenshots, keyboard/VoiceOver, RTL, and multi-display evidence.

## Explicit non-approval
This record does not approve Phase 01, claim all 12 screens are implemented, enable broker dealing, alter risk limits, change credentials, or authorize LIVE trading.
