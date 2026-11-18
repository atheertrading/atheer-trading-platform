---
document_id: ATP-IPDS-001
title: "ATHEER Trading Pro — Institutional Precision Design System"
version: 0.1.0
status: "Engineering foundation proposal — Phase 00 final approval pending"
owner: Project Owner
accountable_role: Head of Engineering
classification: Product Design and Engineering Baseline
source_authority: Owner Q&A archive; Phase 00 v1.1 decisions; repository implementation
implementation_status: "Initial appearance and semantic-token slice in this branch; full IPDS is not implemented"
---

## ATHEER Trading Pro — Institutional Precision Design System (IPDS)

**Design direction:** Clarity Under Pressure  
**Brand line:** Intelligence in Motion. Precision in Execution.

## 1. Purpose and product promise

ATHEER Trading Pro is conceived as a professional trading operating environment, not a collection of disconnected market screens. It brings market intelligence, analysis, strategy operation, governed execution, position management, risk supervision, quantitative evaluation, and AI-assisted decision support into one coherent workstation.

The design must help an experienced trader answer five questions without ambiguity:

1. What is happening in the market?
2. What is the verified state of my account, orders, positions, and exposure?
3. What is the system proposing, and why?
4. What is authorized, blocked, pending, or still unknown?
5. What requires my attention or intervention now?

The governing principle is **clarity over decoration, precision over visual noise, and information over ornamentation**. Visual polish must never conceal missing data, uncertain execution, a failed connection, or an authorization boundary.

### 1.1 Design pillars

| Pillar | Product expression |
|---|---|
| Professional authority | Restrained institutional visual language, native macOS behavior, coherent terminology |
| Analytical clarity | Stable hierarchies, readable financial data, deliberate density, precise chart semantics |
| Technological intelligence | Contextual intelligence, explainable analytical state, observable system health |
| Operational precision | Explicit lifecycle states, accurate provenance, predictable interactions |
| Capital protection | Risk visibility, deliberate confirmations, no false success states, governed actions |

### 1.2 Experience model

The primary trader journey is:

**Market Intelligence → Analysis → Strategy → Authorization → Execution → Position Management → Risk Control → Performance Evaluation.**

This is a product-level mental model. It does not collapse independent domain services or grant UI components authority over those services.

## 2. Source authority and decision status

This document consolidates design direction from the owner-provided Q&A archive, the Master Visual Design / UI:UX Engineering Specification, Phase 00 v1.1, the recovered historical Mermaid export, current GitHub implementation, and the owner-directed UI/UX engineering directive in PR #13.

The following distinctions are mandatory:

- **Owner-approved decisions:** D-001 dark-first appearance; D-002 adaptive information density; D-003 English and Arabic with full RTL support.
- **Owner-provided design direction:** IPDS v1.0 visual identity, the brand line, institutional restraint, 12 task-oriented navigation groups, and modular workspaces.
- **Implementation evidence:** the current SwiftUI token file, app shell, Command Center, Workspace Engine, panel manager, Markets screen, and Settings screen on the repository main branch.
- **Proposal in this document:** semantic token taxonomy, light-theme values, density behavior details, information architecture mapping, component contracts, and the initial appearance-settings slice.
- **Unresolved approval:** the complete Phase 00 baseline, Design Authority review, Engineering Authority review, and the final exact turquoise brand token remain open.

Phase 00 explicitly states that Phase 01 must not formally begin until the final baseline approval and Design/Engineering reviews are recorded. This document is therefore an implementation foundation and proposal; it does not declare Phase 00 closed or Phase 01 approved.

## 3. Brand and visual language

### 3.1 Identity

The product identity is **ATHEER Trading Pro** with the brand line **Intelligence in Motion. Precision in Execution.**

The interface should feel calm, exact, technically sophisticated, and immediately legible during sustained trading sessions. Branding is strong in the application shell and restrained inside working surfaces. Do not imitate a retail brokerage, a gaming interface, a generic AI dashboard, or a wall of decorative analytics cards.

### 3.2 Palette and provenance

