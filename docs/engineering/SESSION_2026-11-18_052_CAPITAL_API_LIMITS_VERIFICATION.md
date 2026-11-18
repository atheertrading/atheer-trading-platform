# Engineering Session 052 — Capital.com API Limits Verification

**Date:** 2026-11-18  
**Batch:** ATP-2026-11-18-052  
**Repository:** `atheertrading/atheer-trading-platform`  
**Branch:** `feat/capital-demo-session-streaming-ipc`  
**Scope:** Official Capital.com API contract verification against the existing DEMO session and streaming implementation.

## 1. Official source verification

Reviewed the current official Capital.com API reference and Help Center:
- API reference: https://open-api.capital.com/
- API limitations: https://help.capital.com/hc/en-us/articles/6630830103058-Do-you-have-any-limitations-on-their-API
- WebSocket API instrument cap: https://help.capital.com/hc/en-us/articles/6630762294418-Which-kind-of-APIs-do-you-have

The current official sources state:
- General API request rate: 10 requests per second per user.
- `POST /session`: one request per second per API key.
- REST session inactivity: 10 minutes; use the ping endpoint to keep the session alive.
- WebSocket session duration/inactivity: 10 minutes; send the documented ping service at least once every 10 minutes.
- WebSocket `marketData.subscribe` capacity: maximum 40 instrument epics.
- DEMO `POST /positions` and `POST /workingorders`: 1,000 requests per hour.
- Changing the active financial account with `PUT /session` interrupts WebSocket streaming.

## 2. Source-to-code reconciliation

| Official requirement | Existing implementation | Assessment |
|---|---|---|
| 10 requests/second per user | `CapitalDemoClient` shared request queue, default 100 ms request-start interval | Implemented per shared client; confirm every future broker REST consumer uses the manager-owned shared client |
| 1 `POST /session` request/second/API key | `CapitalDemoRuntime` and `BrokerSessionManager` enforce a minimum 1,000 ms interval | Implemented; manager-level guard spans runtime replacement |
| REST inactivity under 10 minutes | `CapitalDemoRuntime` defaults to 5-minute ping and rejects intervals at/above 10 minutes | Implemented with a 5-minute safety margin |
| WebSocket ping under 10 minutes | `CapitalDemoStreamingRuntime` sends application-level `destination: "ping"` every 5 minutes with server-held session tokens | Implemented with a 5-minute safety margin |
| Maximum 40 market-data epics | `CapitalDemoStreamingRuntime` validates the shared desired subscription set against 40 | Implemented; status now reports provider-confirmed subscriptions, not merely desired instruments |
| DEMO order endpoint budget | No order/position/working-order route is implemented in this stream slice | Not applicable yet; enforce endpoint-specific quotas in the future OMS/broker adapter before dealing |
| Account switch interrupts stream | No active-account switching workflow is qualified in this slice | Future requirement: invalidate stream subscriptions and reconnect after any `PUT /session` account change |

## 3. Engineering conclusions

- The existing 100 ms shared REST request-start spacing matches the documented 10 req/s per-user ceiling.
- The 1-second session-creation throttle matches the documented per-API-key `POST /session` limit.
- The 5-minute REST and WebSocket pings are conservative relative to the 10-minute session inactivity/duration limit.
- The 40-epic cap is confirmed by current official sources, not merely historical project notes.
- The broker REST client must remain shared through the backend Broker Session Manager. New code must not instantiate independent clients that bypass the process-wide rate queue.
- Any future account-switch operation must stop or invalidate the current WebSocket stream, re-read the active session/account tokens, and re-subscribe only after broker confirmation.
- The future OMS must enforce the documented DEMO position/working-order request budget and the broader 10 req/s per-user budget; no dealing capability was added in this batch.

## 4. Qualification status

This is source-contract verification, not a live broker test. No DEMO credentials were used, no broker session was created, and no orders were sent.

The implementation remains on an unmerged PR stack. Exact-head CI and owner-Mac DEMO authentication/streaming qualification remain pending. Credential handoff confidentiality is still an independent P0 gate documented in EDL-022: the current local HTTP bearer capability authenticates but does not encrypt the credential body.

`CAP_ALLOW_TRADING=false`; LIVE and dealing remain disabled.
