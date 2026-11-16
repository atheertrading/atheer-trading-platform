# ATP-UX-001 — ChatGPT UI/UX and SwiftUI Engineering Directive

**Document type:** AI-facing product and engineering directive  
**Status:** Owner-directed baseline; detailed reconciliation with the formal Library design/architecture sources remains required  
**Applies to:** ATHEER Trading Pro macOS workstation and any future compatible client  
**Implementation status:** Specification only. This document does not claim that the design system, screens, or interactions described here are implemented.

## 1. Purpose and controlling rule

This directive governs how ChatGPT and other AI-assisted contributors discover, specify, design, implement, review, and modify the ATHEER Trading Pro user interface.

**Do not invent the product's visual language, screen composition, navigation, component behavior, or interaction semantics from personal model preference.** Work from the owner's explicit requirements, the current approved design/architecture sources, this directive, the existing repository implementation, and verified platform constraints.

A visually attractive mock-up is not an implementation specification. A generated SwiftUI screen is not accepted merely because it compiles. The delivered interface must be coherent with the product-wide design system, functionally correct, accessible, maintainable, and verified in the running macOS application.

If a required decision is not specified by an authoritative source:
1. Inspect the relevant Library documents, repository specifications, existing components, and current implementation.
2. Record the missing decision and any conflicting evidence.
3. Recommend a bounded option with rationale and trade-offs.
4. Ask the owner only when the decision materially affects product identity, user workflow, persistence, security, financial risk, or another owner-reserved boundary.
5. Do not silently turn an assumption into an approved design rule.

## 2. Authority and source reconciliation

Apply the project authority model in root `AGENTS.md`. In particular:
- Owner instructions and explicit approvals govern scope and authorization.
- Approved Library specifications and standards govern intended architecture and product behavior.
- GitHub `main`, accepted pull requests, and verified source govern committed implementation.
- Historical conversations provide context and rationale, not proof of current implementation or approval.

Before substantial UI/UX work, inspect:
- `AGENTS.md` and `docs/architecture/AI_AGENT_NAVIGATION.md`.
- Current continuity, task, implementation, and decision records.
- The current app source tree, project configuration, tests, and relevant PRs.
- Formal design sources, especially ATP-ARCH-014 (application architecture and professional UX/UI), ATP-ARCH-037 (configuration/settings governance), ATP-ARCH-038 (workspace and human interaction governance), and the original IPDS / visual design documents.
- Existing tokens, components, screen specifications, interaction contracts, and accessibility requirements.

The repository's document registry identifies these source families, but registry presence does not mean their full text, approval status, or current revision has been reconciled. Verify exact source contents and approval metadata before claiming conformance. Record unresolved conflicts in the established conflict register. This directive supplements, and does not silently supersede, approved formal architecture or design specifications.

## 3. Product design direction

The intended experience is a **professional institutional trading workstation**, combining:

- Institutional precision and information integrity.
- Native macOS quality, clarity, responsiveness, and interaction conventions.
- A modular, configurable trading workspace.
- An operational intelligence environment for market, strategy, AI, and risk context.
- A calm visual hierarchy that supports sustained attention and rapid interpretation.

Do not turn the product into a generic crypto dashboard, a decorative analytics wall, or a dense terminal imitation. Avoid visual noise, unnecessary borders, excessive cards, arbitrary gradients, gratuitous animation, inconsistent iconography, and competing accent colors.

The interface must be comfortable to read for extended sessions. Use deliberate hierarchy, whitespace, alignment, restrained color, typography, and predictable interaction. Information density is a product decision: optimize for decision quality and task completion, not for the maximum number of widgets visible at once.

### 3.1 Progressive disclosure

Show the information needed for the user's current task first. Reveal secondary detail through deliberate navigation, disclosure, inspector areas, popovers, or detail views.

Progressive disclosure must never hide information that is critical to:
- Order authorization or execution state.
- Position exposure, P&L, margin, or account state.
- Risk limits, risk rejections, warnings, or system lockouts.
- Data freshness, broker connectivity, or operational health.
- The distinction between DEMO, SIMULATION, BACKTEST, and LIVE.

