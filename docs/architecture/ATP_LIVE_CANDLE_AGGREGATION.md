# ATP-MKT-006 — Live DEMO Quote-to-Candle Aggregation

**Screen integration:** SCR-CHART-001 / Command Center Chart Workspace  
**Branch:** feat/live-candle-aggregation  
**Parent:** PR #44 — Historical Chart Workspace  
**Provider:** Capital.com DEMO timestamped streaming quotes  
**Capability:** Volatile, read-only intraday OHLC aggregation

## Objective

Extend the historical chart with live quote-derived candles while preserving provider timestamp and price-side semantics. Every validated stream quote must reach analytical consumers before Market Watch's 100 ms presentation coalescing can discard intermediate ticks.

## Data flow and ownership

- MarketExplorerViewModel remains the owner of the DEMO SSE stream lifecycle and selected instrument subscriptions.
- MarketDataQuoteEventBus is an app-scoped in-process fan-out boundary. It publishes each accepted stream event before the presentation throttle. The chart aggregator processes every tick into a private working series, while MarketChartViewModel publishes a coalesced presentation snapshot at 100 ms.
- LiveCandleAggregator is a deterministic value-type component. It owns UTC interval bucketing, monotonic provider-timestamp checks, and Bid/Ask OHLC updates.
- MarketChartViewModel owns the chart projection, request lifecycle, historical bootstrap, and volatile live updates.
- SwiftUI chart surfaces render MarketChartCandle; they do not aggregate prices or access broker APIs.

## Acceptance rules

1. Provider and environment must be exactly capital.com and DEMO.
2. Instrument must match the currently selected chart instrument.
3. Quote prices must be finite, positive, and non-crossed.
4. Provider and receipt timestamps must be positive; provider time may not exceed receipt time by more than the existing 250 ms future-skew policy.
5. Quote freshness must be fresh, have a finite age within -250..5000 ms, and explicitly allow automated decisions.
6. Provider timestamps must be strictly increasing for the active chart series; duplicates and out-of-order events are ignored.
7. Bid and Ask OHLC are updated independently. Open is immutable after the first quote in a bucket; high/low are extrema; close is the latest accepted quote.
8. A quote in the current final candle bucket updates that candle. A later bucket appends exactly one bar. No gap filling or interpolation occurs.
9. Newly aggregated bars do not claim provider volume. Existing historical provider-volume lineage remains explicitly provider-reported.
10. The current increment aggregates fixed UTC intraday resolutions MINUTE, MINUTE_5, MINUTE_15, MINUTE_30 and HOUR. HOUR_4, DAY and WEEK remain historical-only until provider/session-calendar alignment is specified.
11. Retain at most 500 candles in the active in-memory series, matching the historical bootstrap maximum. When a later bucket is appended beyond the limit, discard the oldest candle while preserving chronological order and the newest OHLC/provenance. Never fill gaps.

## Failure and recovery

- Invalid, stale, future-dated, wrong-instrument, duplicate, out-of-order, or unsupported-resolution quotes are ignored without mutating the chart.
- A new historical request, instrument change, or timeframe change resets the aggregation sequence.
- No synthetic candle is created to bridge a gap.
- Live bars are in-memory only, bounded to 500 candles per active chart series, and disappear when the chart model is recreated or historical data is refreshed.
- If streaming disconnects, the last rendered bar remains visible as last-known data; no new quote is accepted until the stream supplies a valid fresh event.

## Explicit non-scope

- Market-session calendars, daily/weekly/4-hour live aggregation, synthetic gap bars, or historical backfill.
- Durable candle storage, volume aggregation, indicators, drawing tools, alerts, strategy synchronization, or backtesting.
- Account state, order entry, RiskEngine, OMS, Execution Gateway, broker dealing, SIMULATION, BACKTEST, or LIVE.
- Changes to broker credentials, account permissions, risk limits, or trading capability.

## Verification

Deterministic XCTest coverage includes independent Bid/Ask updates, OHLC extrema/close semantics, no-gap-fill behavior, stale/future/out-of-order rejection, unsupported session-aligned resolutions, and app-scoped quote-bus delivery. Hosted Intel and Apple Silicon qualification is required on the exact PR head.

`CAP_ALLOW_TRADING=false` remains unchanged.
