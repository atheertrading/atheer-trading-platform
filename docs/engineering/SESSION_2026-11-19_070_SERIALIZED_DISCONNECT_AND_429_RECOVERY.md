# Engineering Session 070 — Serialized Broker Disconnect and REST Rate-Limit Recovery

**Date:** 2026-11-19  
**Assignment:** ATP-TEAM-B-001  
**Workstream:** Team B — Backend Engineering  
**PR:** #66 — private Unix-domain broker credential IPC  
**Branch:** `fix/broker-credential-unix-domain-ipc`  
**Final implementation/test head:** `7689188b649b037c795642e9c0d86af4579303ee`

## Objective

Close a concurrency gap found during the exact-source review of PR #66, implement the documented Capital.com 429 recovery policy in the shared REST client, and preserve the broker's fail-closed/read-only DEMO boundary.

## 1. Broker-session disconnect serialization

### Finding

The IPC `disconnect` handler previously awaited the market-data stream teardown callback before entering `BrokerSessionManager.disconnect()`. The session manager serializes its own transitions, but this callback was outside that queue.

A concurrent credential `connect` could therefore enter the manager queue after the stream teardown began but before the disconnect transition. The replacement session could be created, after which the original disconnect operation could release that newly created session. This was a real ordering defect, not a hypothetical API concern.

### Correction

- `BrokerSessionManager.disconnect(beforeSessionReplacement?)` now executes the optional stream-teardown callback inside the same serialized transition queue as the broker-session release.
- The UDS `disconnect` action passes its stream callback into the manager operation rather than invoking it beforehand.
- The IPC callback records stream-shutdown failure but still allows broker-session release to proceed, preserving the previous fail-safe cleanup behavior and returning a sanitized failure result.
- Added a lifecycle regression test that holds stream teardown open while a replacement connect is queued. It proves that the old session is disconnected before the replacement runtime is created and authenticated.
- Updated IPC test doubles to invoke the serialized callback, preserving the asserted stream-before-broker teardown order.

Changed files:
- `services/api/src/market-data/broker-session-manager.ts`
- `services/api/src/security/broker-credential-ipc.ts`
- `services/api/test/broker-session-manager-lifecycle.test.mjs`
- `services/api/test/broker-credential-ipc.test.mjs`

## 2. Capital.com REST 429 recovery

### Existing control

The REST client already has a single process-wide request-start queue at 100 ms spacing (10 requests/second), and the broker-session manager retains one shared client across runtime/account replacement. Session creation is separately throttled to one attempt per second.

### Correction

The shared REST request path now:

- Detects HTTP 429 only; transport timeouts and other uncertain failures are not automatically retried.
- Honors numeric-seconds and HTTP-date `Retry-After` values, bounded to 60 seconds.
- Uses bounded exponential full jitter when `Retry-After` is absent or invalid.
- Allows at most three retries per request.
- Publishes a process-wide cooldown through the existing request queue so other REST calls observe the same rate-limit pause.
- Applies an independent 10-second timeout to each actual network attempt; the provider-directed wait does not consume that per-attempt network timeout.
- Keeps provider response bodies out of diagnostics.

Added `services/api/test/capital-demo-client-rate-limit.test.mjs` for numeric and HTTP-date headers, deterministic jitter, retry exhaustion, no retry for HTTP 503, and per-attempt timeout-signal coverage.

No dealing method exists in this adapter. This retry behavior must not be reused for future order submission without an independently specified idempotency, broker-acknowledgement, and reconciliation contract.

## 3. Library source reconciliation

Reviewed the five ATP-MER-001 Mermaid sources and their catalogue in `Codex.zip`:

- System context shows the native macOS client, target ATHEER services, broker API and target persistence boundary.
- The proposed trading boundary is **Order Intent → Backend Validation → Central RiskEngine → OMS durable authorization → Execution Gateway → Broker → Confirmation → Reconciliation → Verified account state**.
- Market-data flow separates connection lifecycle, raw observations, normalization/timestamps, sequence/completeness validation, freshness, and distribution.
- AI has a typed intent-proposal boundary and no direct broker-dealing authority.
- Backtesting is a provenance/quality-controlled evaluation path with explicit execution assumptions and costs.

