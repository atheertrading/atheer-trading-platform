# ATP-CHART-001 — Historical Chart Workspace

**Screen ID:** SCR-CHART-001  
**Branch:** feat/historical-chart-workspace  
**Parent:** PR #43 — Command Center Live Market Watch  
**Provider:** Capital.com DEMO historical market-data endpoint  
**Capability:** Read-only historical Bid/Ask OHLC visualization

## Objective

Replace the Command Center's static no-series chart surface with a working native historical candlestick chart and expose the same app-scoped chart capability through Charts & Analysis navigation.

## Data contract

The chart client consumes the existing GET /market-data/history response. It does not introduce a second provider adapter or bypass the backend.

- Provider and environment must be exactly capital.com and DEMO.
- Instrument and resolution must match the request.
- Bid and Ask OHLC remain separate; the UI selects one side at a time.
- Prices must be finite and positive; each OHLC range must be internally consistent.
- Ask must not be below Bid at any OHLC point.
- Candle timestamps must be positive, unique, and strictly increasing.
- Receipt timestamps and provider timestamps remain distinct.
- Provider volume is retained only as the explicitly named lastTradedVolume lineage; it is not presented as exchange volume.
- Duplicate and observed-gap metadata is displayed as data-quality context. Gaps are not classified as missing until a market-session calendar exists.

## Application ownership

ContentView owns one MarketChartViewModel. The same instance is injected into ChartWorkspaceView and CommandCenterView. The chart selects only instruments in the persistent MarketWatchlistStore; removing the selected instrument clears the displayed series.

MarketHistoryClient owns transport. MarketHistoryPayloadDecoder validates provider provenance and financial invariants. MarketChartViewModel owns request generation, selection, loading, stale-result suppression, and presentation state. SwiftUI views render the state and never perform financial calculations or broker operations.

## Implemented in this increment

- Native Charts-based candlestick rendering from provider-normalized historical data.
- Instrument selection from the persistent watchlist.
- Provider-supported timeframe selection.
- Explicit Bid or Ask OHLC selection; no synthetic mid candles.
- Refresh, loading, empty, unavailable, and error states.
- Command Center chart panel and dedicated Charts & Analysis destination share the same model.
- Deterministic decoder, model, and view-construction tests.
- Mermaid diagram 15 and engineering continuity records.

## Explicit non-scope

- Live candle aggregation from the streaming quote feed.
- Synthetic mid-price candles.
- Technical indicators, drawing tools, market-session overlays, multi-chart layouts, and strategy synchronization.
- Account data, order entry, RiskEngine, OMS, Execution Gateway, or broker dealing.
- Backtest, SIMULATION, or LIVE data/execution.

## Verification boundary

The code is committed on a branch stacked on PR #43. Hosted Intel and Apple Silicon CI must pass on the exact head. No local Mac build, visual QA, authenticated Capital.com DEMO request, or runtime acceptance is claimed by the source commit alone.
