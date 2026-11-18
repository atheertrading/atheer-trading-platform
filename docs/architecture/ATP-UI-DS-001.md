# ATP-UI-DS-001 — Premium Professional Trading Workspace Design System

- **Document ID:** ATP-UI-DS-001
- **Version:** 1.0
- **Status:** Owner-directed visual direction; token validation, component implementation, and screen acceptance are pending.
- **Platform:** Native macOS application (SwiftUI); preserve the repository's verified macOS 13 deployment baseline and historical Xcode/Swift compatibility until requalified.
- **Related architecture:** [ATP-UI-ARCH-001 — Presentation Architecture and Backend Decoupling](ATP-UI-ARCH-001.md)

## 1. Design identity

Adopt **Premium Professional Trading Workspace**: a restrained, dark-first, high-precision trading workstation that communicates confidence, clarity, control, and analytical depth.

Premium quality must come from disciplined hierarchy, typography, spacing, alignment, information density, consistency, responsiveness, and interaction craftsmanship—not decorative gradients, excessive blur, ornamental glass, oversized cards, or animation for its own sake.

This is an ATHEER product identity informed by Apple's Human Interface Guidelines. It is not a pixel imitation of Apple's applications. Use native macOS conventions where they improve usability and platform coherence.

## 2. Design principles

1. **Clarity before decoration:** every visual element must support comprehension, orientation, or action.
2. **Information density with order:** professional market workflows need high data density, but grouping, alignment, whitespace, and typography must preserve scanability.
3. **Stable hierarchy:** navigation, screen title, primary task, contextual controls, data surface, and status feedback follow predictable patterns.
4. **Precision:** prices, quantities, timestamps, units, source, and state must be unambiguous.
5. **Calm confidence:** neutral surfaces dominate; accent and semantic colors are purposeful and sparse.
6. **Native behavior:** support macOS focus, keyboard, menus, windowing, resizing, full screen, and accessibility conventions.
7. **User control:** users can shape workspaces without losing predictable defaults or critical safety information.
8. **Truthful states:** missing, stale, partial, delayed, or unavailable data is explicit; no fabricated production data.
9. **Safe action design:** destructive or financial actions are clearly distinguished, reviewed, and confirmed according to the governed workflow.
10. **Consistency without uniformity:** shared tokens/components create coherence while each workflow keeps task-appropriate composition.

## 3. Brand palette and semantic tokens

The following values preserve the existing owner-provided palette already represented in the repository's `ATHEERDesignTokens`. They are initial brand primitives, not yet a fully contrast-qualified semantic theme.

| Primitive | Value | Intended use |
|---|---|---|
| Deep canvas | `#121212` | Primary dark workspace background |
| Deep teal | `#093732` | Brand/depth surface, sparingly |
| Navy | `#001F3F` | Secondary depth/selected context |
| Teal | `#008080` | Secondary accent |
| Bright teal | `#00CEC8` | Focus/active accent, sparingly |
| Gold | `#FFD700` | Limited attention/highlight only |
| Danger red | `#D32F2F` | Critical/danger semantic |
| Success green | `#00C853` | Success semantic |

### 3.1 Semantic roles required

Do not let screens reference raw palette values directly. Define semantic roles, including:
- Background: canvas, workspace, surface, elevated surface, inset surface.
- Foreground: primary, secondary, tertiary, disabled, inverse.
- Structure: separator, subtle border, strong border, focus ring.
- Interaction: accent, accent-foreground, hover, selected, pressed, disabled.
- Status: neutral, information, success, warning, danger, critical.
- Trading: positive movement, negative movement, unchanged, bid, ask, stale, delayed, rejected, pending, confirmed.

Semantic colors must be accompanied by text, symbols, labels, or shape/state differences. Never encode a financial or operational state by color alone.

### 3.2 Contrast and appearance qualification

- Validate text and meaningful UI graphics against WCAG 2.2 AA contrast targets as the project accessibility baseline; this is a project acceptance target, not a claim that WCAG replaces Apple HIG.
- Normal text target: at least 4.5:1; large text target: at least 3:1; meaningful non-text controls/indicators target: at least 3:1 against adjacent colors.
- Validate every semantic foreground/background pairing, disabled-state legibility, focus visibility, selected state, and chart/table status cue.
- Support the approved dark-first experience and verify system appearance behavior. Do not claim full light-mode support until it is designed and tested.
- Preserve native system contrast and accessibility settings where possible; avoid hard-coded low-opacity text that becomes unreadable.

The listed palette has not yet been contrast-qualified. If a brand primitive fails a required pairing, adjust the semantic foreground/surface pairing rather than forcing the raw primitive into every role.

## 4. Typography and numeric presentation

- Prefer the macOS system font family and platform text styles where appropriate.
- Establish a limited type scale for brand, screen title, section/panel title, body, secondary, caption, and compact metadata.
- Use monospaced digits for aligned prices, quantities, rates, timestamps, identifiers, and tabular market values where it improves comparison.
- Use tabular number alignment in dense tables.
- Avoid ultra-light weights, tiny captions, excessive tracking, and all-caps labels as the primary reading style.
- Respect Dynamic Type/accessibility text scaling where supported by the macOS implementation; layouts must adapt rather than clip essential information.
- Formatting must preserve precision, sign, currency, unit, and locale semantics. Never round financial values silently for visual convenience.

