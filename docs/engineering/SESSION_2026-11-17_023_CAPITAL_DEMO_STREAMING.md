# Session 2026-11-17 — Capital.com DEMO Market Streaming Foundation

**Work package:** ATP-MKT-003  
**Branch:** `feat/capital-demo-market-streaming`  
**Base:** PR #33 latest verified head at branch creation `61b0953a04047868f000709369e2a182b3db34d4`  
**Status:** IMPLEMENTED IN SOURCE AND TESTS — HOSTED VERIFICATION PENDING

## Scope

Add a backend-owned Capital.com DEMO WebSocket quote stream and loopback Server-Sent Events relay. No new macOS screen is added.

## Implementation

- Added `CapitalDemoClient.getStreamingConnectionInfo`, which obtains the provider-returned `streamEndpoint` from authenticated `GET /session` and validates WSS plus the documented Capital.com host.
- Added `CapitalDemoRuntime.getStreamingConnectionInfo` as a server-side session boundary.
- Added `CapitalDemoStreamingRuntime` with a shared provider socket, correlation-ID acknowledgements, 40-instrument ceiling, subscription reconciliation, five-minute WebSocket ping, bounded reconnect backoff, and subscription restoration.
- Normalized provider Bid/Ask/timestamp fields using the existing quote contract; invalid, duplicate, and out-of-order events are rejected and counted.
- Added an in-memory latest quote cache and per-consumer event fan-out.
- Added loopback SSE `GET /market-data/stream?epics=...`, status reporting, keepalive frames, and cleanup on client disconnect.
- Explicit API disconnect now tears down the WebSocket before ending the DEMO REST session.
- Wired stream shutdown into the API service lifecycle.
- Added architecture documentation and Mermaid diagram 09.

## Tests added

- Provider session endpoint and host validation.
- DEMO session headers and token isolation.
- WebSocket path, subscription payload, quote normalization, duplicate/out-of-order rejection.
- 40-instrument cap.
- Reconnect and subscription restoration.
- SSE framing, disconnect cleanup, and invalid subscription rejection.

## Verification status

- Source and tests are committed on the focused branch.
- Hosted TypeScript/API tests have not yet run for this branch.
- No actual Capital.com DEMO authentication or WebSocket connection was attempted.
- No real quote receipt is claimed.
- No macOS SSE consumer or UI integration has been implemented in this increment.
- No owner-Mac build, runtime, visual, keyboard/focus, or VoiceOver test was performed.

## Architecture and safety limits

- Provider CST and X-SECURITY-TOKEN remain server-side.
- The SSE endpoint is only intended for the existing loopback API host `127.0.0.1`; network exposure requires an authenticated transport and security review.
- The 5-second quote-age result is an arrival-time data-quality signal, not an execution authorization.
- Quote events are not wired into RiskEngine, OMS, or Execution Gateway.
- No orders, dealing, positions, account mutation, or LIVE functionality were added.
- `CAP_ALLOW_TRADING=false` remains unchanged.

## Next acceptance gates

1. Exact-head TypeScript build and backend tests.
2. Fix all CI failures and repeat on the exact latest head.
3. Verify provider subscription/heartbeat/reconnect behavior against a configured DEMO account when credentials are available.
4. Integrate SSE into the existing Market Explorer; do not add a screen.
5. Normalize and persist historical candles with source lineage and gap detection.
6. Build the Charting data adapter only after historical and streaming candle contracts are stable.
7. Keep RiskEngine integration separate and fail-closed; no execution use until quote freshness is operation-aware and tested.
