# Session 057 — Cached Quote Freshness Replay Correction

**Date:** 2026-11-18  
**Workstream:** ATP-MKT-007 / quote-quality integrity  
**Branch:** `fix/market-data-cached-quote-freshness-2026-11-18`  
**Base:** PR #66 exact head `9c0dd2e87cadabfbe33c4f27046b4991129c19a8`

## Finding

The streaming runtime retained the latest quote in `latestQuotes` and replayed it through `latest(epics)` when a new SSE subscriber connected. The cached quote's original `freshness` object was calculated at initial receipt and was returned unchanged. A quote that was fresh at receipt could therefore be replayed minutes later with `state: fresh` and `automatedDecisionsAllowed: true`.

The native view model starts its local monotonic age calculation when it receives an event. Replaying the original age value could consequently reset the displayed age and misclassify old data as fresh.

## Correction

- Centralized the stream freshness policy constants (5,000 ms maximum age; 250 ms maximum future skew).
- Recompute freshness in `CapitalDemoStreamingRuntime.latest()` using the current backend clock and the original provider timestamp.
- Preserve the original `providerTimestampMs` and `receivedAtMs` provenance; do not rewrite receipt history.
- Return stale/invalid replayed quotes with `automatedDecisionsAllowed: false`.
- Add a deterministic regression test that advances the injected clock by 6,000 ms and verifies stale classification, exact age, preserved provenance and denied automated-decision eligibility.

## Changed files

- `services/api/src/market-data/capital-demo-streaming-runtime.ts`
- `services/api/test/market-data-streaming.test.mjs`

## Commits

- `d8ecbf3f2431b057e7104720b6f030401f905628` — `fix(market-data): recompute cached quote freshness on replay`
- `12e32c175c8f05ecb9708879345f31ed31d380ff` — `test(market-data): cover stale cached quote replay`

## Verification

- Source review confirms replay freshness is evaluated against the current backend clock while provider and local receipt timestamps remain unchanged.
- Regression test source is committed. Hosted backend tests, full exact-head CI, Mermaid/hygiene checks and Intel/Apple Silicon macOS qualification are pending for this branch.
- No test pass, owner-Mac runtime result, live provider request or automated-trading integration is claimed.

## Safety

No broker credentials, provider session, orders, risk limits, LIVE capability or execution path was used or changed. This correction only tightens display/data-quality freshness classification. `CAP_ALLOW_TRADING=false` remains unchanged.
