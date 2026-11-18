# Engineering Session 053 — Native Supervisor Shutdown Outcome Qualification

**Date:** 2026-11-18  
**Batch:** ATP-2026-11-18-053  
**Repository:** `atheertrading/atheer-trading-platform`  
**Branch:** `fix/backend-supervisor-bounded-shutdown`  
**Code head before this report:** `4a55032511125d98a9cb4861c8ab4173bea42a3e`  
**Pull request:** [#57 — Bounded native backend shutdown](https://github.com/atheertrading/atheer-trading-platform/pull/57)

## 1. Objective

Close the gap where the native supervisor treated every terminated child process as a successful stop, even if the backend reported a failed shutdown or required SIGKILL.

## 2. Implementation

Updated `BackendProcessSupervisor.performStop()` to inspect the child's final `Process.terminationReason` and `terminationStatus` after termination:
- Normal exit status 0 is accepted.
- Non-zero process exit throws `childExitedWithFailure(status)`.
- Signal termination throws `childExitedUncleanly(signal)`; this includes forced SIGKILL.
- The process reference, capability, IPC connection, readiness port and buffered startup output are cleared before a failed termination is surfaced. A second stop remains safe and idempotent.
- `BackendRuntimeViewModel.stop()` already maps supervisor errors to a failed UI state and preserves the diagnostic description.

This makes the backend's non-zero shutdown status meaningful to the native app. It no longer reports success merely because the process disappeared.

## 3. Tests added/updated

- Updated the graceful startup-cancellation test to use a SIGTERM handler that exits with status 0.
- Added a forced-termination test that ignores SIGTERM, verifies escalation to SIGKILL, verifies the unclean-termination error, and verifies supervisor state is cleared.
- Added a non-zero-exit test that exits with status 7 on SIGTERM and verifies the exact failure status is surfaced and supervisor state is cleared.
- Existing capability zeroization, idempotent stop and canonical readiness-port tests remain.

## 4. Safety verification

Verified in `BackendProcessSupervisor.swift` that the supervised child environment explicitly sets:
`CAP_ALLOW_TRADING=false`.

The child still receives its 256-bit IPC startup capability through stdin, not argv or environment. No broker credentials, trading API, or LIVE capability were added.

## 5. Remaining observability limitation

The backend shutdown code in PR #55 emits operation-specific, redacted diagnostics to stderr. The native supervisor currently redirects child stderr to `FileHandle.nullDevice`, so those individual operation labels are not surfaced to the GUI. This PR now surfaces the overall non-zero exit or unclean signal outcome, but a filtered, secret-safe diagnostic channel from child stderr to the app remains a follow-up. Do not claim operation-level shutdown messages are visible in the native UI yet.

## 6. Verification status

- Commit `4a55032511125d98a9cb4861c8ab4173bea42a3e` contains the supervisor outcome handling and added tests.
- Earlier Local Sync Safety run `44288294964` passed on the prior code head `00d8aab12cd4dd1afe21a78ef1007c0c3b143cd4`; it does not qualify the latest test commit.
- Earlier CI run `44288294827` was queued on that prior code head. No final Intel, Apple Silicon, XCTest, or exact-head CI pass is claimed for `4a550325`.
- The branch remains based on PR #56 and diverges from its current head; preserve history and integrate only through the normal PR merge path after latest-head CI.

No owner-Mac Xcode run or local worktree synchronization was performed.
