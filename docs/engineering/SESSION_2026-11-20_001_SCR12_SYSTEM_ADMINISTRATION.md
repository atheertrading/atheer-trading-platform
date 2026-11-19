# Engineering Session 2026-11-20 — SCR-12 System & Administration

**Work package:** ATP-UI-SCR-12-001  
**Team:** A — UI / Frontend Engineering  
**Branch:** feat/ui-system-administration-screen  
**Parent:** PR #92 head ad8a64b7031f79d35a132c766a7bb9d194634682  
**Base branch:** feat/ui-workspace-lifecycle-delete

## Objective

Translate the approved IPDS direction for SCR-12 into a native SwiftUI screen using only verified UI-facing contracts and existing semantic design tokens.

## Implementation

- Replace the prior Settings-only destination content with an adaptive System & Administration composition.
- Bring API Connection and System & Administration under the SYSTEM navigation group without exposing unimplemented product destinations.
- Reuse existing theme persistence and backend health / market-data status contracts.
- Add a pure presentation projection and deterministic unit tests for unknown, unavailable, not-ready and contradictory authorization states.
- Make unavailable audit and permission capabilities explicit rather than inventing content or controls.

## Source and integration boundaries

- UI-only. No backend-owned code or API schema is changed.
- No broker-dealing operations, order controls, risk mutations or LIVE capability are added.
- The PR is a child of the existing Team A workspace lifecycle branch to preserve dependency ancestry.
- ContentView.swift overlaps the independent chart/market stack (#70/#83); shared-file integration remains a separate history-preserving review gate.

## Verification

- Source-level requirements and deterministic tests are included in the branch.
- Exact-head hosted CI status must be recorded after the PR is opened.
- Owner-Mac Xcode build/test, launch, native screenshot comparison, Light appearance, Arabic RTL, VoiceOver, keyboard/focus and multi-display checks are not claimed until executed.
- Design direction approval does not by itself establish native pixel-perfect or production qualification.

## Next action

Complete exact-head GitHub Actions qualification, address any compiler/test failures, then submit the branch as a Draft PR stacked on PR #92. Keep all unresolved native visual/accessibility and cross-stack integration gates visible.
