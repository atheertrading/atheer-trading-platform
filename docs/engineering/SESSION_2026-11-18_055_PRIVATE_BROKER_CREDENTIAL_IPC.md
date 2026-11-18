# Engineering Session 055 — Private Broker Credential IPC

**Date:** 2026-11-18  
**Batch:** ATP-2026-11-18-055  
**Repository:** `atheertrading/atheer-trading-platform`  
**Branch:** `fix/broker-credential-unix-domain-ipc`  
**Parent branch:** `feat/market-explorer-live-quotes-integrated`  
**Parent PR branch head:** `e5e57f12217cec694a2eab31d43512e47ddeb618`

## 1. Security finding and selected design

The previous broker-session implementation accepted API key, identifier and password in a loopback HTTP POST body protected by a bearer capability. Loopback binding and bearer authentication do not provide an adequate credential-confidentiality boundary.

Selected replacement: a per-process Unix-domain socket (UDS) dedicated to broker credential connect/disconnect operations. This is a private local IPC channel; HTTP remains for non-secret status and market-data reads.

## 2. Native process and filesystem boundary

- The native supervisor creates a random private temporary directory with POSIX mode 0700.
- The socket path is bounded to Darwin's `sockaddr_un.sun_path` limit (103 UTF-8 path bytes).
- Only the socket path—not credentials or the capability—is passed in the child environment.
- The child environment continues to set `CAP_ALLOW_TRADING=false`; tests assert broker credential environment variables are unset.
- The backend creates the UDS listener and applies socket mode 0600.
- The supervisor does not report ready until HTTP health/status checks pass and the UDS socket exists with mode 0600.
- The parent removes the private directory only after child termination is confirmed.

## 3. Protocol and backend changes

- Each UDS request is one bounded JSON line (8 KiB maximum), with a request ID, action, and the existing 256-bit per-process capability.
- Capability validation uses constant-time comparison.
- Only `connect` and `disconnect` actions are accepted. The payload allowlist is exact; no environment/provider override is accepted, so this channel cannot request LIVE.
- Credential field lengths are bounded. Credentials are not logged and are not returned in responses.
- Provider status returned to the app is sanitized by the DEMO runtime.
- HTTP `POST /broker-session/connect` and `POST /broker-session/disconnect` handlers and method exposure have been removed. HTTP `GET /broker-session/status` remains capability-authenticated.
- The UDS server participates in bounded backend shutdown. Streaming is stopped before broker logout; broker logout still runs if stream shutdown reports failure.

## 4. Native client and lifecycle

- Added a Darwin Unix-domain socket client with bounded read/write timeouts, partial-write handling, response-size limits, request-ID correlation and payload-buffer clearing.
- `BackendBrokerAuthenticationService` now sends credentials and disconnect commands through the UDS transport. Its HTTP executor is used only for non-secret session status.
- Added private socket-directory management and integrated bounded SIGTERM/SIGKILL shutdown from session 053.
- The app termination delegate waits for confirmed backend shutdown and does not claim success when termination is unconfirmed.

## 5. Tests added or updated

- Backend UDS tests: capability rejection, credential redaction, exact DEMO field allowlist, LIVE override rejection, payload bounds, directory/socket permissions, disconnect ordering and logout despite stream shutdown failure.
- Backend HTTP tests: credential connect/disconnect endpoints return 404; session status remains available.
- Capability tests: constant-time value validator accepts only the matching canonical capability.
- Native tests: UDS client request/response round trip, authentication service uses private IPC rather than HTTP POST, socket directory permissions/path bounds, child environment contains no broker credentials, and shutdown cleans the socket directory.
- Existing bounded shutdown tests from session 053 are carried forward.

## 6. Safety and qualification status

- No broker credentials were used in this work.
- No real Capital.com DEMO session was created and no order was sent.
- LIVE trading remains disabled.
- This implements the private credential transport boundary in code; secure broker authentication is not qualified until exact-head CI passes and the owner Mac verifies a real DEMO connection with test credentials.
- PR #65 is intended as a child of PR #64. The branch is 40 commits ahead / 0 behind at report creation; squash merge is recommended to keep the integrated branch history concise.
