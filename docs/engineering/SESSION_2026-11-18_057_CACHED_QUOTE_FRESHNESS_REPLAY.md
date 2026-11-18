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


## Library and architecture-source reconciliation

Reviewed the saved **Screen Implementation, Application Development & Professional Trading Workstation** execution reference, the Library's `Codex.zip` knowledge-base package and Mermaid catalogue, and the Library `Atheer Q&A Repository.zip` archive.

- The Q&A ZIP contains 517 primary Markdown files; a programmatic scan found 12 Mermaid blocks across 10 documents. These cover AI evidence/provenance and quality gates, manual intervention and override authority, unified intelligence-to-risk flow, strategy suspension/handover, emergency recovery and controlled resumption.
- The curated knowledge-base package contains five proposed Mermaid diagrams: system context, market-data pipeline, target trading boundaries, AI order boundary and backtest pipeline. Its catalogue explicitly marks syntax/render validation pending.
- Repository diagrams 01–11 were inspected. The canonical market-data pipeline diagram (03) is updated in this branch to distinguish live distribution from cached replay and to show freshness recomputation at replay time.
- The separate `ATHEER_HISTORICAL_MERMAID_52_SOURCE_EXPORT.zip` and `Project documents and questions and answers.zip` named in the documentation handover were not present in the current Library listing. Therefore, the 52 historical Mermaid blocks have not been claimed as reviewed. The available 12 Q&A blocks and five curated diagrams are the inspected sources for this increment.

The source diagrams reinforce the same safety invariants: missing/stale/invalid evidence must remain explicit; deterministic checks precede consequential outputs; manual, strategy and AI proposals converge on independent authorization and RiskEngine; the Execution Gateway alone deals with the broker; manual overrides cannot be silently overwritten; and recovery cannot resume normal trading until broker positions/orders/executions are reconciled and verified.

The current 5,000 ms quote maximum-age and 250 ms future-skew values are inherited from the existing streaming implementation and reused by this correction. They are not newly approved trading-risk limits. The historical repository baseline separately records 5-second normal quote age, blocking new automated entries above 10 seconds and stale classification above 15 seconds. Reconcile those semantics against the authoritative market-data/RiskEngine specification before connecting this display-quality state to automated entry authorization. This PR does not change risk policy or wire RiskEngine.

## Safety

No broker credentials, provider session, orders, risk limits, LIVE capability or execution path was used or changed. This correction only tightens display/data-quality freshness classification. `CAP_ALLOW_TRADING=false` remains unchanged.
