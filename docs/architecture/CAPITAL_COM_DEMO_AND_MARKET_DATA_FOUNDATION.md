# Capital.com DEMO and Market Data Foundation

**Status:** Implementation baseline under qualification  
**Scope:** Provider connectivity and read-only market-data ingestion  
**Environment:** Capital.com DEMO only

## 1. Provider boundary

Capital.com is accessed through a backend-owned adapter. The macOS client must never receive the API key, account identifier, API password, CST, or X-SECURITY-TOKEN. Provider credentials and session tokens must not be logged, returned by HTTP routes, or persisted in source control.

The current adapter is deliberately DEMO-only. Its base URL is fixed to `https://demo-api-capital.backend-capital.com/api/v1`; it exposes session creation/termination, session ping, market search, and historical prices. It contains no order placement, order cancellation, position dealing, account mutation, or LIVE endpoint method.

Capital.com currently documents that generated API keys have trading privileges and that no read-only API key can be generated. Therefore, the provider adapter must remain capability-restricted in ATHEER: do not expose dealing methods, do not accept caller-supplied base URLs, and keep trading disabled. DEMO account credentials only are permitted in this milestone.

## 2. Session contract

- Create sessions using `POST /session` with `X-CAP-API-KEY`, `identifier`, `password`, and `encryptedPassword: false`.
- Capture `CST` and `X-SECURITY-TOKEN` from response headers.
- Pass both headers on authenticated requests.
- Session lifetime is documented as ten minutes after last use; session ping must be used to maintain an active session.
- Session creation is rate-limited; avoid repeated login attempts and do not implement blind retry.
- Error messages must not include request headers, credentials, tokens, or raw provider response bodies.

## 3. Market-data pipeline

`CapitalDemoClient` is an infrastructure adapter. Provider payloads are normalized into provider-neutral market-data contracts before publication.

A normalized quote records both:
- `providerTimestampMs`: timestamp supplied by Capital.com.
- `receivedAtMs`: local receipt timestamp.

These values are not interchangeable. Freshness is evaluated against provider time and an explicitly injected policy. Missing, malformed, crossed, future-dated, or stale quotes are not eligible for automated decisions. A disconnected provider or invalid clock/policy fails closed.

The initial quote contract supports bid/ask snapshots. The subsequent streaming increment must implement the documented Capital.com WebSocket protocol, bounded subscriptions (maximum 40 epics), ping, disconnect detection, resubscription, and gap/recovery behavior before Market Watch is described as live.

## 4. Data provenance and UI

Every displayed market value must carry provider identity, environment, instrument epic, provider timestamp, local receive timestamp, and freshness/connection state. DEMO data must be labeled DEMO. No UI may imply LIVE data, real balances, or real positions from this integration.

When the provider is disconnected, the last value may be retained only if visibly marked stale with its timestamp. Automated decisions and execution must be blocked until a fresh, validated provider update is received and the connection state is healthy.

## 5. Qualification boundary

Mocked contract tests validate request construction, header handling, payload validation, and fail-closed freshness behavior. They do not prove credentials, network access, or Capital.com DEMO account connectivity. Provider integration qualification requires an owner-provided DEMO API key, identifier, and API-key password supplied through a secure local secret store/environment—not through GitHub, source code, or chat—and an observed authenticated DEMO session plus real provider response evidence.

No LIVE account, LIVE endpoint, order execution, or trading permission is part of this foundation.
