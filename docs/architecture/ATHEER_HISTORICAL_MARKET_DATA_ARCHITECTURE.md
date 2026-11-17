# ATHEER Trading Pro — Historical Market Data Contracts

**Work package:** ATP-MKT-005  
**Status:** Implemented on focused branch; exact-head CI pending  
**Provider:** Capital.com DEMO  
**Scope:** Historical price request validation, provider response normalization, bid/ask OHLC integrity, UTC lineage, duplicate detection, and observed-gap reporting.

## 1. Provider contract

The adapter calls Capital.com DEMO `GET /prices/{epic}` with:

- `resolution`: MINUTE, MINUTE_5, MINUTE_15, MINUTE_30, HOUR, HOUR_4, DAY, or WEEK.
- `max`: integer 1–1000 (provider maximum).
- `from` and `to`: optional as a pair. The ATHEER API accepts explicit UTC ISO-second values (`YYYY-MM-DDTHH:mm:ssZ`) and translates them to Capital.com's documented UTC date-time form without the trailing `Z`.

Official provider reference: [Capital.com Public API — Historical prices](https://open-api.capital.com/).

A date range must contain both bounds and `from` must precede `to`. The provider's `max` limit is enforced before and after the request. The response reports `pagination.limitReached` when the requested count is reached; this means the range may require a narrower follow-up request, not that the provider has confirmed additional records.

The current API does not fabricate an opaque continuation cursor. Automatic range partitioning is deferred until inclusive/exclusive boundary behavior is verified against the live DEMO provider.

## 2. Canonical candle contract

Each provider record is normalized into:

- Provider identity: `capital.com`.
- Environment: `DEMO`.
- Instrument identity: provider epic.
- Resolution.
- UTC epoch-millisecond candle timestamp from `snapshotTimeUTC`.
- Independent Bid OHLC.
- Independent Ask OHLC.
- Local `receivedAtMs` captured when the response is normalized.
- Optional raw `lastTradedVolume` retained as `providerVolume` with `providerVolumeField: "lastTradedVolume"`.

Bid and Ask OHLC are never combined into synthetic mid prices. The provider volume field is retained without claiming that it represents exchange-traded volume, tick count, or another unsupported semantic.

The canonical candle contract is transport/domain-facing and contains no charting or execution authority.

## 3. Validation and data quality

The normalizer:

1. Requires a valid epic and supported resolution.
2. Requires a valid UTC `snapshotTimeUTC`; local wall-clock `snapshotTime` is not used as a fallback.
3. Requires finite, positive Bid and Ask values for each OHLC point.
4. Rejects crossed Bid/Ask values at open, high, low, or close.
5. Validates OHLC high/low consistency independently for Bid and Ask.
6. Preserves optional provider volume only when it is a valid non-negative number.
7. Sorts candles in ascending UTC time.
8. Drops exact duplicate candles and counts them.
9. Rejects conflicting candles with the same timestamp rather than choosing one silently.
10. Reports nominal time gaps as observed gaps requiring a market-session calendar.

A time gap is not automatically classified as missing market data. Weekends, holidays, session breaks, instrument trading hours, and provider omissions must be distinguished by an authoritative market calendar before a gap can be declared missing. No synthetic candles, interpolation, or backfill are generated.

## 4. API behavior

`GET /market-data/history` accepts:

- `epic` (required)
- `resolution` (optional, defaults to MINUTE)
- `max` (optional, defaults to 100; maximum 1000)
- `from` and `to` (optional UTC pair)

The route returns normalized candles, data-quality counts, the original requested range, and whether the result count reached the requested limit. Provider session tokens are never returned.

Invalid input returns HTTP 400. Provider or invalid provider-data failures return a non-sensitive gateway error. No raw provider response body or session credentials are exposed.

## 5. Persistence boundary

This work package deliberately does not claim durable storage. The repository's platform architecture records PostgreSQL as the persistence direction, while operational deployment and workload qualification remain pending. Historical candle storage will be introduced through a repository contract and PostgreSQL migration in a separate increment after the schema, retention, idempotency, and workload requirements are reconciled.

Transactional order/intent state remains separate from analytical and historical market datasets.

## 6. Charting dependency

Charting must consume this normalized candle contract and the separately qualified live candle stream. It must not parse raw Capital.com payloads or derive synthetic Bid/Ask bars. Chart presentation, indicator calculations, strategy configuration, RiskEngine, OMS, and Execution Gateway remain separate concerns.

## 7. Verification

Added deterministic tests cover:
- Bid/Ask OHLC normalization and separation.
- UTC timestamps and local receipt lineage.
- Invalid timestamps, crossed quotes, and inconsistent OHLC.
- Exact duplicate removal and conflicting duplicate rejection.
- Observed gaps without false market-closure assumptions.
- Strict UTC range validation and provider date format conversion.
- `max` boundary and date-range query construction.
- HTTP history response contract and invalid route inputs.

Exact-head backend CI is pending. No live DEMO provider request, durable persistence, Charting integration, or market-calendar completeness is claimed.

## 8. Safety

- Capital.com DEMO only.
- Read-only historical market-data request.
- No dealing or account mutation.
- `CAP_ALLOW_TRADING=false` remains unchanged.
- No RiskEngine/OMS/Execution Gateway integration.
