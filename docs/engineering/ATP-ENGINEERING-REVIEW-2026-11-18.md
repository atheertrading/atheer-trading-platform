# ATHEER Trading Pro — Engineering Review, Decisions & Delivery Estimates

- **Record ID:** ATP-ENG-REVIEW-2026-11-18
- **Review date:** 2026-11-18
- **Repository:** `atheertrading/atheer-trading-platform`
- **Baseline:** `main`; the reviewed continuity snapshot records PR #24, #25, #26 and #33 as merged. See the evidence notes below before relying on any later PR state.
- **Status:** Architecture review and planning record; not a release approval, implementation claim, or authorization to enable LIVE dealing.

## 1. Executive assessment

ATHEER Trading Pro is to be engineered as a professional, extensible, multi-asset Trading Operating System, not merely a macOS terminal or a broker-specific front end. The current implementation establishes useful foundations (workspace/Command Center, Capital.com DEMO broker management, Market Explorer, typed market-search contracts and hosted CI qualification for recorded merge heads). It is not yet a complete trading system.

The largest integration risk is split broker-session authority: native Swift/Keychain authentication and backend environment-driven authentication must not independently own Capital.com credentials, CST/X-SECURITY-TOKEN lifecycle, reconnect, or account selection. The largest product risk is allowing market-data, charting, strategy, OMS, and execution work to advance without a single canonical financial domain and centrally enforced risk boundary.

**Current release posture:** engineering foundation in progress; controlled DEMO qualification incomplete; automated dealing and LIVE are not authorized.

## 2. Evidence, status semantics and limitations

Use these status meanings consistently:
- **MERGED / VERIFIED:** supported by a recorded merge commit or exact-head test evidence.
- **IMPLEMENTED — QUALIFICATION PENDING:** source is reported present, but required exact-head CI, owner-workstation, integration, or runtime evidence is missing.
- **PARTIAL:** only a subset of the required behavior exists.
- **PROPOSED:** architectural direction, not verified implementation.
- **BLOCKED:** dependent work must not be accepted until the named prerequisite is met.

The 2026-11-18 continuity snapshot records:
- PR #24 Workspace / Command Center merged at `bd83fd3c8df481104c347f05d9d4f38537d8b011`.
- PR #25 Capital.com DEMO market-data foundation merged at `6b570b8c5a3367784cde7fa2643593c5b5a1eda2`.
- PR #26 DEMO broker management merged at `6b4668b9355178d5e13219f14cfe8cc847770915`; exact-head CI run `44231098511` is recorded as passing Intel x86_64 Debug/XCTest/Release/Swift CodeQL, Apple Silicon arm64 Debug/XCTest/Release, backend toolchain and repository hygiene. Dedicated CodeQL `44231098441` and Local Sync Safety `44231098576` are recorded as passing.
- PR #33 Market Explorer merged at `2e8bf9bd5f4274ed5d500474335a778cd6f9b75c`, tested head `04e70808d5cb403b6a7b8e05ceb41dc335e3d4cf`; CI `44235123474`, CodeQL `44235124217`, and Local Sync Safety `44235123457` are recorded as passing.

These hosted results do **not** establish owner-Mac visual/accessibility/runtime acceptance, Keychain persistence across restart, authenticated Capital.com DEMO success, end-to-end order execution, reconciliation, or LIVE readiness. PR and branch states are mutable; re-fetch current PR metadata, exact head SHAs, ancestry and checks before any integration action. Older statements in continuity/task documents that conflict with the later dated integration checkpoint are superseded only where the later checkpoint explicitly says so.

## 3. Product and domain direction

The product target is a multi-asset professional trading operating system with these bounded domains:
1. **Market Intelligence:** provider adapters, instrument master, market status, quotes, trades, order books where supported, corporate/economic events and provenance.
2. **Quantitative Research:** indicators, feature calculations, charting, historical data, research notebooks and reproducible datasets.
3. **Strategy & Simulation:** strategy definitions, deterministic backtests, paper/simulation execution, walk-forward and out-of-sample validation.
4. **Trading & Execution:** order intents, OMS, broker adapters, controlled execution, fills, positions and lifecycle reconciliation.
5. **Risk & Portfolio:** pre-trade risk, exposure, limits, margin, concentration, portfolio valuation and emergency controls.
6. **AI & Decision Intelligence:** advisory analysis and bounded agent proposals; AI is not a broker execution authority.
7. **Workstation & Operations:** native macOS workspace, observability, audit, settings, permissions and operational controls.

