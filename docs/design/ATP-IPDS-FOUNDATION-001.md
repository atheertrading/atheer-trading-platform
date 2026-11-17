# ATP-IPDS-FOUNDATION-001 — Initial Native Design-System Foundation

**Status:** Implemented foundation; provisional token inventory pending formal IPDS reconciliation. Not a claim of IPDS v1.0 approval or design completion.  
**Implementation:** `apps/macos/ATHEERTradingPro/Sources/ATHEERDesignTokens.swift` and shared workspace components in PR #18.

## 1. Visual direction

The native interface follows a restrained, dark-first institutional workstation direction: high-contrast hierarchy, compact operational labels, readable numeric values, consistent surfaces, minimal decoration and native macOS controls.

The palette values below are the owner-provided starting palette. The canvas, deep teal and cyan were also present in the existing PR #17 shell. Their complete semantic mapping remains provisional until the formal IPDS source is reconciled.

| Token | Value | Intended semantic role |
|---|---|---|
| Canvas | `#121212` | Main application background |
| Deep teal | `#093732` | Navigation/sidebar identity surface |
| Navy | `#001F3F` | Reserved brand/surface role; not yet used by the current workspace |
| Teal | `#008080` | Reserved brand/interaction role; not yet used by the current workspace |
| Cyan | `#00CEC8` | Primary brand and active accent |
| Gold | `#FFD700` | Attention, warning and unavailable capability |
| Red | `#D32F2F` | Error and disconnected state |
| Green | `#00C853` | Positive/verified state; not used to imply trading readiness |

Neutral panel surfaces currently use white overlays at 3.5% and 5.5% opacity; separators use 8% white opacity. These preserve the existing surface treatment rather than introducing a new surface palette.

## 2. Typography and spacing foundation

Implemented shared roles:

| Role | Current implementation |
|---|---|
| Brand | 18 pt bold rounded |
| Screen title | 25 pt semibold |
| Panel title | 13 pt semibold |
| Body | 12 pt |
| Caption/metadata | 10 pt medium |
| Numeric/status value | 15 pt semibold monospaced |

Spacing primitives currently exposed are 6, 12, 18 and 24 points. Panel inset is 14 points; workspace panel grid gap is 14 points. These are implementation values, not a final cross-platform token contract.

## 3. Shared components implemented

- `WorkspacePanelCard`: consistent panel heading, icon, subtitle, status label, separator and content region.
- `WorkspaceUnavailableState`: explicit explanation when a data dependency is not configured.
- `WorkspaceStatusTile`: compact operational summary with label, value, detail and semantic tint.
- `BackendStatusPanel`: platform health state using the shared surface and typography roles.
- `WorkspacePanelID`: stable identity and default inventory for the four initial workspace panels.

Feature views consume shared token roles rather than independently declaring their own panel colors and type styles.

## 4. Interaction and state conventions

- Status must be expressed through text and iconography as well as color.
- Unavailable data is labelled explicitly; no market/account values are fabricated.
- Panel visibility is an explicit Show/Hide presentation action.
- Reset restores the default panel visibility.
- Panel visibility currently lives in view state and is not persisted.
- Native buttons and menu controls are used for panel visibility and API Connection navigation.
- The backend health panel retains refresh state and read-only semantics.
- Trading remains disabled; no dealing or risk mutation controls are present.

## 5. Window and layout baseline

Current source establishes:
- Minimum application window: 900 × 600 points.
- Minimum detail region: 620 × 520 points.
- Sidebar minimum width: 190 points.
- Workspace content maximum width: 1280 points.
- Dark appearance is selected at the application scene.

These are current implementation constraints, not final responsive/window specifications. Docking, draggable panel rearrangement, user resizing policy, workspace profiles, layout persistence and Settings window construction remain open.

## 6. Accessibility and qualification status

Implemented foundations include text labels alongside status colors, combined accessibility elements for compact status tiles, contained accessibility grouping for panels, and selectable diagnostic text.

Not yet qualified:
- VoiceOver traversal and announcements.
- Full keyboard navigation and focus order.
- Contrast measurements for every semantic combination.
- Dynamic Type behavior.
- Reduced-motion behavior.
- Localization and right-to-left layout.
- Visual regression across supported window sizes and displays.
- Actual macOS visual/runtime behavior.

Hosted CI is necessary but does not establish these runtime properties.

## 7. Source authority and next reconciliation

The exact approved full text and approval metadata for the original IPDS and ATP-ARCH-014/037/038 were not surfaced by the current Library retrieval. ATP-UX-001 on PR #13 requires reuse of approved palette/tokens and prohibits model-invented styling; it supplements rather than supersedes the formal sources.

Therefore:
- Keep this foundation explicitly provisional.
- Do not add new brand colors or promote reserved palette entries into semantic roles without source validation.
- Do not declare IPDS v1.0 complete.
- Reconcile primitive/semantic token names, typography, chart colors, component contracts, theme mappings, accessibility and localization before broad screen expansion.
