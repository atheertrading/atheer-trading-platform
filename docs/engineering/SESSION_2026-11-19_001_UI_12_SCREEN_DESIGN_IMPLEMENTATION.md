# Engineering Session 2026-11-19 — Twelve-Screen IPDS Design Package

**Work package:** ATP-UI-IPDS-012  
**Team:** A — UI / Frontend Engineering  
**Branch:** `feat/ui-12-screen-pixel-specs`  
**Base:** PR #89 exact head `7c756390240a05c5570d5e2c200c20c3b2e917e3`

## Sources inspected

- Repository `AGENTS.md`, current SwiftUI source and tests.
- Official TEAM A assignment ATP-TEAM-A-001 in the project Library.
- GitHub Issues #72, #77, #79.
- PR #69 IPDS foundation, #73 screen blueprint, #80 operational status, #85 instrument quick search, #89 native shell.
- Existing design tokens, Command Center, Markets, operational status strip and workspace engine.
- Library `ATHEER Trading Pro Showcase.zip`; composite references are inspiration only and their financial examples are excluded.

## Implementation

- Added twelve screen-specific Dark / English / Balanced SVG design compositions, each with a 1440 × 900 pt logical viewBox and 2880 × 1800 px 2× export.
- Added the measured screen geometry, a proposed IA crosswalk, data-provenance rules and approval/qualification checklist.
- The current application navigation remains limited to implemented destinations; design assets are not inert production routes.
- No broker data, account values, risk values, orders, positions, AI confidence or execution outcomes are fabricated.
- No backend-owned file, API, broker permission, risk limit or trading gate was changed.

## Verification

- Source branch and PR ancestry are preserved.
- SVG XML/render validation, exact-head hosted CI, owner-Mac build/launch, native screenshot comparison, accessibility, Light theme, Arabic RTL, minimum-window and multi-display review remain to be completed.
- No owner/design-authority approval or native pixel-perfect qualification is claimed.

## Integration

Stacked on PR #89; does not merge PR #69/#73/#70 or rewrite their dependency history. Shared continuity/task/status records remain subject to Gate D reconciliation with parallel engineering work.

## Next action

Extract existing native shell dimensions into a shared Swift metrics type, cover them with XCTest, then run exact-head CI and complete native visual qualification.