Potential asset classes include FX, metals, energy, indices, equities, digital assets and agricultural commodities. This is a platform-domain target, **not** a claim that Capital.com or any current broker account supports every class. Each instrument must be capability-qualified by broker, account jurisdiction/type, trading hours, contract specification, currency, lot/tick size, margin, financing, order types and market-data entitlement before it is shown as tradable.

## 4. Binding engineering decisions

### EDL-024 — Single broker credential/session authority (P0)
The backend Broker Session Manager is the sole runtime authority for broker authentication and session lifecycle. macOS remains the user-facing credential-entry and consent surface; credentials are provisioned from Keychain to the managed backend using a private, authenticated bootstrap channel. No second native Swift runtime session may independently authenticate and trade. Environment credentials are test/development-only and must never become a production fallback.

**Acceptance:** one session owner for REST, streaming, account, positions and future OMS; secret redaction; secure storage; authenticated local IPC; per-launch capability; expiry/refresh/reconnect tests; account-switch isolation; no credential/token logging.

### EDL-025 — Local process and IPC trust boundary (P0)
A static header such as `X-ATHEER-LOCAL-CLIENT: macOS` is a browser-origin/CSRF mitigation marker, not authentication. Production local APIs require an unpredictable per-launch capability (minimum 256 bits), delivered through private stdin/pipe or equivalent protected channel, bearer authorization, loopback-only binding, origin/fetch-metadata rejection, strict route authorization, and lifecycle invalidation when the managed child exits.

**Acceptance:** unauthorized local process denied; browser cross-origin denied; token absent from logs/crash reports; token invalid after process restart; no wildcard CORS; bounded request bodies and timeouts.

### EDL-026 — One governed order path (P0)
Manual, strategy, automation and AI-generated proposals must converge on a canonical Order Intent and the same path:
`Intent → Validation → Central RiskEngine → OMS → Execution Gateway → Broker Adapter`.
No UI, strategy, agent or adapter may bypass pre-trade risk. Broker acknowledgement is not a fill. Timeouts are ambiguous outcomes: query/reconcile by client correlation/idempotency key before retry. Use durable intent journal/outbox, UUID/correlation IDs, idempotency, order-state transitions and audit trail.

### EDL-027 — Broker truth and reconciliation (P0)
Broker-confirmed account, margin, orders, fills, positions and cash are authoritative for broker-connected trading. Local state is a projection/cache and must be reconciled. Never fabricate balances, prices, fills, margin or positions. Unknown, stale or contradictory broker state blocks new risk-increasing actions; safe cancel/close/lockdown controls remain available subject to verified broker state and explicit policies.

### EDL-028 — Canonical multi-asset domain (P0/P1)
Use provider-neutral domain entities and explicit instrument metadata/capabilities. Avoid leaking provider DTOs into SwiftUI, strategy logic, risk or persistence. Model decimal precision, quote currency, contract multiplier, tick/lot increments, trading sessions, order capabilities, market-data timestamps/source and asset-specific risk semantics. Do not assume all assets share FX/CFD semantics.

### EDL-029 — Market-data quality and subscription governance (P1)
Separate REST request limits, authenticated REST keepalive/session inactivity, WebSocket heartbeat/lifetime and provider instrument-subscription caps. Do not invent provider limits. Apply timestamp/sequence validation, stale/out-of-order suppression, gap detection, reconnect/resubscribe, subscription priority, utilization telemetry and explicit degraded states. Recorded Capital.com work mentions a 40-instrument cap; verify this against current official broker specifications before treating it as universal or permanent.

### EDL-030 — Persistence, audit and event integrity (P1)
PostgreSQL is the target durable store for canonical trading state, audit, broker observations and operational history. Define migrations, transaction boundaries, retention, backup/restore, encryption and access control. Use append-only intent/audit records where appropriate. Do not persist transient quote streams indiscriminately; define hot cache, time-series retention and historical backfill policies separately.

### EDL-031 — AI is advisory, bounded and auditable (P1/P2)
AI agents may research, explain, rank, propose and prepare intents. They cannot hold broker secrets, alter risk limits, grant permissions, call dealing endpoints, or bypass RiskEngine. Every proposal must carry source evidence, timestamp, model/agent identity, confidence/uncertainty and expiry; deterministic validation and risk approval remain outside the model.

