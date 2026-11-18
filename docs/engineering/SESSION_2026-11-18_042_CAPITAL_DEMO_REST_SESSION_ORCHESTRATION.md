# SESSION_2026-11-18_042 — Capital.com REST Session Orchestration

**Branch:** `feat/capital-demo-session-orchestration`  
**Parent:** PR #37 head `e8c2a8c321d6cd8f54ff4c17e499474e6b700414`  
**Task:** ATP-BRK-003 / EDL-023

## Implementation

- Added minimum one-second delay between sequential `POST /session` attempts in the single `CapitalDemoRuntime` owner. Concurrent `connect()` calls remain coalesced.
- Added five-minute scheduled REST `GET /ping`, below Capital.com's documented ten-minute inactivity interval.
- Keepalive is cancelled on disconnect; disconnect waits for an in-flight keepalive before terminating the session.
- HTTP 401/403 invalidates the current session. Other provider HTTP failures transition to `degraded`; a successful keepalive restores `connected`.
- Session timing is validated: authentication attempts cannot be configured faster than one per second and REST keepalive must be scheduled before ten minutes.
- Provider error messages are normalized before exposing them in runtime status; raw credentials and session tokens are not added to status.

## Tests added

- Sequential reconnect waits for the one-second session-creation slot.
- Keepalive scheduling interval, invocation and cancellation.
- Transient HTTP 503 degrades the session; subsequent successful ping restores connectivity.

## Explicit limitations

- Rate limiting is currently scoped to the single runtime instance. ATP-BRK-002 must guarantee one shared throttle across all backend session consumers using the same API key.
- Credentials still enter this runtime through the existing environment-based development path. Production CMS/Keychain provisioning and authenticated local IPC remain unimplemented.
- No authentic Capital.com DEMO credentials or broker session were used.
- No LIVE, dealing or order-placement capability was added.
- Exact-head CI and independent runtime verification are pending.

## Documentation commits

- Project continuity: `e50f0117e42fac73359c9ea7c544751d764f3020`
- Conversation index: `edd90ca17a7a41806e0660ab79d2ac81960a1193`
