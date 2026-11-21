---
document_id: ATP-IPDS-ASSET-001
version: 1.0.0
status: "Proposed implementation increment — pending Design Authority review"
approval_status: "Not formally approved"
implementation_status: "Prepared on feat/ipds-visual-asset-package; exact-head CI and native Mac qualification pending"
platform: "Native macOS / SwiftUI"
---

# ATHEER Trading Pro — IPDS Reusable Visual Asset Package

## 1. Purpose and scope

Establish a reusable and source-controlled asset foundation for the Institutional Precision Design System (IPDS), derived from the ATHEER Trading Pro Showcase and reconciled with the current macOS application baseline.

The package contains:

- Editable geometric brand-mark, wordmark, and app-icon SVG masters.
- A visible atlas with ten reusable geometric SVG symbol definitions.
- Platform-neutral JSON handoff manifests for colors, typography, and geometry.
- Runtime Swift design tokens and reusable SwiftUI primitives.
- Deterministic XCTest coverage for token compatibility and geometric scaling.
- 2× PNG review previews generated from the SVG sources.

This is a bounded implementation increment. It does not mean the full IPDS, all screens, or the final brand identity have been approved.

## 2. Repository and platform baseline

The reviewed XcodeGen project currently specifies:

| Property | Existing value |
|---|---|
| Platform | macOS |
| Deployment target | 13.0 |
| Swift language mode | 5 |
| Application bundle | com.atheertrading.desktop |
| Source discovery | apps/macos/ATHEERTradingPro/Sources |
| Test discovery | apps/macos/ATHEERTradingPro/Tests |

This package retains the current deployment target, Swift language mode, and dependency set. It introduces no package dependency and no new Liquid Glass API requirement.

Existing owner-approved design direction remains:

- Dark-first appearance.
- Light appearance support.
- Adaptive information density.
- English and Arabic with full RTL support.

The package preserves existing design-token identifiers and legacy metrics so current screens are not forced into an unrelated visual rewrite.

## 3. Apple macOS design alignment

### 3.1 Native-first controls

Prefer native SwiftUI/AppKit controls for buttons, navigation, toolbars, menus, pickers, toggles, text fields, steppers, dialogs, and contextual commands. Custom IPDS components should provide semantic consistency and branding without removing platform activation, focus, keyboard, or accessibility behavior.

The ATHEERButton wrapper selects native SwiftUI button styles by semantic variant. It deliberately does not draw a custom bezel or replace the native focus ring.

Use SF Symbols with Image(systemName:) for native application controls wherever a suitable system symbol exists. The SVG symbol atlas is a design-handoff resource, not a direction to replace system icons indiscriminately.

### 3.2 Liquid Glass policy

Liquid Glass is a system visual layer for appropriate functional surfaces such as navigation and toolbars. It is not a general background material for every content surface.

- Prefer system-managed navigation, toolbar, sidebar, and menu integration.
- Keep charts, tables, order books, market-data cells, order entry, and numerical panels stable and legible.
- Do not blanket-apply glass effects to cards or financial content.
- Do not add an unguarded glassEffect dependency while macOS 13 remains the deployment target.
- Any future newer-OS enhancement must be availability-gated and retain a functional fallback.
- Validate Reduce Transparency, Increase Contrast, and window/scroll-edge behavior on a native Mac.

### 3.3 Control metrics

Apple's current macOS Accessibility HIG lists 28 × 28 pt as a default control target reference and 20 × 20 pt as a minimum reference. The package represents these as platform guidance, not a command to size every control identically.

ATHEER additionally defines a 44 pt touch-expanded target proposal for touch-capable Macs. This is a project adaptation target, not a claim that 44 pt is Apple's universal macOS control size. Touch expansion must be adaptive and must not permanently inflate keyboard/pointer layouts.

## 4. Palette and semantic color tokens

Runtime implementation:

apps/macos/ATHEERTradingPro/Sources/ATHEERDesignTokens.swift

Portable handoff files:

- docs/design/assets/ipds/tokens/ipds-colors.json
- docs/design/assets/ipds/tokens/ipds-typography.json
- docs/design/assets/ipds/tokens/ipds-geometry.json

Feature views MUST consume semantic ColorRole values rather than hardcode raw hex colors. The Swift source is the runtime token implementation; JSON files are handoff manifests and must be reconciled with Swift whenever tokens change.

### 4.1 Existing primitive palette

| Token | Value | Meaning |
|---|---|---|
| graphiteBlack | #121212 | Dark canvas |
| deepTeal | #093732 | Structural navigation tone |
| midnightNavy | #001F3F | Brand navy |
| teal | #008080 | Brand teal |
| currentTurquoise | #00CEC8 | Current implementation value |
| gold | #FFD700 | Restrained brand accent |
| slateBlue | #384959 | Supporting neutral |
| mutedTeal | #3C635F | Supporting brand tone |
| softTurquoise | #81D8D0 | Supporting brand tone |
| positive | #00C853 | Existing positive palette value |
| negative | #D32F2F | Existing negative palette value |

