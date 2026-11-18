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


## Follow-up engineering direction — staged delivery and visual asset governance

### Proposed delivery order (owner/authority review pending)
1. Application Shell + Navigation.
2. Command Center.
3. Markets.
4. Charts & Analysis.
5. Trading + Risk + Positions.
6. Remaining product areas: Intelligence & Research, Strategy Center, Automated Trading, Performance & Analytics, Atheer Mind OS, System & Administration.

This order intentionally establishes shell and read-only market/account context before exposing consequential trading workflows. Trading UI is not to be treated as an early standalone screen; it depends on broker data contracts, order intent, RiskEngine, OMS, execution, and reconciliation readiness.

### Stage-level UI estimates
| Stage | Included work packages | Estimate | Confidence |
|---|---|---:|---|
| 1. Foundation + Shell | design-system audit (3–5) + shell/navigation (5–8) | 8–13 engineer-days | Medium |
| 2. Command Center | account/market/position/service-health read models and screen | 4–6 engineer-days | Medium |
| 3. Markets | instrument explorer, watchlists, quote provenance/freshness | 5–8 engineer-days | Medium |
| 4. Charts & Analysis | chart surface, history/stream integration, indicators/drawings | 8–15 engineer-days | Low |
| 5. Trading + Risk + Positions | governed order UI (8–12) + positions (5–8) + risk (6–10) | 19–30 engineer-days | Low |
| 6. Remaining areas | research (5–9), strategy (6–10), automation (6–10), analytics (5–9), Mind OS (6–10), administration (5–8) | 33–56 engineer-days | Low |
| Cross-cutting QA | visual, accessibility, localization/RTL and multi-display QA | 8–12 engineer-days | Medium |

**Corrected total: 85–140 engineer-days.** The previous 81-day lower bound was an arithmetic aggregation error; the individual work-package minima sum to 85. This corrected figure supersedes the earlier lower bound. The upper bound remains 140. Estimates are one engineer's focused full-time effort and exclude substantial backend/domain work, broker qualification, owner-review latency, release certification, and external dependencies. Calendar duration is not implied.

### High-fidelity design asset policy
- Commit source design assets under `docs/design/assets/<screen-id>/` (or a clearly versioned shared board), using stable names such as `SCR-01-command-center-dark-v1.png`.
- Maintain a manifest with screen ID, design version, viewport dimensions, appearance, density, locale/direction, state represented, source file/editable format, author, review status, and related issue/PR.
- Keep editable source (where available) alongside exported PNG/SVG/PDF; avoid lossy-only delivery for diagrams and vector work.
- One screen per frame/artboard. Do not bundle unrelated screens into one image where screen-specific review is required.
- Required variants per screen: Dark and Light; English LTR and Arabic RTL; Compact/Balanced/Spacious where layout materially changes; key loading, empty, stale/disconnected, error/rejected, and normal states.
- Use synthetic placeholder content only when clearly labelled as illustrative. Never use realistic-looking fabricated balances, quotes, risk values, broker statuses, AI confidence, or execution outcomes without persistent "illustrative" labeling.
- Design images are visual references, not UI implementation, behavior contracts, data fixtures, or approval evidence.
- Do not overwrite approved assets in place. Increment design version and retain review history.
- Each asset must link to its screen contract, component inventory, interaction/state specification, and acceptance checklist.

### Screen approval gate
A screen is not approved by visual appearance alone. Required evidence:
1. Owner-approved screen frame(s) and documented unresolved decisions.
2. Design review of hierarchy, typography, semantic tokens, density, and visual consistency.
3. Engineering review of SwiftUI component ownership, state flow, window/panel lifecycle, performance, and accessibility.
4. Trading-systems review where account, risk, order, position, broker, or agent state is represented.
5. Defined view-model/domain contracts and all material UI states.
6. Dark/Light, RTL, keyboard, VoiceOver, contrast, scaling, and multi-display checks.
7. Implementation with automated tests, exact-head CI, native macOS build/launch evidence, and screenshot comparison.
8. Explicit acceptance record; mockup review does not imply implementation completion or trading authorization.

### Immediate next deliverables
- Repository visual asset manifest and per-screen asset directories.
- Screen 01 Application Shell + Navigation high-fidelity frame and state inventory.
- Screen 02 Command Center high-fidelity frame and state inventory.
- Screen 03 Markets high-fidelity frame and state inventory.
- Re-estimate after the first three vertical slices using actual implementation and integration evidence.

### Approval boundary
This follow-up records the requested engineering direction for review. It does not mark these stages complete, approve all 12 screens, authorize a LIVE trading path, or change `CAP_ALLOW_TRADING=false`.
