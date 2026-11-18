# Engineering Session 2026-11-19 — Workspace Lifecycle Deletion

**Work package:** ATP-UI-WORKSPACE-DELETE-001  
**Team:** A — UI / Frontend Engineering  
**Branch:** `feat/ui-workspace-lifecycle-delete`  
**Base:** PR #91 exact head `ea0e1226ec310e5e314e39d1a984fe2bd188336e`

## Objective

Complete the missing workspace deletion lifecycle without coupling saved layout state to broker, market-data or trading-service lifecycle.

## Implementation

- Added `WorkspaceEngine.deleteWorkspace(_:)` with atomic preflight over all profiles that reference the target workspace.
- A workspace is not deleted when it is the last workspace in any referencing profile or the last workspace in the snapshot.
- When the active workspace is deleted, the affected profile selects its first remaining workspace; other profiles retain their existing active workspace when it was not deleted.
- The engine validates the complete candidate snapshot before publishing and persisting it.
- Added a destructive confirmation in Workspace Panel Management, disabled when the profile invariants do not permit deletion.
- The confirmation states that deletion only removes workspace configuration and does not stop broker or market-data services.
- Added isolated XCTest coverage for active selection/persistence, last-workspace rejection, shared profile references and no-partial-mutation behavior.

## Safety

Workspace deletion changes only the versioned workspace snapshot. It does not close windows, stop services, cancel orders, close positions or change trading state.

## Verification

Hosted exact-head CI and owner-Mac workspace interaction checks remain pending.
