# ATHEER IPDS Asset Package

**Status:** Proposed / review candidate  
**Specification:** docs/design/IPDS_ASSET_PACKAGE_V1.md

## Contents

- brand/atheer-mark-primary.svg — geometric mark source.
- brand/atheer-wordmark-horizontal.svg — horizontal wordmark source.
- brand/atheer-app-icon-master.svg — full-bleed app-icon vector master; platform masking/export remains pending.
- icons/atheer-ui-symbols.svg — visible supplemental SVG symbol atlas with reusable symbol definitions.

Native macOS controls should use SF Symbols wherever a suitable system symbol exists. SVG files are editable identity/design assets, not an instruction to replace native toolbar or navigation icons.

## Token manifests

- tokens/ipds-colors.json — primitive and semantic Dark/Light color tokens, including unresolved turquoise provenance.
- tokens/ipds-typography.json — type roles and financial-number rules.
- tokens/ipds-geometry.json — spacing, radii, strokes, control targets, button heights, and motion values.

The Swift source in the application target remains the runtime token implementation. These JSON files are handoff manifests and must be reconciled with Swift tokens during review.
