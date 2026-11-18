# Engineering Session 065 — Backend API Boundary Validation and OpenAPI Contract

**Date:** 2026-11-18  
**Assignment:** ATP-TEAM-B-001  
**Batch:** ATP-2026-11-18-065  
**Repository:** `atheertrading/atheer-trading-platform`  
**Pull request:** [#84 — Validate market-data query parameters at the HTTP boundary](https://github.com/atheertrading/atheer-trading-platform/pull/84)  
**Branch:** `fix/market-history-max-query-validation`  
**Base:** `main` at `31e3e5547c9204645427ec56426e741d4bcfa955`  
**Current head:** `d5853c3ed8ba42cc49384a64832d270b262fb0b2`

## Objective

Correct a verified API input-validation defect, establish consistent client-error responses for market-data query validation, and publish a versioned contract for the routes that actually exist in the current local backend.

## Implementation

- Corrected the malformed `max` regular-expression validation in `GET /market-data/history`.
- Enforced `max` as a safe integer from 1 through 1000, defaulting to 100. Invalid values return HTTP 400 before the provider runtime is called.
- Added HTTP-boundary validation and trimming for market `searchTerm` values (1–100 characters); invalid values return HTTP 400.
- Added HTTP-boundary EPIC validation using `^[A-Za-z0-9_.-]{1,64}$`; invalid values return HTTP 400 before provider invocation.
- Added regression tests for default and boundary values, malformed/fractional/exponent/negative/empty/overflow values, invalid EPICs, invalid search terms, and provider-call suppression.
- Published `services/api/openapi.yaml` as the OpenAPI 3.1 contract for the current service routes.
- Added an API-contract regression test for route inventory, loopback/security disclosures, input bounds, and component-reference integrity.
- Linked the contract and documented input constraints in `services/api/README.md`.

## Changed files

- `services/api/src/server.ts`
- `services/api/test/market-history-max-validation.test.mjs`
- `services/api/test/market-data-query-validation.test.mjs`
- `services/api/test/openapi-contract.test.mjs`
- `services/api/openapi.yaml`
- `services/api/README.md`

## Verification — exact current head

- Commit: `d5853c3ed8ba42cc49384a64832d270b262fb0b2`.
- Backend Toolchain: **passed** — hosted Node.js 24 setup, TypeScript type-check/build and API test suite (CI run `44386717893`).
- Repository Hygiene: **passed** — same CI run.
- CodeQL: **passed** (run `44386718140`).
- Local Sync Safety: **passed** (run `44386718050`).
- Intel x86_64 macOS build/XCTest/Swift CodeQL: **queued** at last inspection.
- Apple Silicon arm64 macOS build/XCTest/Swift CodeQL: **queued** at last inspection.
- No local Node 24 execution, owner-Mac build/runtime, authenticated DEMO session or visual/accessibility acceptance is claimed.

## Security and trading boundaries

- The current mainline API remains loopback-only and does not yet enforce a per-request application capability on HTTP routes. Loopback binding is not authentication; do not expose this revision beyond `127.0.0.1`.
- The credential confidentiality and private Unix-domain IPC integration in PR #66 remains a separate, unmerged dependency stack.
- Historical price records remain opaque provider objects in this API version. This contract does not imply normalized OHLC candles or volume semantics.
- No credentials, broker sessions, account state, orders, positions, dealing routes, RiskEngine, OMS, Execution Gateway or LIVE capability were added or used.
- `CAP_ALLOW_TRADING=false` remains unchanged.

## Integration status

PR #84 is OPEN and not merged. The backend and security/documentation checks have passed on its exact head; Intel and Apple Silicon checks remain pending. Merge only after all applicable required checks complete successfully and the final diff is reviewed.

The canonical domain / PostgreSQL / OMS dependency stack remains separate:
- PR #76 — canonical multi-asset domain.
- PR #81 — PostgreSQL persistence on the canonical domain.
- PR #82 — risk-gated OMS lifecycle persistence.

PR #76's cancelled macOS jobs were re-triggered. PRs #81 and #82 have backend/hygiene passes, with their macOS matrix still incomplete. No PR in that dependency chain is claimed merged by this session.

The authenticated broker/session and charting stack also remains open. Current parent/head comparisons identified branch-parent drift in PRs #66–#70; those branches require preservation-first updates and exact-head requalification before integration. Do not force-push, rewrite history, or merge across UI ownership boundaries.

## Next actions

1. Complete exact-head Intel and Apple Silicon qualification for PR #84; merge only when all required gates pass.
2. Complete PR #76 exact-head macOS qualification, then review and integrate the canonical domain before its persistence and OMS descendants.
3. Reconcile PR #81 and #82 against the integrated canonical parent and rerun exact-head qualification.
4. Resolve authenticated broker-session ancestry and private credential IPC before any authenticated DEMO acceptance.
5. Keep LIVE disabled and retain the centralized risk/execution authority requirements.
