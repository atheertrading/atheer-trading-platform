# Local API Health Contract

**Document ID:** ATP-API-002  
**Status:** Accepted engineering contract for the local development vertical slice  
**Authority:** Delegated Engineering Authority  
**Scope:** Local ATHEER API process only  
**Owner approval:** Not claimed

## Purpose

Provide a truthful operational signal for the first backend process without prematurely defining the platform's full REST, WebSocket, IPC, or event architecture.

## Binding and configuration

- Default bind address: 127.0.0.1.
- Default port: 4100.
- HOST accepts only 127.0.0.1.
- PORT must be an integer from 1 through 65535.
- Invalid configuration prevents startup.

The service is local-development-only. It must not bind to 0.0.0.0 or a public/LAN interface.

## Routes

### GET /health/live

Returns HTTP 200 when the API process can accept and answer an HTTP request.

Response fields:
- status: ok
- service: atheer-api
- version: 0.1.0
- timestamp: ISO 8601 response time

Liveness does not imply persistence, broker, market-data, or trading readiness.

### GET /health/ready

Returns HTTP 503 until the required platform dependencies are implemented and verified.

Current response fields:
- status: not_ready
- service: atheer-api
- timestamp: ISO 8601 response time
- dependencies.persistence: not_configured
- dependencies.broker: not_configured
- trading.enabled: false
- trading.status: disabled

This status is intentional. It must not be changed to ready using mock values or assumed connectivity.

## Error behavior

- Unknown paths return HTTP 404 with a stable not_found error.
- Non-GET requests to known health paths return HTTP 405 and Allow: GET.
- Responses use application/json and Cache-Control: no-store.

## Explicit exclusions

This contract does not define business API transport, authentication, authorization, user identity, database schemas, broker authentication, market-data schemas, order states, risk formulas, event delivery, or persistence semantics. Those require source reconciliation and separate contracts.

No endpoint in this service can submit orders or alter financial state.