## 5. Layout, spacing, and surfaces

Define shared tokens for:
- Spacing scale and content insets.
- Control heights and hit areas.
- Sidebar, toolbar, panel, table-row, and chart-container dimensions.
- Corner radii, border widths, separators, and elevation.
- Minimum/ideal widths and responsive breakpoints for screen compositions.

Rules:
- Prefer alignment and grouping over boxes around every element.
- Use cards/panels only when they represent a meaningful independent work surface or grouping.
- Keep primary content dominant and preserve chart plotting area.
- Support compact and expanded density modes only where both remain legible and useful.
- At narrower window sizes, reflow or provide deliberate scrolling/overflow behavior; never compress critical values into illegibility.
- Keep toolbar and panel controls discoverable without competing with primary data.
- Use whitespace to separate task groups, not to waste the limited space of a trading workspace.

### 5.1 Materials and effects

Use native materials only where they clarify hierarchy or support a functional layer such as navigation, toolbar, or transient overlay. Do not apply blur/material effects indiscriminately to chart canvases, dense tables, order forms, or every panel. Any use of Liquid Glass must be validated against the target macOS version and supported APIs; the macOS 13 compatibility floor takes precedence over adopting newer visual APIs.

Motion should be short, purposeful, interruptible, and non-blocking. Never delay a market update, risk warning, order review, or time-critical action for decorative animation.

## 6. Application shell and navigation

Use a stable application shell with:
- Sidebar/navigation for primary destinations and workspace selection.
- Contextual toolbar for screen-level actions and view configuration.
- Main content area for the task-specific workspace.
- Optional inspector/detail surface where context warrants it.
- Subtle status/connection/freshness feedback that remains discoverable.

The product information architecture includes Dashboard/Command Center, Markets, Charts & Analysis, Trading, Positions, Orders, Strategies, Portfolio, Risk, Analytics, AI Intelligence, Activity, and Settings. Treat this as target product IA; do not imply every destination is implemented.

Navigation must communicate current location, hierarchy, selection, and available actions. Avoid deep navigation for frequent trading tasks. Keep settings and account/environment configuration distinct from operational trading surfaces.

## 7. Screen composition standards

Screens are task-oriented workspaces, not generic dashboard templates.

### Command Center
- Prioritize operational awareness: connection/market status, watchlist context, active positions/orders, risk state, and actionable exceptions as those capabilities become available.
- Use compact summaries only when the underlying source and update time are clear.
- Avoid presenting unavailable capabilities as zero or healthy.

### Market Explorer
- Optimize symbol discovery, search, watchlist management, quote comparison, source/environment, and freshness.
- Keep numeric columns aligned and units explicit.
- Distinguish no results, no connection, permission, stale quote, and request failure.

### Chart Workspace
- Preserve plot area, price scale, time axis, and candle readability.
- Controls must expose instrument, timeframe, price side, and data source/environment clearly.
- Bid and Ask series remain distinct; never imply synthetic Mid data.
- Data-quality and freshness information must be accessible without overwhelming the chart.
- Overlays, drawing tools, and inspectors must not obscure critical price action.

### Trading and order workflows
- Separate order composition, review, authorization outcome, submission, broker acknowledgement, and final reconciliation states.
- Visually distinguish DEMO/SIM/BACKTEST/LIVE at the point of action.
- Show order side, instrument, size, order type, price constraints, estimated impact/requirements, and risk result where applicable.
- Make disabled/rejected/pending states explicit and explain the semantic reason.
- Confirmation UI never replaces server-side authorization, risk checks, idempotency, or broker reconciliation.

### Positions, Orders, Portfolio, and Risk
- Distinguish broker-confirmed values from local calculations and estimates.
- Show currency, units, timestamps, source, and relevant freshness.
- Make realized/unrealized values and account-level versus position-level risk unambiguous.
- Do not present stale or unavailable values as current.

### AI Intelligence
- Separate analysis/recommendation from authorized actions.
- Show agent identity/capability context, evidence/provenance, confidence or uncertainty where defined, and action status.
- Any financial intent remains subject to the same central authorization, RiskEngine, OMS, and Execution Gateway path.

## 8. Component standards

Build a small, coherent SwiftUI component library around demonstrated reuse and stable semantics.

Expected patterns (not a mandate to create every component immediately):
- Application sidebar and navigation row.
- Screen header and contextual toolbar.
- Workspace panel/container and panel header.
- Market-data status/source/freshness indicator.
- Numeric/financial value presentation.
- Dense data table row/header/selection patterns.
- Chart container, chart controls, and chart quality footer.
- Form field, validation message, and grouped settings row.
- Empty/loading/stale/unavailable/error state surfaces.
- Confirmation/review surface for consequential actions.