The catalogue labels these diagrams as proposed/target architecture; none is evidence of deployed services. The GitHub Mermaid action verifies the repository's diagram set separately.

Reviewed the source Q&A:
- Q8 distinguishes REST session expiration, authentication rejection, network timeout and WebSocket-only disconnection; in particular, a WebSocket interruption does not by itself prove REST-session termination, and network timeout leaves session status unconfirmed.
- Q9 specifies centralized endpoint-aware rate limiting, 429 handling, Retry-After, exponential jitter, preserving correlation/idempotency identity, and no blind retry of uncertain order submissions.

## 4. Verification

### Backend result at code head `dfc30ef70b2242166d9269cb4dd9e850b80df288`

- TypeScript type-check: passed.
- TypeScript build: passed as part of `npm test`.
- Full API test command: passed.
- Repository Hygiene: passed.
- Local Sync Safety: passed.
- Intel x86_64 and Apple Silicon arm64: still in progress at last inspection.

This code head included the serialized disconnect race correction and the 429 retry policy after the numeric Retry-After parser correction. The immediately earlier head `650add5019bbeebadc7da14cc6d1f03f9f7b6169` had one failed numeric-header assertion; that run is not carried forward as a pass.

### Later transport and final-cooldown corrections

A final diff review found the per-attempt timeout signal had been removed from the shared transport call while redundant caller signals were being cleaned up. The signal was restored at the shared fetch boundary and the callers' duplicate timeout signals removed. A deterministic regression assertion verifies that retry attempts receive separate active AbortSignals.

A further rate-limit review found that an exhausted final HTTP 429 returned before publishing its Retry-After value to the shared process cooldown. The client now records the cooldown for every HTTP 429, including the final response after the three-retry budget is exhausted. A subsequent request therefore still waits for the provider-directed delay. Added deterministic coverage that sends four consecutive 429 responses, then verifies the next request waits the full five-second Retry-After. The non-retry contract now also explicitly tests a thrown network failure in addition to HTTP 503.

The final implementation/test head is `7689188b649b037c795642e9c0d86af4579303ee`. Exact-head CI has not yet been observed for this final head; no pass is claimed until Backend Toolchain, Repository Hygiene, Intel and Apple Silicon results are inspected.

## 5. Security and trading constraints

- Broker credentials and provider session tokens remain in the backend and private UDS transport.
- Credential connect/disconnect is not exposed through HTTP.
- Session transitions remain serialized; accepted authenticated IPC requests are drained before provider teardown.
- HTTP broker-sensitive routes continue to require the per-process capability and native request context.
- Broker market data remains Capital.com DEMO and read-only.
- No order/dealing endpoint, OMS, Execution Gateway, or LIVE path is introduced by this batch.
- `CAP_ALLOW_TRADING=false` remains enforced.
- No real broker credentials, accounts, orders or execution events were used by these synthetic tests.

## 6. Remaining qualification and integration gates

1. Inspect the exact-head CI for `dfd0bf238dec3d88e061367251954fc860dffbb4`: Backend, Repository Hygiene, Intel and Apple Silicon.
2. Keep PR #66 Draft until exact-head CI completes and cross-workstream review/dependency requirements are met.
3. PR #66 remains stacked on PR #64 and contains macOS-owned UDS/supervisor changes. Team B has changed only backend-owned `services/api/**` and backend documentation in this continuation.
4. Reconcile #64 → #66 with the separate IPDS/UI stack and ATP-ENG-063 (#77) before any merge.
5. Owner-Mac verification, Keychain persistence/restart, private socket lifecycle on Darwin, authenticated real Capital.com DEMO session, and live provider quote qualification remain unverified.
6. Do not progress to broker dealing until the canonical trading domain, durable intent journal/outbox, RiskEngine, OMS, Execution Gateway, DEMO reconciliation and failure/recovery qualification gates are complete.

## Disposition

The backend disconnect-ordering race and REST 429 handling are implemented. The final per-attempt timeout correction is also committed. The batch remains **implementation-complete, exact-head qualification pending**; PR #66 is not merge-qualified.