Do not collapse critical safety information into subtle tooltips or color alone.

### 3.2 Workspace model

Use coherent, task-oriented workspaces rather than placing every feature on one screen. Workspace examples may include Trading, Markets, Charts, Positions, Orders, Strategies, Risk, AI Intelligence, Analytics, and System Monitoring. These are product-domain groupings, not an instruction to create every screen immediately.

Each workspace must have a clear primary task, information hierarchy, navigation entry, and explicit data/state dependencies. Shared shell, navigation, toolbars, panels, and interaction patterns must remain consistent.

## 4. Design system governance

Use one versioned Institutional Precision Design System (IPDS) as the source of truth for visual primitives and reusable interface behavior.

The IPDS must define and govern:
- Primitive and semantic color tokens, including theme mappings.
- Typography roles, sizes, weights, and numeric-data treatment.
- Spacing, sizing, radii, borders, elevation, and layout constraints.
- Iconography and status semantics.
- Buttons, fields, switches, selectors, menus, toolbars, tabs, tables, charts, panels, dialogs, and window shells.
- Focus, hover, pressed, disabled, loading, empty, error, warning, and success states.
- Accessibility contrast, keyboard navigation, VoiceOver semantics, and reduced-motion behavior.

Rules:
1. Reuse the approved brand palette and existing token definitions. Do not replace them with colors invented in a prompt or mock-up.
2. Do not hard-code ad hoc colors, spacing, fonts, or radii in feature views when a semantic token or shared component is appropriate.
3. Distinguish semantic meaning from raw color values. A warning, loss, profit, selected state, and connection state must use consistent semantic roles.
4. A component must have one documented behavior and visual contract across the application unless a deliberate variant is specified.
5. New tokens and shared components require a clear use case, naming convention, ownership, and tests or visual verification.
6. Do not create duplicate components with slightly different names to bypass an existing shared component.

## 5. SwiftUI architecture and implementation discipline

Design and implement the interface as a maintainable system, not a collection of unrelated screen files.

- Follow OOP where appropriate, SOLID, separation of concerns, dependency inversion, dependency injection, encapsulation, and composition.
- Keep feature views focused on presentation and user interaction. Put domain decisions, persistence, networking, and orchestration behind explicit interfaces and view models/services as appropriate.
- Define ownership and lifetime of observable state. Avoid accidental duplicated sources of truth, broad environment objects, hidden singletons, and view-local copies of shared state.
- Prefer small composable views with stable contracts over monolithic bodies and deeply nested conditional layouts.
- Keep reusable controls and layout primitives in shared modules; keep feature-specific composition within its feature.
- Use explicit dependencies and deterministic inputs. Avoid implicit global state and side effects during view rendering.
- Preserve clear boundaries between UI state, persisted preferences, workspace layout state, broker state, and trading-domain state.
- Respect the verified deployment target and toolchain. Do not introduce APIs or packages without checking compatibility against the active Xcode/Swift baseline.
- Do not allow UI code, buttons, view models, or AI surfaces to bypass authorization, RiskEngine, OMS, or Execution Gateway contracts.

### 5.1 Change isolation and regression control

When asked to change one control or view:
1. Locate its actual implementation and all callers.
2. Identify shared components, state owners, layout constraints, and tests affected.
3. Change the smallest coherent boundary.
4. Preserve public contracts and unrelated behavior.
5. Add or update focused tests and visual verification.
6. Inspect affected sibling screens that reuse the component.

Do not redesign an entire screen or restructure unrelated modules to make a small requested change. If the current architecture genuinely prevents a safe local change, explain the coupling, propose the smallest refactor, and state its impact before expanding scope.

## 6. Interaction semantics must remain distinct

Never use similar labels for different actions or conflate their state models. The following are separate concepts:

