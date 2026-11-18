# Engineering Session 071 — Canonical Domain Payload Immutability

**Date:** 2026-11-19  
**Assignment:** ATP-TEAM-B-001 — Backend Engineering  
**Work package:** ATP-DOMAIN-001  
**PR:** #76 — canonical multi-asset trading domain foundation  
**Branch:** `feat/canonical-multi-asset-domain-foundation`  
**Code/test head recorded before this report commit:** `dc2e3d7445ce19dc526d0a3d8bc4ce25bebc33c0`

## Finding

The canonical domain uses immutable event and intent records. The previous recursive freeze helper called Object.freeze on all object values and recursed through Object.values. That is insufficient for arbitrary nested runtime values:

- Object.freeze does not prevent Map/Set mutator methods from changing their entries.
- A frozen Date object can still change its internal time value through Date methods.
- Accessor properties can execute code during later reads and are not converted into immutable data.

A typed TypeScript interface does not prevent such runtime values from arriving at a public constructor through JSON adaptation, untyped JavaScript or a cast.

## Implementation

Updated `services/api/src/domain/shared.ts`:

- `deepFreeze` now accepts data-only object graphs made of plain objects and arrays.
- Rejects functions and objects with non-plain prototypes, including Map, Set and Date.
- Traverses own property descriptors rather than invoking getters through Object.values/property reads.
- Rejects accessor properties with the stable `invalid_immutable_value` domain validation code.
- Preserves recursive freezing and cycle detection for plain object/array graphs.

Updated `services/api/test/domain.test.mjs`:

- Nested Map inside an execution-event payload is rejected.
- An accessor property that would throw when evaluated is rejected without invoking the getter.

No order, risk, lifecycle, identifier or broker-execution semantics were changed. This change only makes the existing immutability contract enforceable at runtime.

## Verification

At exact code/test head `dc2e3d7445ce19dc526d0a3d8bc4ce25bebc33c0`:

- Backend TypeScript type-check/build/API test command: passed.
- Repository Hygiene: passed.
- Apple Silicon macOS Debug build, XCTest and Release build: passed.
- Apple Silicon Swift CodeQL steps: skipped by the workflow for this runner.
- Intel x86_64: still in progress at last inspection.
- Local Sync Safety: passed.
- CodeQL workflow: passed.
- Mermaid architecture diagrams: passed.

A new documentation commit for this report advances the PR head; fresh exact-head CI must be checked before merge qualification. The PR remains Draft and has no recorded review approval.

## Boundaries

- Domain code remains transport/database/broker/UI independent.
- No PostgreSQL persistence, transactional outbox, RiskEngine formula, OMS order state machine, Execution Gateway, dealing adapter or LIVE execution is introduced.
- The existing policy is to keep order/position detailed transitions open until accepted original architecture/ADR semantics and broker contracts are reconciled.
- `CAP_ALLOW_TRADING=false` remains enforced.
