# ATP-DOMAIN-001A — Test and Verification Report

**Date:** 2026-11-17  
**Branch under test:** `feat/atp-domain-foundation`, stacked on PR #10 head `06bd496d957b6cd2f999209cf5dc83cae54251cf`.  
**Verification scope:** isolated domain source and tests in the available container; not the owner's Mac.

## Executed commands

```sh
tsc --noEmit --project tsconfig.json
tsc --project tsconfig.json
node --test test/trading-domain.test.mjs
```

## Results

- TypeScript project typecheck: PASS.
- TypeScript compilation: PASS.
- Domain test suite: 28 passed, 0 failed.
- Runtime: Node.js 22.16.0.
- TypeScript compiler: 5.8.3.

Node.js 22 is below the repository's required Node.js 24 runtime target. These results establish local compilation and deterministic domain test behavior in the available container, but do not replace Node.js 24 CI verification. The existing API health tests were not included in this isolated run.

## Coverage

- Decimal parsing, exact arithmetic, rounding and division-by-zero.
- Currency-safe money arithmetic and UTC timestamp validation.
- Instrument precision, tick/step, quantity bounds and quote freshness.
- LIVE account guard, trading-session transitions and order-intent validation.
- Order state transitions, risk rejection, partial/full fills, weighted average price, duplicate execution and overfill.
- Unknown submission outcome and reconciliation-required transition.
- Long/short position increase, partial close, realized/unrealized linear P&L and over-close.
- Order/position reconciliation and broker snapshot authority.
- Portfolio gross exposure grouped by quote currency without implicit FX conversion.
- Risk fail-closed behavior, order-volume/instrument/account exposure, stale data, emergency halt, inactive account and LIVE rejection.
- OMS duplicate idempotency key, conflicting payload reuse and concurrent duplicate intake.
- Immutable value-object snapshot behavior.

## Not verified

- Completion of the macOS Xcode build/test/Swift CodeQL job on the current branch head.
- Full existing API test suite against the authoritative source snapshot.
- PostgreSQL, durable idempotency, transactional outbox/inbox, restart recovery or multi-process concurrency.
- Real broker/Capital.com behavior, account state, market data, order execution or reconciliation.
- Full cross-currency, derivatives, fee/financing, margin, drawdown or approved risk-limit calculations.
- Physical Mac, Xcode, Swift, app launch or app/backend integration.
- PR #10 merge or integration of this branch into `main`.

The in-memory registry used by tests is a test fixture only. It is not production persistence evidence.

## Hosted verification gate

PR #10's current head `06bd496d957b6cd2f999209cf5dc83cae54251cf` has green CI #117, CodeQL #117 and Local Sync Safety #48. Those runs predate ATP-DOMAIN-001A and do not verify this new branch. Fresh CI on the ATP-DOMAIN-001A head is required after the branch commit. PR #10 remains open/unmerged; the domain branch is stacked on its feature branch.


## Hosted CI partial evidence — head 4c43ebe8f0b356e38cd03ea965e9a4bcaeb3fecc

- CI #121 Backend toolchain ran on Node.js v24.22.2 / npm 11.19.1: TypeScript typecheck passed; API and domain test suite passed (34 tests, 0 failures).
- CI #121 Repository hygiene and Markdown lint passed.
- Local Sync Safety #56 passed.
- CI #121 macOS build, XCTest and Swift CodeQL job was still running at the time of this record; no result is claimed. A complete green run on the final branch head remains required.