The owner Q&A identity record specifies Graphite Black (#121212), Deep Teal (#093732), Midnight Navy (#001F3F), Teal (#008080), Turquoise (#40E0D0), Gold (#FFD700), Slate Blue (#384959), Muted Teal (#3C635F), and Soft Turquoise (#81D8D0). It also defines positive trading green (#00C853) and negative trading red (#D32F2F).

A source discrepancy must remain visible:

- Q39.1 specifies the brand turquoise as #40E0D0.
- Phase 00 v1.1 and the current repository token use #00CEC8.
- The existing code value is preserved in this increment to avoid silently changing the current implementation.
- The canonical IPDS brand-turquoise value requires formal reconciliation and visual/contrast review; this document does not silently select a winner.

### 3.3 Semantic token model

Raw palette values must not be assigned directly by feature screens. The design system exposes semantic roles:

| Semantic role | Meaning | Constraint |
|---|---|---|
| Canvas | Main application background | Dark graphite by default; light neutral surface in light appearance |
| Navigation | Primary navigation surface | Deep-teal identity without competing with content |
| Panel | Standard workspace surface | Clear separation with restrained borders |
| Elevated panel | Focused or raised content | Used sparingly, not as a default card treatment |
| Primary text | Main labels and values | High contrast in both themes |
| Secondary text | Supporting metadata | Remains readable; not used for critical instructions |
| Accent | Selected, active, or primary interactive emphasis | Not a profit/loss or buy/sell signal |
| Positive | Positive P&L / bullish movement | Always accompanied by sign, label, or numeric context |
| Negative | Negative P&L / bearish movement | Always accompanied by sign, label, or numeric context |
| Attention | Warning, important event, degraded state | Must state the condition in text |
| Neutral | Disabled, unknown, secondary, or informational state | Must not imply a successful connection |
| Separator | Structural boundary | Subtle but visible in both themes |

Profit/loss, market direction, connection state, selected navigation, and command emphasis are separate semantic concepts. Do not reuse one accent color for all of them. Buy and Sell actions require distinct, unmistakable action treatments and must not be confused with P&L colors; their final component colors require a dedicated trading-control specification.

### 3.4 Theme direction

Dark is the default appearance. Light is a complete supported appearance, not an inverted dark palette. Theme preference is presentation state and must not alter market-data processing, strategy configuration, risk policy, broker connectivity, or execution state.

This branch introduces the initial dark/light semantic surface mapping and persisted appearance selection. The complete IPDS still requires contrast measurements, chart theme mappings, component-state review, screenshot regression, and owner-workstation inspection.

## 4. Typography, numbers, and information density

### 4.1 Typography

Use the native macOS system type family for the main interface, with the platform's San Francisco family for display and text roles. Use a monospaced system face for prices, quantities, balances, P&L, timestamps, IDs, and diagnostics.

Typography must distinguish:

- Screen title and section heading.
- Panel title and compact label.
- Main body and supporting explanation.
- Financial value and instrument metadata.
- State label, timestamp, and diagnostic detail.

Financial values should use monospaced/tabular digit presentation, explicit units, currency and sign, and instrument-specific precision from the authoritative instrument specification. Never round or pad prices to a generic platform-wide decimal count.

### 4.2 Adaptive information density

D-002 establishes adaptive information density. The UI should adapt to available workspace dimensions and user preference while preserving critical information. It must not simply shrink text or hide important fields.

The balanced presentation is the proposed default. Compact and spacious presentation profiles may be added as explicit user preferences after component and screen-level validation. The exact profile metrics remain open.

Critical order, position, risk, environment, broker, and market-data states must remain discoverable when panels are hidden, collapsed, moved, or when the window is resized.

### 4.3 Financial data behavior

- Keep the geometry of frequently updating figures stable to avoid layout jitter.
- Display source, instrument identity, environment, provider/event timestamp, receipt timestamp, and freshness/quality where applicable.
- Distinguish zero from unavailable, delayed, stale, disconnected, unsupported, and not-yet-loaded.
- Preserve provider precision and source lineage; never interpolate missing market data for visual continuity.
- Use text and symbols in addition to color for important states.

## 5. Global application information architecture

The owner Q38.1 answer defines a 12-group, task-oriented navigation model. It is the target product information architecture, not a claim that all destinations exist in the current code.

| Group | Primary responsibility |
|---|---|
| Command Center | Operational overview, market/account context, exposure, active positions, alerts, platform health |
| Markets | Instrument discovery, watchlists, market movers, specifications, session and feed status |
| Charts & Analysis | Multi-timeframe charts, indicators, drawings, price action, market structure |
| Intelligence & Research | News, calendar, fundamental, sentiment, volatility, liquidity, event impact |
| Strategy Center | Strategy library, builder, configuration, conditions, compatibility, versions |
| Automated Trading | Strategy supervision, allocations, schedules, permissions, execution monitoring |
| Trading & Execution | Manual order entry, OMS, open orders, history, execution reports, broker status |
| Positions & Portfolio | Position lifecycle, P&L, protection, partial close, exposure, portfolio view |
| Risk Management | Limits, drawdown, margin, exposure, authorization, protection, emergency controls |
| Performance & Analytics | Equity curve, attribution, win/loss, profit factor, risk-adjusted diagnostics, journal |
| Atheer Mind OS | AI agents, skills, decision support, evidence, provider/model operations |
| System & Administration | Broker setup, environments, integrations, preferences, permissions, audit, diagnostics |

Navigation hierarchy:

1. Primary sidebar: the 12 high-level task groups.
2. Contextual navigation: subsections within the active group.
3. Workspace tabs: concurrent work contexts and saved arrangements.
4. Global command/search: instruments, functions, strategies, positions, and supported actions.

The current main-branch app exposes only Workspace, Markets, API Connection, and Settings. The remaining groups are product scope and must be implemented through bounded screen increments, not represented by empty navigation destinations.

### 5.1 Persistent operational command region

The application shell should provide persistent, source-grounded access to:

- Active account and broker identity.
- Authenticated environment (DEMO, SIMULATION, BACKTEST, or LIVE).
- Broker-reported account facts when an authoritative snapshot exists.
- Separate broker-session and market-data-feed status.
- Critical alerts and unresolved events.
- Universal command search.
- Quick Trade entry only when the required order-intake, identity, risk, and execution contracts are implemented and available.

The environment must remain unmistakable and cannot be hidden by workspace customization. A user-selectable label alone must not create a broker environment or imply authentication.

## 6. Workspace, panel, and window architecture

### 6.1 Workspace model

Workspaces are task-oriented arrangements, not independent trading engines. The owner Q&A proposes standard starting workspaces for Trading, Market Analysis, Automation, Portfolio, Research, and Risk, with custom workspace support.

Each workspace has:
- A stable identity and display name.
- A versioned layout snapshot.
- A collection of panel instances with visibility, order, region, and supported size constraints.
- A selected instrument/context only where the feature contract supports it.
- A controlled persistence and recovery policy.

Workspace changes must never mutate strategy configuration, broker state, risk policy, open positions, or service lifecycle.

### 6.2 Panel and element lifecycle

The Element Management System should support Add, Remove, Configure, Resize, Rearrange, Duplicate, Pin, Favorite, Hide, Restore, and Share for approved element types.

**Removing a panel removes its presentation instance only.** It must not delete underlying data, cancel an order, stop a strategy, disconnect a broker, disable risk monitoring, or terminate a background service.

Elements should declare identity, version, purpose, data dependencies, permissions, state, resource constraints, and supported integration level:
- Visual-only presentation.
- Independent functional tool.
- Integrated service interaction through explicit versioned contracts and permissions.

External elements must be provided through controlled adapters. Arbitrary scripts in a workspace must not bypass application security or execution authority.

### 6.3 Window independence

Workspace layout and native macOS window management are different systems:

- Workspace management owns panel membership, order, visibility, and internal layout.
- Window management owns native window geometry, display placement, full-screen/minimize/restore behavior, and multi-monitor recovery.

Closing or resizing a window must not stop associated services or change trading state. A disconnected display must not leave a critical window inaccessible; saved arrangements must recover onto an available display. Implement this through native macOS window APIs where supported.

The current Workspace Engine already provides versioned workspace/profile persistence, panel visibility/add/remove/order, sidebar sizing, validation, and recovery. Interactive drag-and-drop, docking, panel-specific flexible resizing, full native multi-window orchestration, and multi-monitor restoration remain incomplete.

## 7. Component and interaction contracts

### 7.1 Standard component families

The IPDS component library should progressively cover:

- Application shell, navigation items, command bar, environment badge.
- Workspace tabs, panel shell, panel toolbar, panel manager.
- Data table, watchlist row, quote cell, instrument identity, price/quantity field.
- Chart toolbar, chart surface, indicator legend, drawing toolbar, order/position overlay.
- Order ticket, order preview, risk assessment summary, OMS state timeline.
- Position row, exposure summary, protection controls.
- Alert, notification, connection state, service-health panel.
- Settings section navigation, appearance selector, broker connection and credential controls.
- Dialog, confirmation, popover, context menu, empty/loading/error/unavailable states.

Each component requires documented inputs, state ownership, semantic variants, keyboard/focus behavior, accessibility labels, minimum dimensions, empty/degraded states, and tests or visual verification.

### 7.2 Interaction semantics

These are distinct actions and must not be conflated:

| Action | Effect |
|---|---|
| Open / Close Settings | Window lifecycle only |
| Show / Hide Panel | Presentation visibility only |
| Expand / Collapse | Local information density or layout |
| Add / Remove Panel | Workspace composition only |
| Connect / Disconnect | Broker/service connection lifecycle |
| Start / Stop Strategy | Governed strategy lifecycle; not position closure |
| Enable / Disable Trading | Protected capability governed by authorization; never a cosmetic toggle |
| Submit Order | Create/submit an immutable intent through the approved domain path |

Settings close must not silently revert changes, disconnect a broker, stop a strategy, or change trading permissions. The persistence policy for each settings category must be explicit: immediate-save, staged Apply/Cancel, or separately confirmed.

### 7.3 UI state vocabulary

Use explicit state labels and presentations for at least:

- Loading.
- Available / live.
- Delayed.
- Stale.
- Disconnected.
- Not configured.
- Not authenticated.
- Unsupported.
- Unavailable.
- Invalid response.
- Error.
- Restricted / disabled.
- Pending / reconciling.
- Unknown outcome.

An unknown outcome must remain unknown until authoritative reconciliation resolves it. Never render broker acknowledgment as a confirmed fill.

## 8. Trading, AI, and safety presentation

The UI is not the authorization boundary.

The required command flow is:

**User / Strategy / Agent → Immutable Order Intent → Identity and Permission Validation → Domain Validation → Central RiskEngine → OMS → Execution Gateway → Broker → Broker Observation → Reconciliation → Confirmed UI State and Audit.**

Manual, automated, and AI-originated requests converge on the same governed path. UI controls must not call broker dealing endpoints directly.

The interface must:
- Show the exact intent, account, environment, instrument, side, quantity, order type, protection, and relevant risk assessment before a protected submission.
- Show authorization separately from persisted OMS state, gateway dispatch, broker acknowledgement, execution fill, and reconciliation.
- Prevent blind retry after timeout or uncertain submission; reconcile first.
- Keep AI analysis and proposals visually distinct from broker-confirmed facts and authorized commands.
- Show permission and autonomy as separate dimensions.
- Preserve manual overrides against conflicting strategy/AI management actions according to the authoritative management policy.
- Make strategy stop, new-entry halt, exposure restriction, position transfer, and emergency recovery distinct workflows.
- Expose critical risk and system states outside any optional or hideable panel.

DEMO, SIMULATION, BACKTEST, and LIVE must be separate in account context, styling, persistence, reporting, and execution capability. LIVE activation requires its independent owner approval and verified operational gates; this design work does not enable it.

## 9. Charting and market visualization

Charts are operational analytical instruments, not decoration. The target chart surface includes:
- Accurate time and price scales.
- Provider-grounded OHLC candles with explicit Bid/Ask lineage where applicable.
- Instrument-native precision and supported timeframe metadata.
- Clear candle direction and non-color-only cues.
- Multi-timeframe context, synchronized charts, zoom/pan, future space.
- Indicators and drawing/annotation tools with explicit parameter/state ownership.
- Entry, stop-loss, take-profit, average position price, and exposure overlays where backed by authoritative data.
- Distinct historical, replay, simulation, and live-updating candle states.
- Explicit handling of missing intervals; no synthetic gap filling or invented volume.

Live quote ingestion must remain independent from rendering cadence. UI snapshot coalescing may reduce redraw frequency only after every validated event has been ingested by the responsible aggregation service.

## 10. Localization and accessibility

D-003 requires English and Arabic, with full RTL support.

RTL is an architectural behavior, not a late translation pass:
- Mirror navigation and directional layout where semantically appropriate.
- Do not blindly mirror chart axes, price movement, instrument symbols, order-side semantics, or technical controls.
- Isolate Latin symbols, EPICs, UUIDs, broker identifiers, numeric sequences, and timestamps inside mixed-direction text.
- Apply locale-aware text, date, decimal, currency, and time formatting while preserving provider precision and market conventions.
- Test table alignment, keyboard order, menu anchoring, focus traversal, VoiceOver labels, and chart annotations in both directions.

Accessibility baseline:
- Target WCAG 2.2 AA contrast and interaction principles where applicable to the native product; confirm platform-specific acceptance using macOS accessibility APIs and native conventions.
- Never communicate a critical state by color or sound alone.
- Provide visible keyboard focus, predictable tab order, clear labels, accessible data tables, VoiceOver announcements, reduced-motion support, and meaningful touch/hover-independent actions.
- Keep compact data readable at supported window sizes; do not make critical controls inaccessible through adaptive density.

## 11. Motion and visual restraint

Motion should communicate state transition, continuity, or focus—not entertainment. Avoid flashing quote cells, sweeping gradients, ornamental transitions, unnecessary blur, excessive glass surfaces, and layout shifts. Update prices without moving column geometry. Critical alerts persist according to severity and explicit acknowledgement rules.

## 12. Implementation foundation delivered by this increment

The code portion accompanying this specification is deliberately bounded:

1. Keep the dark appearance as the persisted first-run default.
2. Add a user-selectable Light appearance in Settings.
3. Map semantic surfaces, text, accents, and status colors to dark/light appearances.
4. Preserve existing token names used by current views to avoid an unrelated UI rewrite.
5. Add deterministic tests for preference resolution and the default-to-dark fallback.

This is an IPDS foundation, not the complete IPDS or an acceptance claim for the full application. It does not add missing product screens, RTL localization, trading controls, broker-session bridging, risk authorization, OMS dispatch, or LIVE behavior.

## 13. Quality and acceptance gates

A component or screen is not accepted until the applicable items are evidenced:

| Gate | Required evidence |
|---|---|
| Design consistency | Uses semantic IPDS tokens and approved component contracts |
| Functional correctness | Every visible interactive control performs its stated action |
| Data integrity | No fabricated broker/account/order/position/market facts |
| State clarity | Loading, empty, unavailable, stale, disconnected, unknown, and error states are distinct |
| Theme | Dark-first default; light appearance tested without clipping or contrast regression |
| Layout | Representative narrow, standard, wide, and multi-display arrangements verified |
| Accessibility | Keyboard, focus, VoiceOver, contrast, non-color cues, RTL |
| Architecture | UI does not own broker or trading-domain authority |
| Regression | Debug, XCTest, Release and supported x86_64/arm64 CI at the exact head |
| Runtime | Owner-workstation launch, interaction, Keychain, and provider checks recorded separately |

Never mark a gate passed merely because the source file exists or a hosted compile succeeds. A local visual inspection is still required for owner-machine acceptance.

## 14. Source traceability and outstanding decisions

Primary source families reviewed:
- Q&A Section 38, especially Q38.1 (navigation and global command region).
- Q&A Section 39, Q39.1 (identity and visual palette), Q39.2 (sidebar customization and widget rearrangement), Q39.4 (window management), and Q39.5 (element management).
- Master Visual Design, UI:UX Architecture & Engineering Specification.
- Phase 00 Discovery and Baseline v1.1 and its D-001/D-002/D-003 decision record.
- Historical Mermaid source export, especially ATP-ARCH-037, ATP-ARCH-038, ATP-ARCH-040 and Q&A flows Q11, Q13, Q26.14, Q26.15.
- Repository AGENTS.md, current implementation and continuity/task records.
- ATP-UX-001 in PR #13, which supplements and does not replace formal Library specifications.

Outstanding:
1. Resolve #40E0D0 versus #00CEC8 as the canonical brand turquoise and update the token contract after approval.
2. Record final Phase 00 owner approval plus Design Authority and Engineering Authority reviews.
3. Reconcile original ATP-ARCH-014, ATP-ARCH-037, ATP-ARCH-038 and the formal IPDS source documents at clause level.
4. Define final screen inventory and workspace mapping in the approved information architecture.
5. Specify settings persistence by category, density profile metrics, panel resize/docking behavior, and window-restoration policy.
6. Qualify dark/light contrast, RTL, VoiceOver, keyboard, screenshot regression and multi-display behavior on the supported Mac toolchain.

**Status:** Proposed IPDS engineering foundation; not final design approval and not evidence of a trading-ready application.
