# ATP-2026-11-17-020 — PR #26 Owner-Mac Qualification and AppKit/Concurrency Remediation

## Objective
Use the owner-supplied terminal evidence titled **The terminal on Hossam's Mac - 02** to qualify PR #26, remediate the four Swift 5.8 URLSession Sendable warnings and the AppKit table reentrancy path, and publish traceable status without changing broker permissions or trading scope.

## Source and baseline
- Repository: [atheertrading/atheer-trading-platform](https://github.com/atheertrading/atheer-trading-platform)
- PR: [#26 — secure Capital.com DEMO management](https://github.com/atheertrading/atheer-trading-platform/pull/26)
- Branch: `feat/broker-management-keychain-demo`
- Baseline HEAD: `0e7f25edb65e6a6a41b86b6f4513231d36edf79e`
- Baseline parent: `913a00fc04e2662b41806d0a7eed9bdca9c83dcc`
- PR state at inspection: Open / Draft; base remains PR #25 head `bdcdab3592347473ff9ec0ca0a9d4f99d6eccc5b`.
- Owner evidence: uploaded RTF **The terminal on Hossam's Mac - 02.rtf**, 595 lines. The local Git output explicitly reports HEAD `0e7f25edb65e6a6a41b86b6f4513231d36edf79e` and a clean branch tracking origin before qualification.

## Verified owner-Mac results at baseline HEAD
Environment:
- macOS 13.7.8
- Xcode 14.3.1 / Swift 5.8.1
- XcodeGen 2.36.1
- Intel `x86_64` workstation

Results:
- `make generate`: passed.
- `make build` Debug: passed.
- `make test`: passed; XCTest executed 35 tests, 0 failures (32 app tests + 3 Capital.com authentication tests).
- `CONFIGURATION=Release bash scripts/build-macos.sh`: passed.
- `make app-run`: launch was requested for the Debug app. The report does not prove the window was presented, visually inspected, or interacted with.
- The Release build log explicitly shows `CreateUniversalBinary ... arm64 x86_64` and `lipo -create`; this proves both slices were emitted by that build on the Intel host. It is not Apple Silicon runtime qualification.

## Observed runtime diagnostics
1. Four targeted-concurrency warnings at `BrokerManagementServices.swift` lines 318, 336, 378, and 414. All identify the optional non-Sendable `URLSessionTaskDelegate` argument crossing from the MainActor call site into `URLSession.data(for:delegate:)`.
2. AppKit warning: `Application performed a reentrant operation in its NSTableView delegate`. The inspected SwiftUI source contains a List-backed panel manager whose row callbacks synchronously mutate the same observable workspace model backing that List. This is the identified reentrant mutation path; runtime reproduction after correction is still required.
3. A window-ordering warning occurred while the XCTest-launched app was not the active application. Treat as test-host activation context unless reproduced in normal user launch.
4. Backend health request to `127.0.0.1:4100/health/live` failed with connection refused. The backend process was not listening at test time; this is not an XCTest failure.

## Baseline hosted CI at the exact SHA
- Local Sync Safety run [#319 / 44149500897](https://github.com/atheertrading/atheer-trading-platform/actions/runs/44149500897): passed.
- CI run [#222 / 44149501164](https://github.com/atheertrading/atheer-trading-platform/actions/runs/44149501164): Repository Hygiene passed; Backend Toolchain passed; Intel x86_64 macOS job cancelled; Apple Silicon arm64 macOS job cancelled. Therefore no hosted macOS build/XCTest/Release pass is claimed for this SHA.

## Remediation in this increment
### URLSession concurrency boundary
- Added a narrow `URLSessionRequestExecutor` transport wrapper, isolated from MainActor.
- The wrapper owns one immutable URLSession reference; URLSession is thread-safe. Its request method explicitly supplies `delegate: nil` from the non-UI transport context.
- The authentication service continues to own CST/security-token state on MainActor. The wrapper does not store credentials, tokens, or account state.
- This is a narrowly scoped unchecked-Sendable boundary, not a global warning suppression or broad conformance.

### AppKit table reentrancy
- Panel manager List row actions (add, remove, reorder, visibility toggle) now defer WorkspaceEngine mutations by one MainActor task yield.
- This prevents synchronous mutation of the List's backing observable data while AppKit is executing its NSTableView delegate callback.
- No workspace model, ordering rule, persistence contract, or user-visible capability was removed.

## Verification status after remediation
- Source changes are prepared for exact-head hosted CI.
- No post-change compile, XCTest, Release, Intel runtime, Apple Silicon runtime, or owner-Mac visual result is claimed until the new commit's checks and workstation rerun complete.
- The earlier 35/35 XCTest result remains valid only for baseline SHA `0e7f25e`, not for the remediation commit.
- Backend connection, normal application activation, and the UI warning require owner-side rerun with the backend process started.
- Keychain real-device save/read/delete across app restart remains outstanding. Existing mocked credential-store tests do not establish real Keychain restart persistence.

## Remaining qualification gates
1. Exact-head CI: Intel and Apple Silicon Debug, XCTest, Release, and Swift CodeQL.
2. Owner Intel runtime/visual QA: open app, navigate Settings → Brokers, exercise workspace panel add/remove/reorder/visibility controls, check console for NSTableView reentrancy, verify responsive UI during authentication and cancellation.
3. Start local backend per repository instructions, then verify app liveness/readiness states and no connection-refused diagnostic.
4. Real Keychain integration: save DEMO credentials locally, quit/relaunch app, confirm credentials are present without revealing values, edit, selectively delete, relaunch and confirm deletion. Do not paste credentials into terminal output or reports.
5. Apple Silicon runtime qualification on physical/available arm64 Mac. A universal binary slice alone is insufficient.
6. Real Capital.com DEMO authentication is a separate owner-authorized credential test; no provider session is claimed here.

## Security and scope invariants
- Capital.com DEMO only. LIVE authentication remains rejected.
- No order, position-dealing, account-mutation, or LIVE endpoint was added.
- No broker trading permission, RiskEngine policy, execution gate, or risk limit was changed.
- No credential or session token is included in this report.
- PR #26 remains Open / Draft. PR #24 and PR #25 remain untouched and unmerged.

## Next action
Run exact-head CI, then have the owner rerun the bounded Intel workstation sequence with backend health process active and provide sanitized runtime/Keychain observations.
