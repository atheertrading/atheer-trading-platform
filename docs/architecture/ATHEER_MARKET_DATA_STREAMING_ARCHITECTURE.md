# ATHEER Trading Pro — Capital.com DEMO Streaming Architecture

**Work package:** ATP-MKT-003  
**Status:** IMPLEMENTED ON FOCUSED BRANCH — HOSTED VERIFICATION PENDING  
**Scope:** Backend provider WebSocket ingestion and local SSE relay. No new application screen.

## 1. Purpose and boundary

This increment extends the existing Capital.com DEMO REST foundation with a server-side real-time quote stream. It does not implement the macOS presentation consumer, historical persistence, OHLC subscriptions, Charting, or trading execution.

The provider credentials and session tokens remain in the backend. The macOS application receives normalized quote events over the local API and never receives CST or X-SECURITY-TOKEN.

## 2. Provider contract

The implementation follows the current Capital.com Public API contract:

1. Authenticate against the existing DEMO REST base URL.
2. Call `GET /session` using the session headers and read the provider-returned `streamEndpoint`.
3. Validate that the endpoint uses WSS and the documented Capital.com streaming host.
4. Resolve the provider's `/connect` path from that session endpoint; do not hardcode a separate streaming host.
5. Send `marketData.subscribe` and `marketData.unsubscribe` messages with correlation IDs and server-held session tokens.
6. Accept quote messages from `destination: "quote"`; map `epic`, `bid`, `ofr`, and provider `timestamp`.
7. Send the provider `ping` message every five minutes, below the documented ten-minute keepalive interval.
8. On interruption, reconnect with bounded exponential backoff and restore the desired subscription set.

Capital.com documents a maximum of 40 subscribed instruments per WebSocket session. The runtime enforces that cap across all local consumers, not merely per individual SSE request.

Official reference: [Capital.com Public API — WebSocket API and Session Details](https://open-api.capital.com/).

## 3. Runtime pipeline

`CapitalDemoStreamingRuntime` owns one shared provider socket per API process:

- Session information is obtained through `CapitalDemoRuntime`; tokens are not returned by public API routes.
- Subscriptions are reference-counted through consumer registrations and reconciled to the provider's desired epic set.
- Provider acknowledgements are correlated and time-bounded.
- Quote payloads pass through the existing normalization and freshness contract.
- Invalid payloads, duplicate updates, and out-of-order timestamps are counted and rejected.
- Latest valid quote snapshots are retained in memory.
- All valid quote updates are fanned out to matching local subscribers.

The stream runtime does not silently synthesize, interpolate, or backfill missing market data.

## 4. Local application transport

The API exposes:

| Endpoint | Contract |
|---|---|
| `GET /market-data/status` | REST session status plus WebSocket stream status and data-quality counters |
| `GET /market-data/stream?epics=AAPL,GOLD` | Server-Sent Events for validated instrument epics |
| `POST /market-data/disconnect` | Stops the provider stream before terminating the DEMO REST session |

The API host is restricted to `127.0.0.1` by the existing runtime configuration. The SSE endpoint is not intended to be exposed on a network interface; remote exposure requires an authenticated client boundary and explicit security review.

SSE events:
- `status`: initial stream state
- `quote`: normalized provider quote
- `error`: non-sensitive connection failure category

Provider tokens are never included in SSE payloads, status responses, or logs.

## 5. Data integrity and timing

- Provider event time remains the source timestamp; local receive time is stored separately.
- A monotonic receive timestamp is captured for elapsed-time analysis.
- Bid and Ask must be finite, positive, and non-crossed.
- Instrument identity and provider timestamp must be valid.
- A timestamp older than the last accepted timestamp for the same epic is rejected.
- Exact duplicate timestamp/Bid/Ask tuples are ignored.
- The existing 5-second quote-age policy is applied as an arrival-time data-quality assessment only.

**Important safety boundary:** this increment does not authorize execution. The freshness result is not connected to RiskEngine, OMS, or Execution Gateway. A future RiskEngine integration must re-evaluate quote age at decision time and apply operation-specific limits, market-session context, feed health, and broker-side protections. A quiet or unchanged market must not be classified as disconnected solely because no price changed.

## 6. Explicitly not implemented

- macOS `URLSession` SSE consumer and Market Explorer live quote presentation.
- Provider OHLC WebSocket subscriptions.
- Historical candle normalization, pagination, durable storage, gap recovery, and dataset lineage.
- Charting Engine and indicator computation.
- RiskEngine consumption of quote events.
- Any order, dealing, position mutation, or LIVE functionality.

The next vertical slice should connect the existing Market Explorer to this stream without creating another screen. Charting follows only after the normalized historical/live candle contract is qualified.

## 7. Verification

The branch adds tests for:
- Provider-returned streaming endpoint and strict host validation.
- DEMO token headers and server-side token isolation.
- WebSocket connection path, subscription messages, and acknowledgement handling.
- Invalid, duplicate, and out-of-order quote rejection.
- 40-instrument subscription ceiling.
- Reconnection and subscription restoration.
- SSE event framing, client-disconnect cleanup, and invalid subscription rejection.

Hosted TypeScript/API tests and macOS qualification are pending. No live Capital.com connection, real quote receipt, or successful provider authentication is claimed.

## 8. Safety

- DEMO only.
- `CAP_ALLOW_TRADING=false` remains unchanged.
- No order/dealing API methods are added.
- No RiskEngine, OMS, Execution Gateway, broker permission, credential, or LIVE behavior is changed.
- Manual and automated order governance is unaffected.