### EDL-032 — Release and operational qualification (P0)
Hosted CI is necessary but insufficient. Require exact-head Intel and Apple Silicon builds/tests, backend tests, repository hygiene, CodeQL and sync-safety checks, followed by owner-Mac installation/launch/navigation/visual/accessibility QA, Keychain restart test, authenticated broker DEMO test, market-data soak/reconnect, order lifecycle/reconciliation tests and documented rollback. LIVE remains separately gated by explicit owner authorization and operational/legal/broker readiness.

## 5. Priority gaps and delivery sequence

| Workstream | Priority | Required outcome / exit condition |
|---|---:|---|
| Broker session consolidation and secure bootstrap | P0 | One backend session authority; Keychain-backed provisioning; authenticated IPC; lifecycle and isolation tests |
| PR #37 preservation-first integration | P0 | Reconcile branch ancestry and client/server contract without force-push or blind retarget; integrate only after exact-head CI |
| Managed backend lifecycle | P0 | Deterministic launch, health, restart, graceful shutdown, crash handling and capability invalidation |
| Canonical trading domain and persistence | P0 | Instrument/account/order/fill/position models, migrations, audit and idempotent event handling |
| Central RiskEngine + OMS | P0 | Shared manual/automated path, pre-trade controls, durable state machine and kill/lockdown |
| Market data and charting | P1 | Authenticated DEMO data, historical/streaming consistency, candle aggregation, gaps and stale-data policy |
| Workstation UX | P1 | Integrated navigation, resilient workspaces, loading/error/degraded states, accessibility and operational visibility |
| Strategy runtime and simulation | P1 | Deterministic isolated simulation, fees/slippage, reproducible backtests and strategy lifecycle |
| Portfolio, reconciliation and reporting | P1 | Broker-sourced positions/P&L/margin, continuous reconciliation and discrepancy workflow |
| AI/agent intelligence | P2 | Evidence-grounded advisory agents with strict permissions and auditable proposals |
| Additional brokers and asset classes | P2 | Capability-driven adapter qualification and contract/risk test packs |

### Integration order
1. Re-fetch exact heads, PR states, checks and ancestry; create a dependency graph. Do not infer mergeability from green checks on a feature branch.
2. Preserve PR #37 history; resolve its recorded divergence from the PR #33 squash merge through an explicit merge-base/compare plan on a new integration branch. Never force-push or silently rewrite a contributor branch.
3. Integrate secure IPC and managed backend lifecycle before exposing privileged broker operations.
4. Consolidate broker credentials/session under EDL-024 and prove DEMO authentication and restart/reconnect behavior.
5. Qualify market data and instrument metadata; then canonical domain and durable persistence.
6. Implement RiskEngine and OMS before any dealing workflow.
7. Complete DEMO order lifecycle, reconciliation and failure injection before strategy automation.
8. Add strategy runtime, portfolio and AI only against the governed domain and execution contracts.

## 6. Engineering estimates

Estimates below are **engineering effort**, not calendar promises. Unit: person-days (PD), 1 PD = one focused engineer-day. Ranges assume existing repository foundations are reusable, one senior engineer can work sequentially with specialist review, and no major broker API or architecture rewrite is discovered. Add 25–40% contingency for integration, macOS 13/Swift 5.8 compatibility, broker sandbox variability and owner-workstation qualification. Parallel work does not eliminate critical-path dependencies.

| Increment | Estimate (PD) | Key assumptions / uncertainty |
|---|---:|---|
| Repository/PR ancestry audit and integration plan | 2–4 | Exact refs/checks accessible; no history rewrite |
| Secure IPC + managed backend lifecycle | 5–9 | Existing PR work reusable; platform process supervision needs hardening |
| Unified broker session + Keychain provisioning | 6–10 | Official Capital.com auth/session contract available; DEMO credentials supplied locally by owner |
| Market data streaming, quality and subscription orchestration | 6–12 | Provider caps/heartbeat verified; no new entitlement requirement |
| Canonical multi-asset domain + PostgreSQL/audit | 8–14 | Schema and migrations can evolve without major legacy data migration |
| RiskEngine + OMS + idempotency/outbox | 12–20 | Risk policy baseline and broker order contract sufficiently specified |
| DEMO execution + reconciliation + failure testing | 8–14 | Broker DEMO supports required order lifecycle and test cases |
| Charting/workstation integration and QA | 8–14 | Existing chart branches are reusable and UI design inventory is stable |
| Strategy runtime + deterministic backtesting | 12–20 | Historical data quality, costs and instrument specs available |
| Portfolio, reporting and operational controls | 8–14 | Broker account/position endpoints and canonical domain stable |
| AI advisory/agent governance | 8–14 | Tool permission boundary and evidence schema established |
| Additional broker/asset-class qualification | 5–10 per adapter/asset capability pack | Varies materially by broker, product and jurisdiction |