Every component must define:
- Purpose and semantic contract.
- Supported variants and size/density behavior.
- Inputs/actions and ownership of state.
- Default, hover, focus, pressed, selected, disabled, loading, and error states as applicable.
- Accessibility label, value, hint, and keyboard behavior where applicable.
- Layout behavior at minimum supported window sizes.

Components must remain presentation-only and backend-independent. They accept semantic values and explicit callbacks; they do not receive API DTOs, network clients, broker services, or risk engines.

## 9. Interaction and accessibility

Accessibility is a release requirement, not a polish phase.

- Full keyboard navigation for primary workflows; visible and logical focus order.
- VoiceOver labels, values, hints, grouping, and meaningful reading order.
- Focus indicators that remain visible against all supported surfaces.
- Do not rely on hover as the only way to reveal an action.
- Do not rely on color alone for status, direction, selection, or risk.
- Controls must have usable hit targets and clear disabled explanations.
- Support reduced motion and avoid flashing or rapid animated updates.
- Provide confirmation and undo/recovery where appropriate; irreversible financial actions must use the governed order workflow.
- Ensure table and chart information has accessible summaries or alternative access paths where practical.
- Test keyboard-only operation, VoiceOver, contrast, text scaling, and window resizing.

## 10. Workspace behavior

- Support resizable windows and panels, full-screen use, and multi-display arrangements where the underlying workspace implementation allows it.
- Panel add/remove/reorder/hide/show actions must be explicit and reversible where possible.
- Persist user layout preferences only through a defined workspace persistence contract; do not bind layout persistence to broker/backend schemas.
- Provide sensible defaults and a restore-layout action.
- Keep window-level controls distinct from panel-level controls.
- Preserve minimum usable dimensions and define graceful behavior when panels cannot fit.

## 11. SwiftUI implementation rules

- Keep design tokens centralized and semantic; avoid per-screen raw hex values and duplicated magic spacing.
- Prefer small composable views with clear ownership of state.
- Use environment/theme injection for visual configuration where justified; avoid global mutable theme state.
- Keep view bodies declarative and free of networking, financial calculations, and business authorization.
- Keep reusable components independent of application services.
- Use APIs compatible with the verified deployment target and compiler. Newer Apple APIs require availability checks and an explicit compatibility decision.
- Add accessibility identifiers for stable automated UI tests where needed.
- Do not introduce a dependency or a universal design framework without a demonstrated requirement.

## 12. Visual and UX acceptance checklist for Pull Requests

- [ ] Follows Premium Professional Trading Workspace identity and semantic hierarchy.
- [ ] Uses approved tokens; no unexplained raw colors, typography, spacing, or corner-radius values.
- [ ] Remains readable at the minimum supported window size and at realistic large-screen layouts.
- [ ] Resizes/reflows without clipping, overlapping, or hiding critical market/trading information.
- [ ] Provides coherent empty, loading, stale, partial, unavailable, error, selected, disabled, and focus states as applicable.
- [ ] Shows source, environment, timestamp, units, and freshness where needed to interpret financial data.
- [ ] Does not use color as the sole status/direction indicator.
- [ ] Preserves chart/table readability and numeric alignment.
- [ ] Supports keyboard navigation and VoiceOver for changed workflows.
- [ ] Meets contrast targets for text and meaningful controls/indicators.
- [ ] Uses motion/materials purposefully and compatibly with the deployment target.
- [ ] Preserves DEMO/SIM/BACKTEST/LIVE separation and all trading safety controls.
- [ ] Keeps UI components independent of backend DTOs and services.
- [ ] Includes screenshots or reproducible visual QA evidence for material screen changes.

A PR must record the tested macOS version, window size(s), appearance, relevant interaction paths, accessibility checks, and screenshots or equivalent evidence. Compilation alone is not visual acceptance.

## 13. Design governance and change control

- These documents define the owner-directed design direction and engineering acceptance baseline. They do not assert that all current screens comply.
- Token values and components may evolve through focused PRs with before/after evidence, accessibility validation, and migration notes.
- Brand primitive changes require a rationale and impact review across all semantic roles.
- A screen-specific exception must be documented and justified by workflow needs.
- Do not silently introduce a new visual language or bypass shared tokens.
- Keep design decisions traceable and reconcile them with the existing IPDS specification and Library sources before declaring IPDS v1.0 formally approved.

## 14. Apple and accessibility references

Use current official documentation and verify API availability against the project's deployment target:
- [Apple Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/)
- [Designing for macOS](https://developer.apple.com/design/human-interface-guidelines/designing-for-macos)
- [Layout](https://developer.apple.com/design/human-interface-guidelines/layout)
- [Typography](https://developer.apple.com/design/human-interface-guidelines/typography)
- [Materials](https://developer.apple.com/design/human-interface-guidelines/materials)
- [Accessibility](https://developer.apple.com/design/human-interface-guidelines/accessibility)
- [Apple Developer Documentation](https://developer.apple.com/documentation/)
- [WCAG 2.2](https://www.w3.org/TR/WCAG22/)

Apple's guidance evolves. Review the live HIG and platform release notes during design review rather than treating a dated screenshot or a single material style as a permanent 2026 mandate.
