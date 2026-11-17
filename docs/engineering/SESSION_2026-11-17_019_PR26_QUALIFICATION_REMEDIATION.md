# ATP-2026-11-17-019 — PR #26 Qualification Remediation

## Objective
Resolve the qualification defects reported by the owner's macOS 13.7.8 / Xcode 14.3.1 / Swift 5.8.1 workstation before adding functionality or advancing PR #26.

## Baseline
- PR: [#26](https://github.com/atheertrading/atheer-trading-platform/pull/26)
- Branch: `feat/broker-management-keychain-demo`
- Initial remediation head: `a1c6c471a0a9a7cfc82a9a30299e7bbdffa9cfb9`
- Follow-up test-harness head: `9559dc30539a41d2e2319bc45bd05466bf721804`
- PR state: Open / Draft; base remains PR #25 head.
- Initial owner-Mac evidence: project generation succeeded; Debug compilation succeeded after the MainActor correction; the original XCTest run reported a single Capital.com request-body assertion failure. Release and app launch did not execute because the command sequence stopped at `make test` failure.
- The subsequent request-body capture patch introduced a compile-time mismatch: the URLProtocol handler still called the old one-argument recorder API after `RequestRecorder.append` changed to require `body:`.

## GitHub defect reports
| Issue | Priority | Scope | State |
|---|---|---|---|
| [#27](https://github.com/atheertrading/atheer-trading-platform/issues/27) | P0 | Capture URLSession request body reliably in authentication contract test | Open |
| [#28](https://github.com/atheertrading/atheer-trading-platform/issues/28) | P1 | Investigate and resolve Swift 5.8 URLSession Sendable diagnostics | Open |
| [#29](https://github.com/atheertrading/atheer-trading-platform/issues/29) | P1 | Reproduce and isolate Brokers screen UI freeze | Open |

## Workstream sequence

### 1. Request-body test harness correction — IN PROGRESS
- Capture request and body bytes at the URLProtocol interception boundary, supporting both `httpBody` and `httpBodyStream`.
- Keep body data in test memory only; do not log credential values.
- Assert `identifier`, `password`, and `encryptedPassword == false` from decoded JSON.
- The owner-Mac run at `9559dc30539a41d2e2319bc45bd05466bf721804` confirmed the app Debug target builds, but XCTest compilation fails because the handler retained `recorder.append(request)` after the recorder signature changed.
- Correction: remove the redundant recorder append from the response handler. `StubURLProtocol.requestObserver` is the single recording boundary and records each intercepted request exactly once, including the captured body.
- Re-run focused authentication tests and the full suite on the corrected exact head; no passing result is claimed yet.

### 2. Capital.com authentication contract requalification — PENDING
- Run focused `CapitalComAuthenticationTests`.
- Run complete macOS XCTest suite.
- Confirm unauthorized-response redaction and LIVE rejection remain green.
- Mocked URLProtocol tests do not prove real provider authentication.

### 3. Swift concurrency diagnostics — OPEN / PENDING
- Reproduce diagnostics on Swift 5.8.1 and hosted macOS.
- Review URLSession async API actor/sendability boundaries.
- Avoid global warning suppression, broad unchecked Sendable conformances, or weakened concurrency settings.

### 4. Brokers runtime freeze — OPEN / PENDING
- Reproduce on owner workstation.
- Trace ViewModel task ownership, periodic polling, request cancellation, view disappearance, and isWorking state transitions.
- Separate Capital.com REST waits from local intermediary/backend health failures.
- Keep SwiftUI navigation responsive while requests are pending or cancelled.

### 5. Full qualification — BLOCKED
- Exact-head Intel and Apple Silicon Debug, XCTest, Release.
- Owner workstation Debug, XCTest, Release, app launch, navigation and cancellation QA.
- Keychain persistence/restart checks and sanitized DEMO session evidence remain separate acceptance requirements.

## Source correction
The URLProtocol test harness records a `RecordedRequest` containing the intercepted `URLRequest` and captured body bytes. `StubURLProtocol` supports both in-memory `httpBody` and streamed `httpBodyStream` content. The response handler now only supplies mocked responses; it no longer records requests a second time or calls the obsolete recorder signature.

**Verification status:** correction prepared for commit; no compile, XCTest, Release, or runtime result is claimed until exact-head CI and owner-Mac execution complete.

## Safety and scope
- No production authentication behavior changed in this correction.
- No credentials or session tokens are logged or persisted by the test harness.
- LIVE remains disabled; no dealing endpoints or trading permission changes.
- No changes to PR #24 or PR #25.
- PR #26 remains Open / Draft and must not be merged as part of this remediation.
