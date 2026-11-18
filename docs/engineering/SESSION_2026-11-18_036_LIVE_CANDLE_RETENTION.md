# ATP-2026-11-18-036 — Bounded Live Candle Retention

**Date:** 2026-11-18  
**Repository:** `atheertrading/atheer-trading-platform`  
**Branch:** `fix/live-candle-retention-2026-11-18`  
**Base:** PR #45, `218d07c637738c14541482d067954325f16da224`  
**Work package:** ATP-MKT-006H

## Objective

Bound the volatile live chart series so long-running streaming sessions cannot grow the in-memory candle array indefinitely.

## Source change

- Added a 500-candle retention limit to `LiveCandleAggregator`, matching the historical bootstrap maximum.
- New accepted bars are appended chronologically; oldest bars are removed only when the cap is exceeded.
- Existing OHLC, Bid/Ask separation, source provenance, timestamp validation, and no-gap-fill behavior are preserved.

## Regression coverage

- Added `testLiveAggregatorRetainsOnlyTheMostRecent500Candles`.
- The test ingests 501 distinct minute buckets and verifies:
  - exactly 500 candles remain;
  - the oldest retained timestamp advances by one interval;
  - the newest timestamp and latest close are retained;
  - the retained first and last bars preserve live provenance.

## Commit trail

- `82d64fe30b67abc25c18e4be8ce0d0006a01b191` — `fix(charting): bound live candle series retention`
- `329101f388867097ccf5bf2c684d84af5e1d80ca` — `test(charting): cover bounded live candle retention`
- `9c19ecd1a35c4ffc7dbe15651b0952ce5f3f1a9f` — `docs/architecture/ATP_LIVE_CANDLE_AGGREGATION.md`
- `86e184546b164628c617849861ead9eafbcc2e26` — `docs/engineering/TASK_REGISTER.md`
- `27a0656ceba256ef4e8f407289bb3896fb5af1ff` — `docs/engineering/IMPLEMENTATION_STATUS.md`
- `a5ac204b7cd1dc1e64782e8d7068983c36148009` — `docs/engineering/ENGINEERING_DECISION_LOG.md`
- `cf541ed29ce55e42dbdc23f6a25f2044da30ab57` — `docs/engineering/PROJECT_CONTINUITY.md`
- `72bb5307b60de3d2f3b1122a526fe34a6c68210f` — `docs/engineering/CONVERSATION_INDEX.md`

## Parent PR #45 qualification

PR #45 exact HEAD `218d07c637738c14541482d067954325f16da224`:
- CI run `44227375230`: Backend Toolchain, Repository Hygiene, Intel x86_64 Debug/XCTest/Release/Swift CodeQL, Apple Silicon arm64 Debug/XCTest/Release passed.
- Mermaid run `44227375328`: passed.
- Local Sync Safety run `44227375239`: passed.
- Apple Silicon CodeQL is intentionally skipped by the workflow matrix.

## Verification status

- Child-branch hosted CI: pending.
- Local Xcode build/XCTest: not run in this remote session.
- Owner-Mac runtime, visual/accessibility, and authenticated Capital.com DEMO acceptance: not verified.
- No market-data persistence, synthetic bars, indicators, drawing tools, trading execution, risk-policy change, or LIVE capability added.
- `CAP_ALLOW_TRADING=false` remains unchanged.

## Next action

Open a focused draft PR against `feat/live-candle-aggregation`, then verify the exact final head across Intel, Apple Silicon, backend, repository hygiene, Mermaid, and Local Sync Safety.
