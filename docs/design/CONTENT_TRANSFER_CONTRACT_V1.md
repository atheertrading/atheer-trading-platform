# ATHEER Trading Pro — Application Content Transfer Contract v1

**Document ID:** ATP-UI-CONTENT-TRANSFER-001  
**Issue:** [#16 — Application-wide native macOS clipboard and context-aware drag-and-drop](https://github.com/atheertrading/atheer-trading-platform/issues/16)  
**Implementation branch:** \`feat/ui-content-transfer\`  
**Status:** Bounded implementation candidate; full control audit and owner-Mac qualification pending  
**Platform baseline:** macOS 13.0 / Swift 5

## 1. Purpose

Define one application-wide policy for copying, pasting, cutting, selecting, and dragging content in ATHEER Trading Pro. The system distinguishes text editing, read-only value copying, structured application payloads, and workspace configuration changes.

Clipboard and drag/drop are presentation/data-transfer capabilities. They are never authorization boundaries and cannot trigger broker, order, position, strategy, risk, OMS, or execution side effects.

## 2. Interaction principles

1. Preserve native macOS responder-chain behavior and the Edit menu.
2. Use semantic payload types rather than ad-hoc strings for internal objects.
3. Offer plain-text or standard-format fallbacks for interoperability.
4. Distinguish same-container move, cross-container copy, and external copy.
5. Validate every incoming payload at the destination before mutating workspace state.
6. Keep source objects unchanged for copy operations.
7. Provide a non-drag alternative for every essential workspace action.
8. Never place credentials, tokens, broker session values, or secure fields on the clipboard or in a drag payload.

## 3. Clipboard policy

### 3.1 Native text controls

SwiftUI/AppKit text controls retain native editing and selection behavior:

- Select All (\`⌘A\`).
- Copy (\`⌘C\`).
- Cut (\`⌘X\`) when the control is editable and the selection can be removed.
- Paste (\`⌘V\`) when the control is editable and the incoming value is accepted.
- Native undo/redo and replacement behavior.

The app retains its existing \`TextEditingCommands()\` scene command integration. It does not install competing global shortcuts for the same commands.

The application root enables text selection for read-only \`Text\` content so technical values and screen copy can be selected without making the view editable.

### 3.2 Read-only values

- Non-sensitive API endpoints, versions, timestamps, identifiers, diagnostic details, instrument EPICs, and provider metadata can be selected/copied.
- Reusable \`CopyableValueRow\` uses a shared clipboard-writing service and retains its explicit button/contextual Copy action.
- Read-only content is never made editable to obtain clipboard support.
- A status display or chart must expose a deliberate textual/structured representation; screenshots are not a substitute for copying the underlying value.

### 3.3 Sensitive values

Credential entry, masked API keys, session tokens, cookies, private keys, and secure broker data are excluded from shared copy/drag helpers. Any future revealed-secret copy action requires a separate, explicit security decision and user action. No such facility is introduced by this increment.

## 4. Transfer types and representations

Custom Uniform Type Identifiers are registered in the generated application Info.plist and conform to JSON. Each payload includes a schema version.

| Content | Custom UTI | Representation | Current semantics |
|---|---|---|---|
| Workspace panel reference | \`com.atheertrading.workspace-panel\` | Codable JSON + plain-text panel identifier | Same workspace: move/reorder. Different workspace: copy configuration |
| Workspace layout | \`com.atheertrading.workspace-layout\` | Codable JSON + workspace-name text proxy | Copy to clipboard, paste/drop to import as a new workspace |
| Instrument reference | \`com.atheertrading.instrument-reference\` | Codable JSON + plain-text EPIC/identifier | Drag/copy from verified Capital.com DEMO results; validated drop/paste into instrument search |

The application currently uses Swift \`Transferable\`, \`CodableRepresentation\`, \`ProxyRepresentation\`, and SwiftUI \`draggable\`, \`dropDestination\`, \`copyable\`, and \`pasteDestination\` APIs on the existing macOS 13 deployment baseline.

### 4.1 Workspace panel reference

A panel transfer contains only:
- Schema version.
- Source workspace UUID.
- Supported panel identifier.

It does not contain the panel's service state, market data, account state, strategy state, or broker information.

Move/copy policy:
- Drop within the same workspace and same panel region reorders the existing panel.
- Cross-workspace panel transfer copies the panel configuration and keeps the source unchanged. The current management surface exposes this primarily through typed Copy/Paste; a simultaneous cross-workspace drag source/destination is not claimed by the current single-workspace screen.
- Duplicate panel identities are rejected by the existing workspace invariants.
- Unsupported panel regions and unknown IDs are rejected.
- Existing Move Up/Move Down controls and panel context-menu commands remain as keyboard/menu alternatives.
- The first increment accepts one panel per drag operation; multi-selection is not exposed yet.

### 4.2 Workspace layout

A layout export includes:
- Schema version and display name.
- Supported panel identifiers, visibility, and order.
- Workspace presentation geometry.

It excludes:
- Workspace runtime/service objects.
- Broker connections, credentials, sessions, and accounts.
- Market quotes, positions, balances, orders, fills, and P&L.
- Strategy state, risk policy, and execution state.

Import rules:
- Validate schema, workspace name, supported panel catalogue, duplicate identities, ordering, and geometry.
- Create a new workspace with a new UUID in the active profile.
- Never overwrite an existing workspace.
- Validate the resulting profile/workspace snapshot before committing persistence.
- Invalid or unsupported content is rejected without a partial import.

### 4.3 Instrument reference

The current Market Explorer and Instrument Quick Search can export an instrument EPIC only from a backend-reported Capital.com DEMO session. The payload includes the identifier kind and provider identity, not a price or live quote.

Drop/paste into a search field:
- Validates schema, EPIC shape/length, provider identity, and current connected DEMO provider state.
- Places the EPIC into the search field but does not submit a search automatically.
- Never creates an order, chart object, watchlist subscription, or position change.

## 5. Workspace drag/drop feedback and alternatives

- Native drag previews remain system-managed.
- The eligible row is highlighted only while a compatible panel reference is targeted.
- Same-workspace reordering is bounded to the existing primary/secondary panel region.
- Unsupported and malformed items return a rejected drop result.
- Existing up/down controls and panel context-menu commands remain available when dragging is inconvenient or unavailable.
- Layout import can be performed by paste or drop on the panel list.

A later increment should add undo-backed workspace reorder and file-based JSON import/export where that interaction improves recovery and handoff.

## 6. Future content-specific transfer matrix

The transfer contract is extensible, but a representation is implemented only when its owning feature has a verified model and a safe destination contract.

| Product context | Preferred representation | Fallback | Action policy |
|---|---|---|---|
| Editable text | Native text/RTF where supported | Plain text | Native text editing only |
| Read-only diagnostic | Plain text | — | Copy only |
| Instrument | Versioned instrument-reference JSON | EPIC/plain text | Search/selection only |
| Watchlist/table | Versioned JSON + CSV/TSV | Plain text | Metadata/export only; no order action |
| Chart/drawing | Versioned native chart/drawing JSON | PNG/PDF | Analytical artifact only |
| Workspace/profile | Versioned layout JSON | Plain-text name/summary | New layout import only |
| Position/order | Redacted read-only snapshot JSON + CSV/TSV | Plain text | Export only; never mutate the source |
| Reports | PDF/CSV as appropriate | Plain text | Export only |

CSV/TSV, chart artifact exchange, position/order report export, multi-item transfers, and file-based workspace import/export remain future increments until the corresponding domain schemas and screen contracts are implemented.

## 7. Trading and security invariants

- Copy/paste/drop cannot call broker dealing APIs.
- No drag/drop or paste can submit, amend, cancel, or close an order or position.
- No drag/drop or paste can start/stop a strategy, change risk policy, enable trading, authenticate a broker, or change permissions.
- A copied instrument ID or layout is untrusted input and must be validated again by the destination.
- No account identifiers or secret material are serialized unless an explicit approved export contract permits it.
- No clipboard helper infers permission from a visual state, an enabled button, or a drag operation.
- The app's read-only/trading-disabled baseline remains unchanged.

## 8. Automated tests and current implementation

Current source:
- \`ATHEERClipboardService.swift\`
- \`ATHEERContentTransfer.swift\`
- \`CopyableValueRow.swift\`
- \`WorkspacePanelManagementView.swift\`
- \`WorkspaceEngine.swift\`
- \`MarketExplorerView.swift\`
- \`InstrumentQuickSearchView.swift\`

Deterministic tests:
- \`ATHEERContentTransferTests.swift\` validates round-trip, unsupported schema, unknown panel, duplicate panels, invalid geometry, and instrument identifier bounds.
- \`WorkspaceContentTransferTests.swift\` validates source-preserving panel copy, cross-profile rejection, new-workspace import, and no mutation for invalid import.

The tests establish model/engine behavior; they do not establish native keyboard responder behavior, actual pasteboard interoperation, live drag visuals, VoiceOver support, or owner-Mac interaction.

## 9. Required application-wide audit and native qualification

The remaining audit must inspect every current and future:
- \`TextField\`, \`SecureField\`, \`TextEditor\`, and custom editable control.
- Read-only diagnostic/status/log/metadata view.
- Table, list, and multi-selection model.
- Workspace, panel, profile, instrument, chart, order, position, portfolio, and report surface.
- Menu, context menu, dialog, sheet, and toolbar command.

Native Mac verification must cover:
- Focused-control command routing for ⌘A/C/X/V and undo/redo.
- Edit menu and contextual actions.
- Read-only text selection without accidental editability.
- Copy/paste between ATHEER and a standard macOS app.
- Drag within a panel region, between workspaces, and between instrument search surfaces.
- Rejected drops, target feedback, scroll behavior, and keyboard/menu alternatives.
- VoiceOver, Full Keyboard Access, focus order, and selection announcements.
- Dark/Light appearance and supported window sizes.

Until those checks are recorded, Issue #16 remains open and this feature is an initial native implementation slice, not a claim of complete application-wide qualification.

## 10. Apple platform references

- Human Interface Guidelines — Drag and drop: https://developer.apple.com/design/human-interface-guidelines/drag-and-drop
- SwiftUI — Drag and drop: https://developer.apple.com/documentation/swiftui/drag-and-drop
- SwiftUI — Clipboard: https://developer.apple.com/documentation/swiftui/clipboard
- Core Transferable: https://developer.apple.com/documentation/coretransferable
- SwiftUI menu bar and standard Edit commands: https://developer.apple.com/documentation/swiftui/building-and-customizing-the-menu-bar-with-swiftui