| Concept | Meaning | Expected scope |
|---|---|---|
| Open Settings | Present the application settings window | Window/navigation action |
| Close Settings | Close the settings window | Window lifecycle action |
| Show / Hide Panel | Change a workspace panel's visibility | Workspace layout state |
| Expand / Collapse | Change the detail or size presentation of a view | Local presentation state |
| On / Off | Enable or disable a boolean setting | Persisted or runtime configuration, according to its contract |
| Connect / Disconnect | Change a broker/service connection lifecycle | Connection state machine |
| Enable / Disable Trading | Change a separately authorized trading capability | Governed operational control; never a cosmetic switch |

A control's label, icon, accessibility description, keyboard behavior, confirmation requirement, and resulting state must match its actual effect. Do not use an `Open` or `Close` button as a substitute for a boolean switch.

### 6.1 Settings window contract

The settings experience must use a shared, reusable settings-window shell rather than unrelated settings screens with different navigation and close behavior.

The owner-provided reference establishes the following interaction intent:
- An explicit **Open Settings** action opens a dedicated settings window.
- The settings window is organized with a section/navigation sidebar and a primary content area.
- A clearly identifiable **Close** action is available at the bottom of the settings window.
- Native macOS window-close behavior must also work.
- Settings controls use consistent shared components and clear labels/help text.
- The window shell is reused across settings sections.

The shell may host sections such as General & Appearance, Trading Configuration, Brokers & Connections, Risk Management, Automated Trading, AI & Intelligence, Data & Integrations, and Advanced Settings. Final section names, order, and availability must be reconciled with approved requirements; this example list is not authorization to implement every section.

**Closing the settings window closes the window only.** It must not implicitly cancel or revert settings, disconnect a broker, stop a strategy, change trading permissions, or close positions.

Persistence behavior must be explicit for each setting category. Do not assume that Close means Apply, Cancel, Save, or Discard. Determine whether a setting is immediate-save, staged with Apply/Cancel, or requires confirmation from its approved configuration contract. Until that policy is specified, document the open decision and do not invent destructive or surprising behavior.

Use native macOS window lifecycle and keyboard conventions where compatible with the product contract. Escape must not silently discard persisted or safety-critical changes.

## 7. Trading and operational safety in the UI

The UI is not an authority boundary. It must accurately expose system state and route requests through governed services.

- Broker-confirmed account, order, fill, position, balance, and margin data remain authoritative for broker activity.
- Never fabricate quotes, balances, positions, P&L, fills, connection status, or order status for visual completeness.
- Display data freshness and degraded/stale states clearly.
- Manual and automated order intents must converge on the same governed order-intake and risk-authorization path.
- A UI affordance must not imply that an order was accepted, sent, filled, or reconciled before authoritative confirmation.
- AI recommendations must be visually distinguishable from verified broker facts and authorized actions.
- No screen, panel, agent, or shortcut may bypass RiskEngine or Execution Gateway.
- LIVE mode, permissions, risk limits, broker credentials, and other security-sensitive controls retain their explicit owner-approval boundaries.

## 8. Required design-to-implementation workflow

For every new screen, significant interaction, or shared component, ChatGPT must follow this sequence:

1. **Discover:** inspect current source, design system, related screens, formal specifications, and existing interaction contracts.
2. **Trace:** map requirements to the target view, components, state owners, services, and tests.
3. **Specify:** state the user task, hierarchy, layout regions, components, states, navigation, keyboard/accessibility behavior, and data dependencies.
4. **Resolve:** identify missing decisions, source conflicts, and assumptions. Do not conceal them inside code.
5. **Design:** use the approved IPDS and native macOS patterns. Produce a wireframe or structured layout specification when useful; label proposals as proposals.
6. **Implement:** build reusable primitives and bounded feature composition with explicit state and dependencies.
7. **Verify function:** test navigation, controls, state transitions, persistence, error/empty/loading states, and keyboard/accessibility behavior.
8. **Verify visually:** run the actual macOS application, capture screenshots at representative window sizes and states, and compare them with the approved specification and IPDS.
9. **Regression-check:** inspect sibling views and shared components affected by the change; run relevant build and tests.
10. **Document and hand over:** record files changed, design decisions, tests, screenshots/evidence, limitations, and remaining work.

