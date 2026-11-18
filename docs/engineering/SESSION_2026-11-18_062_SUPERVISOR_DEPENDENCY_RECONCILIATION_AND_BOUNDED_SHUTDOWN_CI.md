# Session 062 — Supervisor Dependency Reconciliation and Bounded Shutdown CI

**Date:** 2026-11-18  
**Workstream:** ATP-ENG-063 / ATP-BRK-002  
**Repository:** `atheertrading/atheer-trading-platform`  
**Branch:** `fix/backend-supervisor-bounded-shutdown`  
**PR:** [#57 — Await bounded backend shutdown before app termination](https://github.com/atheertrading/atheer-trading-platform/pull/57)  
**Parent PR:** [#56 — Resolve backend supervisor Swift compile failures](https://github.com/atheertrading/atheer-trading-platform/pull/56)

## Objective

Integrate the latest supervisor compile-correction branch into bounded shutdown without rewriting history, then obtain an exact-head hosted CI result for the combined implementation.

## Branch ancestry reconciliation

Before this session, PR #57 was 15 commits ahead and 2 behind the current PR #56 head. The base branch reference had moved from the older parent commit `ad7a44092c1d82a08a9304a04be876ccdb2bc44e` to current PR #56 head `493e91b010c5637f37a3bc270c99995da3f6d67d`.

Created two-parent commit:

- Commit: `ed839778b4b86c242b73b2b43c1e0fba10015925`
- First parent: PR #56 head `493e91b010c5637f37a3bc270c99995da3f6d67d`
- Second parent: previous PR #57 head `99f740b74b786d78d375e8415d085882adfe3ca0`
- PR #57 changes preserved across 8 changed paths.
- GitHub compare against the current PR #56 parent reports 16 commits ahead / 0 behind.
- GitHub reports PR #57 mergeable.

No force-push, rebase, reset, or history rewrite was used.

## Implementation carried by the combined branch

The combined branch includes the PR #56 source corrections:

- `ContentView` is explicitly `@MainActor`; its optional injected runtime model is initialized inside the actor-isolated initializer rather than in a default argument expression.
- `BackendProcessSupervisor` resolves its actor-isolated default resolver inside its initializer.
- The process property is explicitly assigned through `self.process`, avoiding the immutable shadowing error.
- `BackendProcessManaging` is class-bound so its mutable termination callback can be safely managed through the protocol reference.

It also retains PR #57's bounded shutdown behavior:

- Wait for graceful SIGTERM exit for up to 25 seconds.
- Escalate to SIGKILL and wait up to 2 additional seconds.
- Treat exit code 0 as successful shutdown.
- Surface non-zero process exit and signal termination as explicit errors.
- Preserve process/capability state when termination cannot be confirmed.
- Keep concurrent stop calls idempotent and prevent a new start from racing a stop task.
- Defer app termination until shutdown succeeds; on shutdown failure, reply to AppKit with termination denied so the application remains available to report the error.

The backend child continues to receive `CAP_ALLOW_TRADING=false`; the per-launch 256-bit capability is delivered through stdin, not argv or the environment.

## Exact-head CI evidence

Workflow run: [44352748432](https://github.com/atheertrading/atheer-trading-platform/actions/runs/44352748432)  
Head: `ed839778b4b86c242b73b2b43c1e0fba10015925`

- Backend Toolchain: **PASSED**.
  - Node.js 24.22.3.
  - API dependency installation completed.
  - TypeScript type-check completed.
  - API test suite: 30 tests passed, 0 failed.
- Repository hygiene: **PASSED**.
- Intel macOS build/test/Swift CodeQL: **QUEUED** at report time.
- Apple Silicon macOS build/test/Swift CodeQL: **QUEUED** at report time.
- Local Sync Safety: separate job was still running at report time.

This verifies backend and repository hygiene for the exact PR #57 head. It does not verify Swift compilation, XCTest, macOS runtime, or local owner-machine behavior.

PR #56's own current-head workflow has backend and repository hygiene passed, but its Intel macOS job remains queued and Apple Silicon was cancelled in that run. PR #57's fresh matrix is the next exact-head native qualification opportunity because it includes the compile correction and bounded shutdown together.

## Source-level review notes

The shutdown implementation was reviewed across `ATHEERTradingProApp.swift`, `BackendRuntimeViewModel.swift`, and `BackendProcessSupervisor.swift`. The expected-stop marker prevents a managed shutdown from being reported as an unexpected child crash. The process termination callback releases its waiter and clears the capability and connection; the normal-stop outcome is then determined from the child's final termination reason/status.

The supervisor continues to redirect child stderr to the null device. Consequently, only the overall shutdown failure reaches the app; operation-specific redacted backend shutdown diagnostics are not yet visible in the native UI. This remains an explicit observability follow-up.

## Safety and verification boundaries

- PR #57 remains draft and unmerged.
- No PR was merged into `main`.
- No broker credentials or provider session were used.
- No DEMO or LIVE order was submitted.
- `CAP_ALLOW_TRADING=false` remains enforced in the supervised child environment.
- No owner-Mac pull, Xcode build, app launch, Keychain restart, visual QA, or broker DEMO authentication is claimed.

## Next action

Complete Intel and Apple Silicon build/XCTest on exact PR #57 head `ed839778b4b86c242b73b2b43c1e0fba10015925`. Resolve any compiler or test failure against the combined branch, rerun exact-head CI, then qualify PR #56 and the dependent PR #55 → #64 → #66 → #67 → #68 → #70 branch stack.
