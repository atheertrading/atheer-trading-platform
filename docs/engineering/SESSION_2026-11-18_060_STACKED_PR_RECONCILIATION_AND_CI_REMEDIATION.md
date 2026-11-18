# Session 060 — Stacked PR Reconciliation and CI Regression Remediation

**Date:** 2026-11-18  
**Workstream:** ATP-ENG-061 / ATP-CHART-003  
**Repository:** `atheertrading/atheer-trading-platform`  
**Branch:** `feat/authenticated-chart-workspace-2026-11-18`  
**Prior session:** SESSION_2026-11-18_059_AUTHENTICATED_CHART_WORKSPACE.md

## Objective

Reconcile the authenticated broker, live quote, cached freshness, historical market-data and chart-workspace pull-request stack without rewriting Git history. Diagnose exact-head CI failures, correct test fixtures/expectations, and preserve DEMO/read-only execution boundaries.

## CI failure diagnosis and corrections

1. The inherited `BackendBrokerAuthenticationServiceTests` URLProtocol fixture assumed URLSession always surfaced outgoing request data through `URLRequest.httpBody`. The GitHub macOS runner surfaced it through `httpBodyStream`. The fixture now captures either representation, reads the stream with a bounded three-read loop, and preserves the 8 KiB cap.
2. `UnixDomainSocketBrokerCredentialIPCClientTests` expected an outdated error description. The production message includes the security-specific word "private"; the assertion now matches the implemented contract.
3. Backend historical normalization and native chart decoding independently reject candle timestamps later than receipt timestamps, with deterministic regression coverage.

Test-only changes were propagated through PR #55, #64, #66, #67, #68 and #70 where applicable. No production credential transport, broker authority, or order execution behavior was weakened.

## Stacked branch ancestry reconciliation

Two-parent merge commits were created top-down. Each child feature history remains a parent; no force-push or history rewrite was performed.

| PR | Parent head | Prior child head | Merge commit |
|---|---|---|---|
| #64 | #55 `0849f2318c6b6a0eed261997043da69daec4884f` | `98197bf524a0e1e6bebae64f419da73b7b13dc25` | `1a49ea48c3497c30c68557013c749c8d8be7bbe6` |
| #66 | #64 `1a49ea48c3497c30c68557013c749c8d8be7bbe6` | `98ce9d5c8808446c7db597f8ad012a079d3eeae3` | `46d9d7bd6ad5c247c04cf6645f0a548e53582ae1` |
| #67 | #66 `46d9d7bd6ad5c247c04cf6645f0a548e53582ae1` | `8ff12c3ac0d2ca89991d651639e4d8a8af6c6e63` | `1abf1dafb17d346b903fe69a053976bd359b9245` |
| #68 | #67 `1abf1dafb17d346b903fe69a053976bd359b9245` | `407de768925e171770825a7917fd41beb7b2eb1b` | `96df364562b3af4a123f41b440ad0c7f525a6566` |
| #70 | #68 `96df364562b3af4a123f41b440ad0c7f525a6566` | `76de3a0db94396d0bc85bd09a2011f97bf7d115b` | `458d36b92b3c6769e8c8fda6d7ebdcb4668841d2` |

At the last ancestry verification, GitHub reported each PR #64/#66/#67/#68/#70 as 0 commits behind its base and mergeable. PR #55 remains stacked on the supervisor compile-fix branch.

## Exact-head CI status at report time

- PR #55: Repository Hygiene and Local Sync Safety passed; Backend Toolchain and Intel macOS job in progress; Apple Silicon queued.
- PR #64: Repository Hygiene and Local Sync Safety passed; Backend Toolchain and Intel macOS job in progress; Apple Silicon queued.
- PR #66: Repository Hygiene and Local Sync Safety passed; Backend Toolchain in progress; Intel and Apple Silicon queued.
- PR #67: Repository Hygiene, Mermaid rendering and Local Sync Safety passed; Backend Toolchain in progress; Intel and Apple Silicon queued.
- PR #68: Repository Hygiene, Mermaid rendering and Local Sync Safety passed; Backend Toolchain in progress; Intel and Apple Silicon queued.
- PR #70: Repository Hygiene, Mermaid rendering and Local Sync Safety passed; Backend Toolchain in progress; Intel and Apple Silicon queued.

These are in-progress/queued checks, not passing qualification. Earlier failed test runs remain historical failures; only the new exact-head runs can qualify the corrected code.

## Verification boundaries and safety

- No PR was merged into `main`.
- No broker credentials, provider session, DEMO order, LIVE order, or production dealing action was used.
- `CAP_ALLOW_TRADING=false` remains unchanged.
- No local Mac Terminal/Xcode session is connected in this chat. Local pull, Xcode build, owner-Mac runtime, Keychain restart and authenticated Capital.com DEMO verification are not claimed.
- The chart remains historical DEMO/read-only and is not connected to RiskEngine, OMS or Execution Gateway.

## Next action

Allow exact-head CI to finish. Resolve any newly exposed failures at their owning dependency branch, propagate the corrected parent head top-down, then merge only after all required checks and code review are green. After integration, perform owner-Mac pull/build and authenticated DEMO qualification before considering further trading-system capabilities.
