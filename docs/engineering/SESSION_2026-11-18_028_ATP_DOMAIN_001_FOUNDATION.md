# Session 028 — ATP-DOMAIN-001 Canonical Trading Domain Foundation

**Session ID:** ATP-2026-11-18-028  
**Date:** 2026-11-18  
**Repository:** `atheertrading/atheer-trading-platform`  
**Branch:** `feat/trading-domain-foundation`  
**Pull request:** [#40](https://github.com/atheertrading/atheer-trading-platform/pull/40) — Draft, stacked on PR #39.

## 1. Source and authority review

Reviewed the repository's root `AGENTS.md`, current architecture and engineering records, diagrams 01–10, the Library's `Codex.zip` knowledge base, and the available `Atheer Q&A Repository.zip`.

The accessible Library archive inventory differs from the repository's historical archive record:

- `Atheer Q&A Repository.zip`: 517 Markdown documents and 12 fenced Mermaid blocks.
- `Codex.zip`: 58 Markdown documents and 5 standalone `.mmd` files.
- 17 Mermaid sources were inspected across those two archives, in addition to the repository's canonical diagrams 01–10.
- The repository's prior inventory refers to a separate `Project documents and questions and answers.zip` containing 564 Markdown files and 52 Mermaid blocks. That exact archive/path was not present in the accessible Library root during this session. The 52-block historical extraction is therefore **not** claimed complete.

The Q&A guidance used in this slice includes broker-scoped/environment-scoped instrument identifiers, preservation of raw broker units and constraints, distinct minimum/maximum/increment/lot/contract concepts, decimal-safe quantity handling, one common intent path across human/strategy/algorithm/AI sources, explicit intent/correlation/idempotency identity, durable intent before dispatch, and mandatory centralized risk authorization.

The knowledge base records accepted ADR-0004/ADR-0005 and ADR-0006/OOP, but the original ADR texts were not present in the inspected Library archives. They were not inferred or replaced.

## 2. Implemented scope

Added a provider-independent TypeScript domain package under `services/api/src/domain`:

- Branded internal and broker-scoped identifiers.
- Explicit DEMO, SIMULATION, BACKTEST and LIVE environment values.
- Canonical decimal strings with exact BigInt comparison and increment-alignment helpers; no binary floating-point coercion or implicit rounding.
- UTC epoch-millisecond timestamps and source provenance (source identity/type, environment, event time, receipt time, schema/normalization versions, validation code).
- Instrument identity and versioned broker specifications.
- Separate price precision, price increment, quantity precision, minimum/maximum deal size, quantity increment, lot size, contract size, and units.
- Broker account identity and broker-authoritative account balance snapshots.
- Immutable/versioned intent envelopes with intent, command, correlation, idempotency, account, instrument/specification, environment, origin, strategy/agent, signal and market-snapshot provenance.
- Risk assessments bound to an intent and policy version.
- Caller-supplied lifecycle transition policies.
- Broker order/position observations, execution fills/events, reconciliation and audit events.

The new tests are in `services/api/test/domain.test.mjs` and are included by the existing `npm test` script.

## 3. Deliberate non-decisions

- UUIDv7 is recommended in the Q&A, but the original formal ADR text was unavailable. No UUID version or generation implementation was selected; the future backend application service must own an injected identifier generator.
- Detailed OMS order/position state lists, order-type vocabulary, transition rules, risk formulas, and rounding modes were not frozen. The package provides an explicit generic transition-policy validator and requires exact decimals; it does not invent a universal state machine or rounding behavior.
- No PostgreSQL schema, migration, repository, transaction/outbox, broker command, account mutation, or execution capability was added.
- No broker credentials were read or written. No LIVE behavior or dealing permission was enabled.

## 4. Source commits and hosted CI

- Initial domain implementation: `92a179edc42f7cfeaa47199d20e19acb07edebf0`.
- Branded identifier comparison correction: `392224b8dbdda132a8249c4f9dfd0569770a2ce9`.
- Broker observation/fill validation and test expansion: `d58c60fe3ac4a7e148dc6387d0041aebc033ac0b`.
- Intent source and market-snapshot provenance: `f295023e08774aed7a68c4f916eb14308e720593`.

Initial PR #40 CI run #44193072976 was triggered against earlier head `13bc60e4023abcbf5b70e6a424b1a70d2befc0a8`:
- Repository Hygiene passed.
- Backend Toolchain failed on two TS2367 comparisons between branded `SourceId` and `BrokerId` values.
- Intel macOS job was in progress and Apple Silicon was queued at the time of inspection.

The two compile errors were corrected by comparing validated opaque identifier values as strings. The current source head `f295023e...` has not yet received an exact-head hosted run. No TypeScript build or Node test pass is claimed for this current head.

The available tool container reports Node 22, while `services/api/package.json` requires Node >=24. No local Node 24 result is claimed.

## 5. Architecture and delivery order

- Domain contracts precede persistence, consistent with the governing platform construction sequence.
- The domain package has no dependency on HTTP, database vendors, broker SDKs, SwiftUI, or provider-specific execution code.
- The next package is ATP-PERSISTENCE-001: PostgreSQL migrations and repository/outbox implementation after exact-head domain qualification and formal schema/state semantics review.
- The execution invariant remains: no broker dealing command without a durably committed intent and matching risk authorization.

## 6. Current status and next action

PR #40 is OPEN / DRAFT and stacked on PR #39. The dependent PR chain remains unmerged.

Next:
1. Trigger and inspect exact-head PR #40 CI for TypeScript typecheck/build, API tests, repository hygiene, Mermaid, Intel and Apple Silicon macOS qualification.
2. Correct any additional findings and repeat exact-head verification.
3. Continue formal source/ADR reconciliation before freezing concrete order/position state machines or precision/rounding policies.
4. Begin PostgreSQL persistence as the next bounded vertical slice only after domain contracts qualify.

`CAP_ALLOW_TRADING=false` remains unchanged. No RiskEngine bypass, OMS dispatch, Execution Gateway dealing call, broker permission, LIVE capability, or production configuration was introduced.


## Follow-up — strict UTC timestamp validation remediation (2026-11-18)

Focused review identified that JavaScript `Date.parse` normalizes some impossible calendar dates (for example, February 31) instead of rejecting them. Commit `7ebe46ce7abd104cb74345169e16dbe64cb87998` updates `utcTimestampFromIso` to validate Gregorian month/day combinations, leap years, and clock ranges before parsing. Regression tests cover a valid leap day with milliseconds, a non-leap February 29, February 31, April 31, invalid month, hour 24, and minute 60.

The prior head `34015bda...` had 46/46 backend tests, Repository Hygiene, Mermaid, Local Sync Safety, and Intel x86_64 Debug/XCTest/Release/Swift CodeQL passed; Apple Silicon arm64 remained queued. Those results do not qualify the new fix commit. On `7ebe46ce...`, Local Sync Safety passed, Mermaid validation was in progress, and the full CI run was queued at the time of this record. Exact-head revalidation remains required. No local Node 24 or owner-Mac result is claimed.
