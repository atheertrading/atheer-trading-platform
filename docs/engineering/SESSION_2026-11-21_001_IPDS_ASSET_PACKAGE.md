# Engineering Session 2026-11-21 — IPDS Reusable Visual Asset Package

**Work package:** ATP-IPDS-ASSET-001  
**Team:** A — UI / Frontend Engineering  
**Branch:** feat/ipds-visual-asset-package  
**Parent:** PR #93 head 6cfc3dcf27d26127be8c952899f9637ba33546e1  
**Status:** Proposed implementation increment; exact-head qualification pending

## Objective

Create reusable brand SVGs, semantic design tokens, SwiftUI component primitives, component documentation, and deterministic token/geometry tests while preserving the existing macOS 13 deployment target and IPDS compatibility.

## Repository discovery

- Reviewed root AGENTS.md and the current PR #93 exact head.
- Inspected docs/design/IPDS_V1_FOUNDATION.md and current ATHEERDesignTokens.swift on the PR #93 ancestry.
- Confirmed the XcodeGen project remains macOS 13.0 / Swift 5 and discovers source files from Sources.
- Confirmed the current IPDS source still records the unresolved #40E0D0 versus #00CEC8 brand-turquoise conflict.

## Implementation

- Extended the existing token source without removing legacy role names or metrics.
- Added a geometric SwiftUI mark and brand lockup aligned with the SVG path.
- Added a native-style semantic button wrapper, native switch preference row, and read-only status badge.
- Added vector brand mark, wordmark, full-bleed app-icon master, and ten-symbol atlas.
- Added portable JSON manifests for color, typography, and geometry tokens.
- Added deterministic XCTest coverage and the reusable IPDS asset specification.
- Added 2× PNG previews to the delivery archive; editable SVG remains the source.

## Compatibility and safety

- Keep macOS 13.0 deployment target; no unguarded Liquid Glass API.
- Prefer native SwiftUI controls and SF Symbols for live application interaction.
- The app-icon master is not integrated into the Xcode asset catalog.
- No broker, backend, authentication, risk, OMS, execution, or LIVE behavior is modified.
- No sample financial data or synthetic operational states are introduced.
- The turquoise source conflict is preserved as unresolved; current implementation #00CEC8 remains in code.

## Verification status

- swiftc -frontend -parse completed without syntax diagnostics for all package Swift source and tests. This is syntax parsing only; it does not type-check against the macOS SDK.
- All four SVG files parsed as XML and rasterized successfully to 2× PNG previews.
- All three JSON token manifests parsed successfully; ten symbol definitions and ten atlas uses were verified.
- ZIP integrity and expected package file inventory passed.
- Exact-head hosted CI, Xcode build/XCTest, Swift static analysis, and owner-Mac visual/accessibility qualification remain pending.
- No production readiness or visual approval is claimed.

## Remaining gates

1. Resolve the brand-turquoise conflict through Design Authority.
2. Review the SVG geometry and wordmark with the owner/design authority.
3. Verify native focus behavior, keyboard navigation, and VoiceOver on a supported Mac.
4. Validate Dark/Light, Increase Contrast, Reduce Transparency, Arabic RTL, and window sizes.
5. Export and qualify the app icon separately before asset-catalog integration.
