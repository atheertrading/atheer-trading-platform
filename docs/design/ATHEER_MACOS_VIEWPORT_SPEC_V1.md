# ATHEER Trading Pro — macOS Design Viewport Specification v1

## Status

**Proposed design baseline, grounded in current repository source.** This specification records the minimum content-layout frame currently declared by the SwiftUI application and a standardized wide-desktop design canvas. It does not claim runtime verification on every supported Mac/display configuration and does not approve a release minimum.

## Repository evidence

Reviewed at PR #73 head before this specification was authored:

- Repository: `atheertrading/atheer-trading-platform`
- Source revision: `703995764228a60a4e5503edcf2dcac1c5ced749`
- File: `apps/macos/ATHEERTradingPro/Sources/ContentView.swift`

The current source declares:

- Root content frame: `.frame(minWidth: 900, minHeight: 600)`
- Navigation sidebar: `.frame(minWidth: 190)`
- Detail region: `.frame(minWidth: 620, minHeight: 520)`
- Broker management sheet: `.frame(minWidth: 760, minHeight: 560)`

These values are SwiftUI logical points, not raster pixels. The root declaration is the current repository-enforced minimum content-layout frame. It is not evidence of the complete outer NSWindow frame including title bar/chrome, nor of successful runtime layout on every display scale.

## Adopted design canvases

| Purpose | Logical content viewport | 2× export canvas | Status |
|---|---:|---:|---|
| Minimum supported-layout baseline | 900 × 600 pt | 1800 × 1200 px | Source-declared; runtime QA pending |
| Wide desktop reference | 1440 × 900 pt | 2880 × 1800 px | Design target; not a minimum requirement |

Use these exact logical dimensions for the first SCR-00 Application Shell + Navigation mockup. The 2× dimensions are export guidance only; do not treat PNG pixel dimensions as SwiftUI point dimensions.

## Responsive design rules

1. At 900 × 600 pt, preserve navigation, screen identity, environment/broker identity, connection/freshness indicators, and access to critical alerts. Reduce optional decoration and secondary summaries first.
2. Keep the sidebar at or above its currently declared 190 pt minimum unless a separately reviewed implementation change revises that constraint.
3. Preserve a usable detail region. Do not infer that the sidebar and detail minimums can be independently added to establish the outer window size; validate actual NavigationSplitView behavior at runtime.
4. At 1440 × 900 pt, use the additional area for analytical hierarchy and contextual detail, not arbitrary enlargement of controls or decorative whitespace.
5. Intermediate widths must be tested for sidebar collapse/visibility behavior, truncation, table overflow, inspector behavior, and keyboard navigation.
6. Dark and Light variants must use the same viewport pair. Arabic RTL must be rendered and reviewed at both viewports, including navigation order, mixed-direction symbols/instrument identifiers, numeric alignment, and truncation.
7. Settings sheets and other secondary windows require their own explicit viewport contracts; the existing broker sheet declaration (760 × 560 pt minimum) is not a substitute for the main-window baseline.

## Acceptance evidence required before calling 900 × 600 a supported product minimum

- Build and launch the app on the declared minimum supported macOS version.
- Set the main window to 900 × 600 pt content size and capture the actual rendered window.
- Verify no clipped controls, inaccessible navigation, overlapping status indicators, or unusable detail content.
- Repeat in Dark, Light, and Arabic RTL.
- Verify window resizing below the declared minimum is constrained as intended.
- Test on the owner-approved display scale(s) and multi-display arrangements.
- Record screenshots, OS/build metadata, and test outcome in the screen implementation PR.

Until that evidence is attached, describe 900 × 600 pt as the **current source-declared minimum layout frame**, not a fully runtime-qualified product guarantee.

## First screen delivery

SCR-00 Application Shell + Navigation must provide:
- Minimum baseline: 900 × 600 pt.
- Wide reference: 1440 × 900 pt.
- Dark and Light appearance.
- English LTR and Arabic RTL.
- Compact, Balanced, and Spacious density behavior where materially different.
- Normal, disconnected/stale, and alert-present shell states.
- SwiftUI component mapping and acceptance tests tied to the shell contract.

## Change control

Any change to the source-declared minimum frame, sidebar minimum, detail minimum, or secondary-window minimum must update this specification and include runtime visual QA evidence. Mockup approval does not itself change application constraints.