A mock-up, generated image, or code preview is supplementary. It cannot replace a running-app visual inspection for an implemented screen.

## 9. Quality gates and acceptance criteria

A UI change is not complete until applicable gates are evidenced.

### Design quality
- Consistent with the approved IPDS and product design direction.
- Clear visual hierarchy, restrained density, deliberate spacing, readable typography, and consistent alignment.
- No arbitrary token overrides or decorative clutter.
- Layout remains coherent at supported window sizes and resizing states.

### Functional quality
- Every interactive control performs its stated action.
- State has an explicit owner and updates predictably.
- Settings persistence and window lifecycle are unambiguous.
- Loading, empty, error, disabled, and degraded states are handled where relevant.
- No false representation of broker, trading, AI, or system state.

### Engineering quality
- Reuses established components and contracts.
- Avoids unrelated refactors and duplicate sources of truth.
- Respects deployment/toolchain compatibility.
- Includes appropriate unit, integration, UI, or snapshot tests where supported.
- Does not weaken security, authorization, or trading safeguards.

### Visual and accessibility quality
- Verified in the actual running macOS application, not only in a generated mock-up.
- Screenshots cover representative sizes, themes, and important states.
- Keyboard navigation, focus visibility, semantic labels, contrast, and VoiceOver behavior are checked.
- Visual regressions in shared components are reviewed.

If a gate cannot be performed in the available environment, mark it **NOT VERIFIED**, state why, and identify the exact next verification action. Never report it as passed.

## 10. ChatGPT response and delivery requirements

For UI/UX engineering tasks, ChatGPT must:
- State the inspected source files and specifications before proposing implementation.
- Separate owner-approved requirements, existing verified behavior, proposals, assumptions, and unresolved decisions.
- Explain the intended layout and interaction before broad implementation.
- Prefer a complete, coherent file-level change over disconnected snippets when code is requested.
- Avoid repeatedly replacing the design direction from prompt to prompt.
- Preserve established tokens, component APIs, navigation, and state contracts.
- Show actual implementation evidence and test results; never claim a screenshot, build, or test that was not produced.
- Provide a concise handover with changed files, rationale, verification, and outstanding issues.

If the user asks for a specific visual adjustment, do not reinterpret the whole product. Implement the requested change within the established system and report any necessary adjacent impact.

## 11. Open design decisions and follow-up work

The following are not asserted as already resolved by this directive:
- Full clause-level reconciliation and approval mapping for ATP-ARCH-014, ATP-ARCH-037, ATP-ARCH-038, original IPDS specifications, and visual-design sources.
- Final IPDS token/component inventory and exact token values.
- Final settings section inventory and per-category persistence policy.
- Final workspace inventory, responsive breakpoints, and screen specifications.
- Automated screenshot/snapshot regression tooling and its CI integration.
- Accessibility acceptance checklist and supported assistive-technology qualification.

Track these items in the task register and resolve them against authoritative source material before claiming production design-system completion.

## 12. Related project instructions

This directive is subordinate to root `AGENTS.md`, owner approvals, and accepted architecture/decision records. It is intended to be used alongside:
- `docs/architecture/AI_AGENT_NAVIGATION.md`
- `docs/engineering/PROJECT_CONTINUITY.md`
- `docs/engineering/TASK_REGISTER.md`
- `docs/engineering/IMPLEMENTATION_STATUS.md`
- `docs/engineering/MASTER_DOCUMENT_REGISTRY.md`
- `docs/engineering/SPECIFICATION_CONFLICT_REGISTER.md`

**Core instruction:** Design ATHEER Trading Pro as one coherent professional product. Do not let ChatGPT's momentary aesthetic preference replace documented product decisions, existing architecture, or verified user requirements.
