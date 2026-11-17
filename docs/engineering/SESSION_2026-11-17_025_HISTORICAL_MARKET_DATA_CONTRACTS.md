# Engineering Session 025 — Historical Market Data Contracts

**Date:** 2026-11-17  
**Work package:** ATP-MKT-005  
**Branch:** `feat/historical-market-data-contracts`  
**Base:** PR #38 exact head `0d37f11a8f91d09c82b39c443e346622a7df3530`

## Objective

Replace the raw historical price response with a validated, provider-neutral candle contract and add explicit UTC date-range support without inventing volume semantics, market-session completeness, or persistence.

## Implemented

- Added `historical-prices.ts` with typed resolution, independent Bid/Ask OHLC, UTC provider time, local receipt time, optional provider volume lineage, duplicate detection, and observed gap reporting.
- Added strict UTC `from/to` validation and conversion to Capital.com's documented date format.
- Extended `CapitalDemoClient` and `CapitalDemoRuntime` to pass date ranges and enforce the provider's 1–1000 `max` limit.
- Updated `GET /market-data/history` to validate epic, resolution, max, and date ranges and return normalized candles rather than raw provider payloads.
- Corrected the history route's digit validation regex while expanding route coverage.
- Added deterministic normalization, range, adapter, and API route tests.
- Added architecture documentation and Mermaid diagram 10.

## Source and design constraints

- Capital.com documents `snapshotTimeUTC`, separate bid/ask values for open/high/low/close, optional `lastTradedVolume`, `from`, `to`, and a maximum `max=1000`.
- Provider `lastTradedVolume` is retained as a provider field; no unsupported interpretation is assigned.
- Date bounds are explicit UTC seconds in the ATHEER API.
- Gaps are reported as observed and require a market-session calendar before they can be classified as missing data.
- No synthetic candles or interpolation.
- PostgreSQL is the recorded persistence direction but deployment and workload qualification are pending; no fake in-memory persistence was introduced.

## Verification

- Exact-head CI has not yet run on this branch.
- The PR #38 parent has previous Backend Toolchain 31/31, Repository Hygiene, Mermaid, and Local Sync Safety passes; its Intel/Apple Silicon macOS jobs remain pending.
- No local TypeScript test execution or live Capital.com request is claimed in this session.
- New exact-head backend and Mermaid runs are required before merge.

## Safety

- DEMO only; read-only historical market-data path.
- No account mutation, orders, dealing, or LIVE behavior.
- `CAP_ALLOW_TRADING=false` unchanged.
- No RiskEngine, OMS, or Execution Gateway integration.
