# Engineering Session 051 — Bounded Backend Shutdown and Architecture Review

**Date:** 2026-11-18  
**Batch:** ATP-2026-11-18-051  
**Repository:** `atheertrading/atheer-trading-platform`  
**Branch:** `feat/capital-demo-session-streaming-ipc`  
**Code head before this report:** `fe8a92dad23289901e11c81bbcaf8fdd901b3e09`  
**Pull request:** [#55 — Centralized Capital.com DEMO broker-session IPC integration](https://github.com/atheertrading/atheer-trading-platform/pull/55)

## 1. Objective

Resolve the P1 backend shutdown observability and deadline finding from the PR #55 engineering review; inspect the owner-provided Mermaid source catalogue; preserve the broker/session and trading safety boundaries; and revalidate the dependent native supervisor compile correction.

## 2. Implementation — backend shutdown

Added:
- `services/api/src/shutdown.ts`: reusable bounded shutdown-step runner with positive timeout validation, explicit success/failure/timeout outcomes, and redacted diagnostics.
- `services/api/test/shutdown.test.mjs`: deterministic tests for successful completion, rejected cleanup, timeout behavior, and secret-free diagnostics.

Updated:
- `services/api/src/main.ts`: shutdown now disables the IPC capability, stops accepting new HTTP requests, closes active HTTP connections, then attempts stream disconnect, broker logout, and HTTP server closure in bounded sequence.
- Stream and broker cleanup each have a 7-second deadline; HTTP closure has a 4-second deadline; the child process has a 20-second hard shutdown deadline, below the native supervisor's 25-second graceful window.
- Cleanup failures set a non-zero process exit code. The hard deadline emits a fixed redacted diagnostic and terminates the child rather than leaving it indefinitely alive.
- `services/api/types/node-builtins.d.ts`: declares the explicit process exit contract used by the hard deadline.

No raw provider exception, credential, account identifier, or session token is included in shutdown diagnostics. A timed-out cleanup promise may still be in flight until the hard process deadline; the supervisor remains responsible for confirming child termination.

## 3. Library architecture review — ATP-MER-001

Materialized and read `Codex.zip` from the ChatGPT Library and inspected:
- `03_SYSTEM_ARCHITECTURE/MERMAID_DIAGRAM_CATALOGUE.md`
- `DIAGRAMS/system-context.mmd`
- `DIAGRAMS/target-trading-boundaries.mmd`
- `DIAGRAMS/market-data-pipeline.mmd`
- `DIAGRAMS/ai-order-boundary.mmd`
- `DIAGRAMS/backtest-pipeline.mmd`

The catalogue is accepted as architecture guidance, but each diagram is explicitly marked as proposed/target-only and syntax validation is pending. None is evidence that its target services are deployed.

Architecture constraints carried into implementation:
- Human, strategy, and authorized AI sources converge on typed order intent, backend validation, centralized RiskEngine, OMS, exclusive Execution Gateway authority, broker confirmation, and reconciliation.
- AI receives proposal/intake authority only; it has no direct dealing authority.
- Market data must preserve provenance and timestamps, validate completeness/sequence, and prevent stale or invalid observations from entering automated decisions.
- Backtests require historical-data provenance, quality/bias checks, versioned strategies, explicit execution/fill assumptions, and realistic costs; results are not profit guarantees.
- Persistence and broker integration shown in the context diagram remain target components until independently implemented and verified.

The owner-provided architecture in this conversation remains consistent with these boundaries. No order placement, dealing API, RiskEngine bypass, or LIVE capability was introduced.

## 4. Security finding still blocks merge

The current native credential handoff sends the API key, login identifier, and API-key password in an authenticated HTTP request to `127.0.0.1`.

The per-process 256-bit bearer capability authenticates the caller; it does **not** encrypt the HTTP payload. Loopback binding prevents remote network exposure but is not a confidentiality mechanism against a privileged or otherwise capable local observer.

This finding is not closed by the shutdown work. Do not describe the current credential handoff as fully confidentiality-protected and do not merge the broker stack as security-qualified until either:
1. credential handoff is moved to a private local IPC channel with restrictive peer/file controls (for example, private stdio RPC or a protected Unix-domain socket); or
2. an explicit, documented same-host threat boundary is accepted by the appropriate authority.

The preferred engineering direction is to keep the existing authenticated HTTP API for non-secret local control/market-data traffic and move credential payload transfer to a private process channel. That transport change is a separate security work package.

## 5. PR #57 native supervisor compile remediation

PR #57 previously failed both macOS architecture builds because its bounded-shutdown branch had not incorporated the two Swift corrections from PR #56:
- `BackendProcessManaging` must be class-bound (`AnyObject`) so the termination callback can be mutated through the protocol reference.
- `BackendRuntimeViewModel.supervisor` must be mutable to install that callback.

Applied both corrections on `fix/backend-supervisor-bounded-shutdown` in commit `b1dcda177cf0ff2330a85a09f8f41040392e625c`. Local Sync Safety run `44286395589` passed. Exact-head CI run `44286395905` was queued at last inspection; no macOS build/XCTest pass is claimed.

The PR #57 branch still diverges from PR #56's head (merge base `ad7a44092c1d82a08a9304a04be876ccdb2bc44e`; 8 commits ahead / 2 behind after the correction). Preserve ancestry and integrate only through the normal child-to-parent PR process after exact-head CI.

## 6. Verification status

For PR #55 code head `fe8a92dad23289901e11c81bbcaf8fdd901b3e09`:
- Local Sync Safety run `44286676412`: in progress at last inspection.
- CI run `44286676363`: queued at last inspection.
- Backend type-check had completed successfully; API tests were running; Intel and Apple Silicon jobs were queued.
- The new shutdown tests are part of the backend test command but are not yet reported as passed.
- No exact-head backend test, Intel/Apple Silicon build, XCTest, Release, or CodeQL pass is claimed.

No owner-Mac terminal/Xcode access, local worktree synchronization, Keychain restart qualification, visual/accessibility QA, or real Capital.com DEMO authentication was performed in this batch.

## 7. Current integration and safety gates

- PR #55 remains open and unmerged, based on PR #56's Swift compile branch.
- PR #57 remains open and unmerged; its bounded native process shutdown must be qualified and integrated into the parent stack.
- PR #58 remains a draft live-quote UI branch stacked on an earlier PR #55 head; its ancestry must be reconciled after the parent stack changes.
- PR #51/#52/#53/#54/#56/#55/#57 form a dependency-sensitive authenticated backend stack. Merge upward only after exact-head qualification and ancestry review.
- Credential confidentiality remains unresolved as described above.
- `CAP_ALLOW_TRADING=false`; LIVE authentication, dealing, and order execution remain disabled.
