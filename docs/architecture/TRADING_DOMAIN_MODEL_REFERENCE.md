# Trading Domain Model Reference

**Implementation:** `services/api/src/domain/models.ts` and `shared.ts`.

| Model / value | Current contract | Important constraints |
|---|---|---|
| `TradingInstrument` | Stable internal ID, symbol, name, asset class, base/quote currency, specification, generic broker references, active flag | No Capital.com-specific fields |
| `InstrumentSpecification` | Price/quantity precision, tick, step, min/max quantity, multiplier, valuation model, effective time, provenance | Positive tick/step/min/multiplier; explicit precision; no assumed broker defaults |
| `MarketQuote` | Instrument, bid/ask, source, source event time, receive time, optional sequence | Positive bid/ask, bid ≤ ask, receive time ≥ source event time; caller supplies freshness threshold |
| `TradingAccount` | Internal account ID, generic broker ID/reference, environment, currency, status, broker capability and platform authorization | LIVE platform trading cannot be enabled |
| `TradingBalance` | Cash, equity, available, used margin, realized/unrealized P&L, observation time and provenance | All amounts share account currency; broker snapshot source remains authoritative |
| `TradingSession` | Account/environment, UTC start/end, ACTIVE/HALTED/CLOSED state | Explicit immutable state transitions |
| `OrderIntent` | Intent/account/instrument IDs, environment, source, operation, side, type, quantity/prices, position reference, idempotency/correlation/causation IDs | REDUCE/CLOSE require position ID; price parameters depend on order type |
| `TradingOrder` | Order aggregate, intent, lifecycle state, fill quantity, average fill, executions, rejection reason | Actor-constrained transitions; no direct broker call |
| `OrderExecution` | Execution ID, order ID, broker execution reference, quantity, price, event/receive time, optional commission, provenance | Positive values, UTC ordering, duplicate suppression, no overfill |
| `TradingPosition` | Position/account/instrument, LONG/SHORT, quantity, average entry, calculated realized P&L, stop/take-profit, lifecycle, provenance | Partial close and increase; calculated P&L is not broker authority |
| `Trade` | Trade ID linked to position/account/instrument and open/close state | Closed state requires close timestamp |
| `Portfolio` | Account, base currency, positions, observation time, provenance | Same-account positions; no implicit FX conversion |
| `BrokerOrderSnapshot` | Broker reference/status/fill quantity/average fill/time/provenance | Authoritative external comparison input |
| `BrokerPositionSnapshot` | Broker position/quantity/side/entry/P&L/time/provenance | Broker state and financial values remain authoritative |

## Shared primitives

- `Identifier<Kind>` branded IDs for instrument, account, order, intent, position, execution, session, portfolio, trade and broker.
- `Decimal` exact base-10 arithmetic.
- `Money` currency-checked arithmetic.
- `UtcTimestamp` rejects non-UTC/local timestamp strings.
- `DataProvenance` identifies source kind, source ID, observation time and normalization version.

## P&L and exposure limitations

Current calculated position P&L uses the explicit linear formula:

- Long: `(exit or mark price − average entry price) × quantity × contract multiplier`.
- Short: `(average entry price − exit or mark price) × quantity × contract multiplier`.

The calculation is a local projection only. It excludes commissions, spread costs, financing, swaps, dividends, taxes, FX conversion, contract-specific settlement, options Greeks, inverse/quanto valuation and broker netting. Broker-reported financial values supersede local projections for broker account state.
