# Position Management Specification

**Status:** Core position aggregate and reconciliation comparison implemented; broker synchronization and persistence not implemented.

## Current aggregate

`TradingPosition` models stable position/account/instrument IDs, LONG/SHORT side, positive quantity, average entry price, calculated realized P&L, stop-loss/take-profit references, OPEN/PARTIALLY_CLOSED/CLOSED lifecycle, timestamps and provenance.

- `increase` recalculates weighted average entry price.
- `close` supports partial or full close and rejects over-close.
- `unrealizedPnl` and `grossExposure` are calculated only when a caller supplies a mark and contract multiplier.
- Linear long/short P&L is a local calculation, not a broker-authoritative account value.

## Reconciliation authority

`BrokerPositionSnapshot` retains broker-reported side, quantity, average entry, realized/unrealized P&L, observation time and provenance. `reconcilePosition` reports field discrepancies and returns the broker snapshot unchanged as the authoritative external state. It does not silently overwrite broker data or invent a reconciliation resolution.

## Unresolved semantics

Broker netting/hedging mode, multiple trades per instrument, partial close allocation, FIFO/LIFO/average-cost policy, fees, financing, dividends, FX conversion, corporate actions, options/inverse contracts, stop modification authority and strategy ownership transfer require formal source reconciliation and broker contract review.
