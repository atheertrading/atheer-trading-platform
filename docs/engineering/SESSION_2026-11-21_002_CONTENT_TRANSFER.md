# Engineering Session 2026-11-21 — Application Content Transfer

**Work package:** ATP-UI-CONTENT-TRANSFER-001  
**Issue:** #16 — Application-wide native macOS clipboard and context-aware drag-and-drop  
**Team:** A — UI / Frontend Engineering  
**Branch:** `feat/ui-content-transfer`  
**Parent baseline:** `feat/ipds-visual-asset-package`  
**Status:** Initial implementation candidate; exact-head hosted CI and owner-Mac qualification pending

## Objective

Extend native macOS content interaction from the first clipboard increment in merged PR #17 into an extensible application-wide clipboard policy and context-aware transfer contract, with workspace and instrument vertical slices.

## Discovery and source review

- Reviewed root `AGENTS.md`, current Team A feature ancestry, Issue #16 and its recorded implementation note from PR #17.
- Inspected current application composition, `ATHEERTradingProApp`, `CopyableValueRow`, `WorkspaceEngine`, `WorkspacePanel`, `WorkspacePanelManagementView`, `MarketExplorerView`, `InstrumentQuickSearchView`, XcodeGen configuration, and relevant tests.
- Confirmed PR #17's first copy increment covered non-sensitive diagnostic rows and native text editing commands, but did not complete the application-wide clipboard audit or owner-Mac runtime checks.
- Updated Issue #16 with explicit drag/drop scope, versioned transfer payloads, validation, interoperability, accessibility, and safety requirements.
- Used the native SwiftUI/Core Transferable direction documented by Apple for drag, drop, clipboard, and responder/menu behavior; see the linked Apple references in the content-transfer contract.

## Implemented

### Application clipboard foundation

- Enabled native read-only text selection at the application root without making read-only text editable.
- Added `ATHEERClipboardService` for explicit non-sensitive plain-text and typed JSON clipboard writes.
- Updated `CopyableValueRow` to use the shared service and expose a native copyable string representation.
- Retained the existing `TextEditingCommands()` scene integration; no duplicate global ⌘C/⌘V/⌘X/⌘A shortcuts were introduced.

### Typed content transfer

Added `ATHEERContentTransfer.swift` with schema-versioned `Codable` / `Transferable` payloads and JSON-conforming custom UTIs for:
- Workspace panel references.
- Presentation-only workspace layouts.
- Provider-grounded instrument references.

Each representation offers a plain-text proxy for interoperability. The XcodeGen target declares the custom exported types in its generated application Info.plist.

### Workspace interactions

- Same-workspace panel drops reorder the panel in its existing primary/secondary region.
- Existing Move Up / Move Down controls and context-menu actions remain available as non-drag alternatives.
- Panel references can be copied and pasted into a different workspace in the active profile; source layout remains unchanged.
- Workspace layout JSON can be copied and pasted/dropped onto Panel Management to import a new workspace with a new identity.
- Import validates schema, workspace name, panel catalogue, duplicate identities, order values, and geometry before engine mutation.
- Engine copy/import transactions validate and persist candidate snapshots before publishing state.

### Instrument interactions

- Market Explorer and Instrument Quick Search expose provider-grounded instrument references from backend-reported connected Capital.com DEMO state.
- Search fields accept typed instrument drops/pastes only when the provider, environment, identifier kind, and current backend connection state match.
- Applying a reference populates the EPIC search field only; it does not auto-submit a search or initiate trading.

## Tests added

- `ATHEERContentTransferTests.swift`: payload round-trip, unsupported schema, unknown panel, duplicate panel, geometry bounds, and instrument identifier validation.
- `WorkspaceContentTransferTests.swift`: source-preserving cross-workspace panel copy, invalid cross-profile rejection, new-identity layout import, and no-mutation failure.

These tests cover deterministic payload/engine behavior only. They do not prove live pasteboard interoperability, actual Edit-menu responder routing, native drag visuals, keyboard/focus, or VoiceOver behavior.

## Explicitly deferred

The first implementation slice does not yet provide:
- A complete screen/control audit for all text, secure, table, list, log, dialog, and custom editable surfaces.
- CSV/TSV table export, chart/drawing exchange, redacted position/order reports, or PDF/image export.
- File-based workspace import/export UI.
- Multi-item drag/drop.
- Explicit UndoManager-backed panel reorder.
- Owner-Mac keyboard, context-menu, actual clipboard, drag/drop, VoiceOver, Full Keyboard Access, and accessibility qualification.

These remain gates/follow-up tasks under Issue #16. Do not describe this PR as completing the entire application-wide requirement.

## Safety and ownership

- UI / native application and workspace presentation only.
- No backend-owned source, service contract, broker authentication, credential custody, account state, broker session, RiskEngine, OMS, Execution Gateway, or order lifecycle is modified.
- Transfer payloads contain panel references, workspace presentation configuration, or instrument identity only.
- No credentials, API keys, tokens, session cookies, secret fields, quotes, positions, balances, orders, or P&L are serialized.
- Paste/drop never auto-submits a search and cannot trigger any trading side effect.
- No trading controls, risk-policy settings, or LIVE permissions are introduced.
- `CAP_ALLOW_TRADING=false` remains unchanged.

## Verification state

- Source, tests, XcodeGen UTI declarations, contract documentation, and continuity updates are committed on the feature branch.
- Exact-head hosted CI, XcodeGen project generation, Intel/Apple Silicon Debug build, XCTest, Release build, and Swift CodeQL are pending.
- No local owner-Mac build, runtime, manual clipboard, drag/drop, focus, VoiceOver, or accessibility pass is claimed.

## Next gates

1. Review exact PR head and hosted CI results; repair any XcodeGen, SDK availability, Swift type-check, or XCTest failures.
2. Verify the app's generated Info.plist contains the three custom UTI declarations.
3. Perform a source audit of all implemented editable/read-only/secure controls and keep secret surfaces excluded.
4. Verify native ⌘C/V/X/A, Edit menu, selection, copy/paste interoperability, workspace panel reorder/paste/layout import, and instrument transfer on a supported Mac.
5. Verify Full Keyboard Access, focus, VoiceOver, malformed payload rejection, and no mutation on rejected operations.
6. Keep Issue #16 open until its full application-wide acceptance criteria are evidenced.