**Core controlled DEMO milestone estimate:** approximately **47–83 PD** from the reviewed baseline to secure broker session, market data, canonical domain, persistence, central risk/OMS, DEMO dealing and reconciliation, excluding advanced strategy/AI and broad charting polish. This is a planning range, not a claim of remaining work measured from a fresh code audit. Re-estimate after exact-head PR review and integration spikes.

## 7. Mandatory safety invariants

- Keep `CAP_ALLOW_TRADING=false` until DEMO reconciliation and RiskEngine qualification gates pass.
- SIM/BACKTEST must be isolated from broker-connected DEMO/LIVE state.
- LIVE authentication, permission changes, production credentials, risk-limit changes and live dealing require explicit owner authorization.
- No default/fallback fabricated prices, account values, margin, P&L, fills or positions.
- Quote age policy: normal up to 5 seconds; >10 seconds blocks new automated entries; >15 seconds is stale. Apply only where the instrument/feed's expected cadence makes this policy valid, and expose timestamp/quality.
- Existing positions must not be silently discarded on disconnect; lockdown blocks new exposure while preserving visibility and safe management.
- Emergency halt, cancel-pending and close-all are separate, audited operations with broker-state verification; never claim success before broker confirmation.
- Secrets must be redacted from logs, telemetry, crash reports, tests and support bundles.

## 8. Definition of Ready for controlled DEMO

A controlled DEMO release is acceptable only when all are evidenced:
1. Exact tested commit and reproducible build for supported Intel and Apple Silicon targets.
2. Authenticated local IPC and supervised backend process; unauthorized local/browser access rejected.
3. One backend-owned broker session; Keychain persistence/restart and token renewal/reconnect verified.
4. Real Capital.com DEMO authentication and instrument search verified using owner-supplied credentials without exposing secrets.
5. Real timestamped quotes/streaming and historical data have explicit quality, stale, gap and reconnect behavior.
6. Canonical account/instrument/order/fill/position models and durable audit/persistence are active.
7. RiskEngine is mandatory for every order intent; limits, stale-data rejection, idempotency and duplicate/timeout handling are tested.
8. OMS lifecycle is reconciled against broker orders/fills/positions; discrepancy and recovery workflows are exercised.
9. No LIVE permission or dealing path is enabled; configuration and UI make the restriction explicit.
10. Owner-Mac runtime, visual, keyboard, VoiceOver and operational acceptance evidence is recorded.

## 9. Documentation and governance actions

- Keep this record linked from the engineering continuity index and task register.
- Update implementation status only with exact commit, test run, owner workstation evidence and explicit remaining limitations.
- Record architectural changes as numbered EDL entries; do not silently replace prior decisions.
- Keep Mermaid diagrams synchronized with code: system context, process/IPC trust boundary, broker session lifecycle, market-data flow, order state machine, risk decision path, reconciliation and deployment topology.
- Maintain traceability: owner requirement → architecture decision → issue/task → PR → exact-head checks → acceptance evidence.
- Deduplicate the Library Q&A corpus by canonical question ID/content hash before treating extracted file counts as unique questions. Preserve source provenance and owner-approved answers; do not rewrite ambiguous answers by inference.
- Distinguish proposal, implementation, verification and release approval in every report.

## 10. Immediate action checklist

- [ ] Re-fetch current PR #37, #51–#58 and #39–#47 metadata, exact heads, checks and ancestry.
- [ ] Produce a preservation-first PR dependency/merge graph; do not force-push.
- [ ] Audit backend route authorization and managed process lifecycle against EDL-025.
- [ ] Complete one Broker Session Manager and remove duplicate runtime session authority.
- [ ] Verify official Capital.com DEMO authentication/session, rate and subscription contracts.
- [ ] Establish canonical instrument/account/order/fill/position models and PostgreSQL migrations.
- [ ] Implement/qualify RiskEngine + OMS before enabling any dealing capability.
- [ ] Record owner-Mac and authenticated DEMO evidence separately from hosted CI.
- [ ] Keep `CAP_ALLOW_TRADING=false`; LIVE remains disabled.

---
**Governance note:** This document records engineering direction and estimates for planning. It does not authorize broker permission changes, production deployment, risk-limit changes, LIVE access, or LIVE trading.