### 4.2 Unresolved brand-turquoise conflict

Two authoritative project records conflict:

- Owner Q&A Q39.1 specifies #40E0D0.
- Phase 00 v1.1 and the current implementation use #00CEC8.

This increment preserves #00CEC8 to avoid silently changing existing screens. The canonical brand value remains unresolved and requires Design Authority review. No new feature-specific turquoise value is introduced to bypass the conflict.

### 4.3 Semantic roles

The runtime token implementation provides appearance-aware roles for canvas, navigation, panel, elevated panel, primary/secondary text, accent, text-on-accent, brand mark colors, positive, negative, warning, information, neutral, separators, focus, border, and destructive foreground.

Compatibility rule: the pre-existing dark neutral role `#384959` and light neutral role `#52616B` are preserved. The brighter neutral foreground used by informational badges is exposed separately as `neutralText`; a presentation refinement must not silently repurpose an established semantic token.

Semantic rules:

- Accent is not synonymous with profit, market direction, or trade side.
- Connected, selected, successful, and profitable are separate concepts.
- Unknown/unavailable must never be rendered as a healthy state.
- Positive and negative financial values require a sign, label, or directional cue in addition to color.
- DEMO/LIVE identifies environment, not authorization.

## 5. Typography tokens

Use the native system font through SwiftUI Font.system. Do not bundle or redistribute system font files. Allow the platform's appropriate script fallback for Arabic. Use monospaced numerals for prices, quantities, P&L, timestamps, and diagnostic identifiers where alignment benefits the workflow.

| Token | Size | Weight / design | Intended use |
|---|---:|---|---|
| display | 28 pt | Semibold | Brand or major value |
| screenTitle | 25 pt | Semibold | Screen title |
| sectionTitle | 16 pt | Semibold | Section heading |
| standardBody | 13 pt | Regular | General interface body |
| panelTitle | 13 pt | Semibold | Panel heading |
| controlLabel | 13 pt | Medium | Button and control label |
| body | 12 pt | Regular | Existing compact body role |
| caption | 10 pt | Medium | Existing compact supporting label |
| metadata | 10 pt | Regular | Secondary metadata |
| numeric | 15 pt | Semibold, monospaced | Primary financial value |
| tableNumeric | 12 pt | Medium, monospaced | Dense tabular value |
| diagnostic | 11 pt | Regular, monospaced | IDs and diagnostics |

These are ATHEER roles, not Apple-mandated point sizes. Prefer native control typography where the system supplies it. Validate line wrapping and mixed Arabic/Latin content in RTL.

## 6. Geometry and control tokens

| Token | Value | Purpose |
|---|---:|---|
| extraSmall | 4 pt | Fine alignment |
| compact | 6 pt | Existing compact spacing |
| small | 8 pt | Inline gap |
| standard | 12 pt | Existing standard gap |
| content | 16 pt | Content inset |
| section | 18 pt | Existing section gap |
| large / page | 24 pt | Page and section spacing |
| extraLarge | 32 pt | Major grouping |
| radius.small | 6 pt | Compact geometry |
| radius.standard | 8 pt | Standard geometry |
| radius.large | 12 pt | Prominent panel geometry |
| stroke.standard | 1 pt | Standard border |
| stroke.focus | 2 pt | Focus-token reference |

Button component minimum heights are 28 pt compact, 32 pt regular, 40 pt prominent, and 44 pt critical. They are ATHEER defaults; standard native control sizes remain preferable wherever they satisfy the workflow.

Motion tokens are 0.12, 0.18, and 0.24 seconds for quick, standard, and deliberate transitions. Avoid animating routine quote updates or creating layout jitter.

## 7. SwiftUI component contracts

### 7.1 Brand mark and lockup

ATHEERBrandMarkShape implements the geometric mark in SwiftUI. Its normalized path coordinates match atheer-mark-primary.svg. ATHEERBrandMark is decorative and hidden from the accessibility tree. ATHEERBrandLockup exposes one combined accessible label, “ATHEER Trading Pro”.

### 7.2 ATHEERButton

Variants: primary, secondary, tertiary, destructive. Sizes: compact, regular, prominent, critical.

Example:

```swift
ATHEERButton(variant: .primary, size: .regular, action: saveWorkspace) {
    Label("Save Layout", systemImage: "square.and.arrow.down")
}
```

