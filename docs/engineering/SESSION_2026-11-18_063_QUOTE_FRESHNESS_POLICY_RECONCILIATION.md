# Session 063 — Quote Freshness Policy Reconciliation

**Date:** 2026-11-18  
**Workstream:** ATP-MKT-007 / market-data quality and entry eligibility  
**Branch:** `fix/market-data-cached-quote-freshness-2026-11-18`  
**PR:** [#67 — Cached quote freshness replay correction](https://github.com/atheertrading/atheer-trading-platform/pull/67)  
**Parent:** PR #66 — private broker credential IPC

## Governing requirement

The Library's ATHEER Trading Pro construction directive and trading-system requirements explicitly preserve this quote-age policy:

- Up to and including 5 seconds: normal operating condition.
- Above 10 seconds: block new automated entries.
- Above 15 seconds: classify the data as stale and apply the appropriate protective behavior.

The previous streaming implementation had reused a 5-second maximum-age value as the single stale and automated-decision cutoff. That collapsed three distinct policy boundaries into one and was stricter than the approved entry-block threshold while semantically overbroad: it called the value `automatedDecisionsAllowed`, which could be read as disabling all automated decisions, including position management.

## Implementation correction

The market-data freshness contract now distinguishes four valid age bands and invalid data:

| Provider quote age | State | New automated entries |
|---|---|---|
| `0–5,000 ms` | `fresh` | Allowed |
| `>5,000–10,000 ms` | `aging` | Allowed |
| `>10,000–15,000 ms` | `entry_blocked` | Blocked |
| `>15,000 ms` | `stale` | Blocked |
| Invalid timestamp / quote / clock / policy | `invalid` | Blocked |

Boundary semantics are deliberate: exactly 10 seconds is still aging and does not trigger the “above 10 seconds” block; exactly 15 seconds is entry-blocked but not yet stale. The future timestamp tolerance remains 250 ms.

Changes:
- Replaced the single `maximumAgeMs` contract with `normalAgeMs`, `automatedEntryBlockAgeMs`, and `staleAgeMs`.
- Replaced the ambiguous `automatedDecisionsAllowed` field with the entry-specific `newAutomatedEntriesAllowed`.
- Recompute these classifications at initial quote receipt and every cached quote replay, using the original provider timestamp and current backend clock.
- Preserve provider and local receipt timestamps; never refresh quote age by replay time.
- Native SSE decoding validates the state, age band, exact approved thresholds and entry-eligibility consistency.
- The native monitor distinguishes normal, aging, entry-blocked, stale and invalid states. Aging is attention-level; blocked/stale/invalid are danger-level.
- Position management is explicitly not inferred from the entry gate. The RiskEngine must make separate protective/management decisions using its governed contracts; this increment does not add an execution path or change risk authorization.

## Test coverage added or updated

Backend tests cover:
- Exactly 5,000 ms and 10,000 ms.
- 5,001 ms and 10,001 ms.
- Exactly 15,000 ms and 15,001 ms.
- Cached quote replay through aging, entry-blocked and stale states.
- Preserved provider and receipt timestamps through replay.
- Future timestamps and malformed quote rejection.

Swift tests cover:
- Fresh, aging and entry-blocked wire decoding.
- Rejection of unsupported freshness thresholds and inconsistent state/eligibility.
- Local monotonic aging from normal to aging, entry-blocked and stale without resetting provider age.

## Files changed

- `services/api/src/market-data/contracts.ts`
- `services/api/src/market-data/capital-demo-streaming-runtime.ts`
- `services/api/test/market-data.test.mjs`
- `services/api/test/market-data-streaming.test.mjs`
- `apps/macos/ATHEERTradingPro/Sources/Services/MarketDataStreamClient.swift`
- `apps/macos/ATHEERTradingPro/Sources/MarketDataStreamViewModel.swift`
- `apps/macos/ATHEERTradingPro/Sources/MarketExplorerView.swift`
- `apps/macos/ATHEERTradingPro/Tests/MarketDataStreamClientTests.swift`

## Verification status

Source and contract consistency checks were performed before commit. Exact-head hosted backend, Swift/XCTest, repository hygiene, Mermaid rendering and Local Sync Safety checks are pending. No test pass is claimed until the exact commit's workflow completes. No owner-Mac build/runtime, broker DEMO session, order, or LIVE action is claimed.

## Safety boundary

This is a market-data quality contract and UI classification correction. It does not authorize trading, connect RiskEngine, submit orders, alter `CAP_ALLOW_TRADING=false`, or change broker credentials. All dealing remains outside the market-data service.
