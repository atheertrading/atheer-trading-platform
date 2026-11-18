# ATHEER Trading Pro — Authenticated Historical Chart Workspace

**Status:** Implemented on PR #69 branch; exact-head CI and macOS qualification pending  
**Workstream:** ATP-CHART-001  
**Provider scope:** Capital.com DEMO historical prices only  
**Execution scope:** Read-only; no order submission

## Purpose

Provide a real historical candlestick workspace that consumes the authenticated historical market-data API. The chart is integrated into the Markets navigation and Command Center rather than being a disconnected preview.

## Application flow

1. A user searches for an instrument in Market Explorer.
2. The instrument row's **Chart** action stores the selected epic in the application workspace state and navigates to Charts.
3. The Charts workspace and Command Center chart panel use the same authenticated history-client contract.
4. The MarketChartViewModel requests the selected epic, timeframe and a bounded maximum of 500 provider records.
5. The URLSessionMarketHistoryClient builds its URL from the supervised BackendIPCConnection dynamic base URL and attaches the private IPC bearer capability plus the safe native-client context header.
6. The backend validates the capability, broker-session state, epic, resolution and request limit; it then uses BrokerSessionManager → CapitalDemoRuntime → CapitalDemoClient.
7. The backend normalizes provider records into separate Bid and Ask OHLC candles with UTC timestamp, local receipt time, volume provenance, duplicate counts and observed timestamp gaps.
8. The MarketHistoryPayloadDecoder validates provider/environment identity, instrument and resolution, OHLC integrity, Bid/Ask ordering, timestamps, raw record count and pagination consistency before the chart model publishes the batch.

## UI behavior

- Dedicated **Charts** navigation item.
- **Open Chart** action from each Market Explorer result.
- Command Center chart panel uses the same historical data client and chart surface.
- Timeframe selection: 1m, 5m, 15m, 30m, 1h, 4h, 1D and 1W.
- Bid/Ask side selection; no synthetic midpoint candles.
- Manual refresh; no fabricated or placeholder prices.
- Visible provider record-limit warning when pagination.limitReached is true.
- Observed gaps and duplicate counts remain visible; no automatic gap filling or market-calendar inference.

## Authentication and data handling

- The client uses the managed backend's dynamic loopback URL; it does not hard-code a port.
- Every request carries the private IPC bearer capability and X-ATHEER-LOCAL-CLIENT: macOS.
- The URLSession configuration is ephemeral, disables cookies and URL caching, and sends Cache-Control: no-store.
- The provider session tokens and credentials remain backend-owned and are never decoded or displayed by the macOS client.
- HTTP 401, 502 and 503 responses are mapped to explicit authentication, provider and broker-session states.
- Request cancellation remains cancellation; it is not misreported as a provider failure.

## Scope boundaries

This batch implements historical candles only. It does not yet include:

- Persistent Market Watch or a saved watchlist.
- Live candle aggregation or live OHLC updates.
- Technical indicators, drawing tools, replay, multi-chart layouts or alerts.
- User-selected historical date ranges in the macOS chart controls (the backend API already supports strict UTC bounds).
- Trading, risk authorization, OMS or execution actions.

These are separate increments. The historical chart must not be treated as a live quote or executable signal source.

## Verification

- Swift decoder tests cover separate Bid/Ask values, provider lineage, OHLC validation, crossed sides, raw record limits, pagination consistency and dynamic IPC request construction.
- View-model tests cover instrument selection, receipt-time handling and cancellation.
- Hosted macOS CI and owner-Mac build/test qualification are pending; no local Xcode result is claimed.

## Mermaid

See docs/architecture/diagrams/11-authenticated-historical-chart-workspace.mmd.