The wrapper selects native SwiftUI button styles by semantic variant and exposes explicit enabled/loading inputs. Loading displays a progress indicator and disables repeated activation. The underlying Button retains native activation, keyboard behavior, and system focus treatment. Primary and destructive label colors use theme-aware foreground tokens. Prefer native toolbar items and system button styles for window-toolbar commands. Destructive actions must use the appropriate native Button role and separate confirmation/authorization where required.

### 7.3 ATHEERToggleRow

A labelled preference row that uses the native macOS switch control. Binding and persistence stay with the caller/ViewModel. It does not persist preferences independently.

```swift
ATHEERToggleRow(
    title: "Show extended market metadata",
    detail: "Display provider and freshness information in market tables.",
    isOn: $preferences.showExtendedMetadata
)
```

A generic switch MUST NOT grant LIVE authorization, change risk policy, or bypass backend permissions.

### 7.4 ATHEERStatusBadge

Tones: positive, warning, negative, information, and neutral. The badge is read-only, has no button action, and exposes visible text plus an accessibility label/value. It must not imply a broker/account/execution fact unless sourced from a verified contract.

### 7.5 Native components for other interactions

Use native controls for tabs, segmented pickers, pop-up selection, checkboxes, radio groups, text fields, steppers, menus, and contextual actions. Custom components are justified only when a specific workflow requires them; do not redraw a system control purely for cosmetic differentiation.

## 8. SVG asset inventory and runtime policy

| Asset | Path | Intended use |
|---|---|---|
| Geometric brand mark | brand/atheer-mark-primary.svg | Scalable identity mark |
| Horizontal wordmark | brand/atheer-wordmark-horizontal.svg | Documentation and brand surfaces |
| App icon master | brand/atheer-app-icon-master.svg | Full-bleed vector master for future icon export |
| UI symbol atlas | icons/atheer-ui-symbols.svg | Visible atlas with ten reusable symbol definitions |
| Color tokens | tokens/ipds-colors.json | Primitive and semantic Dark/Light roles |
| Typography tokens | tokens/ipds-typography.json | Typography hierarchy and numerical roles |
| Geometry tokens | tokens/ipds-geometry.json | Spacing, radii, strokes, targets, buttons, motion |
| PNG previews | Distribution ZIP under previews/ | 2× review exports; SVG remains editable source |

The app icon SVG is a full-bleed master. Do not bake a second rounded-corner mask into a future platform export. This artwork is not yet integrated into the Xcode asset catalog or approved as the final app icon. No SVG is downloaded or rendered remotely at runtime.

## 9. Accessibility, safety, and financial UI invariants

- Use visible labels and accessible semantics for critical commands.
- Keep focus visible and predictable; tooltips do not replace accessibility labels.
- Validate Dark/Light, Increased Contrast, Reduced Transparency, keyboard, VoiceOver, and Arabic RTL on a native Mac.
- Keep financial content stable and legible; do not use glass/translucency as a default chart/table surface.
- A status badge is not proof of a broker or account state unless bound to a verified source.
- A disabled button is not an authorization boundary.
- Manual, strategy, and AI order requests retain the existing order-intent, RiskEngine, OMS, Execution Gateway, and reconciliation controls.
- This package does not change broker endpoints, credentials, risk policy, order submission, positions, execution, trading permission, or LIVE authorization.

## 10. Verification and acceptance

Automated coverage in ATHEERDesignSystemAssetTests.swift checks:

- Existing raw palette values are preserved.
- Existing spacing and radius token values remain stable.
- macOS default/minimum target references and separate touch-expanded target.
- Geometric brand-mark scaling is proportional.

Package preparation checks include Swift syntax parsing, SVG XML parsing, SVG preview rasterization, JSON parsing, symbol-ID inventory, and ZIP integrity. These do not replace macOS SDK type-check/build/XCTest or native visual review.

Before acceptance, run exact-head hosted macOS Debug/XCTest/Release and static-analysis workflows, then verify on a supported Mac: Dark/Light, toolbar/sidebar behavior, window resizing, focus, Full Keyboard Access, VoiceOver, Increase Contrast, Reduce Transparency, icon rendering, Arabic RTL, and mixed-direction financial content.

The asset package remains Proposed until Design Authority review and native qualification are recorded.

## 11. Official Apple references

- https://developer.apple.com/design/human-interface-guidelines/designing-for-macos
- https://developer.apple.com/design/human-interface-guidelines/accessibility
- https://developer.apple.com/design/human-interface-guidelines/toolbars
- https://developer.apple.com/documentation/swiftui/applying-liquid-glass-to-custom-views
- https://developer.apple.com/documentation/TechnologyOverviews/adopting-liquid-glass

The macOS HIG page records a 28 October 2026 update for touch input. Recheck API availability and SDK support during future platform upgrades; visual guidance alone does not establish API availability.
