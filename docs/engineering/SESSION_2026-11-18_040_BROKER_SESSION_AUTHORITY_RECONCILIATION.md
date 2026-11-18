# ATP-2026-11-18-040 — Broker Credential and Session Authority Reconciliation

**Date:** 2026-11-18  
**Repository:** `atheertrading/atheer-trading-platform`  
**Branch:** `feat/capital-demo-market-streaming-qualified`  
**Related PRs:** #26, #37  
**Task:** ATP-BRK-002  
**Decision:** EDL-022

## Owner-library requirements reviewed

- Broker Integration Q5: backend receives credentials through a protected process; backend establishes the Capital.com session, owns CST and X-SECURITY-TOKEN, monitors expiry and renews sessions.
- Broker Integration Q6: centralized backend CMS, encrypted storage, least-privilege access, environment isolation, lifecycle management, audit without secret logging.
- The Library requires the broker session to be centralized rather than independently owned by UI, Market Data, AI or strategy modules.

## Current implementation discrepancy

- PR #26: macOS Keychain credential storage with direct Swift-side Capital.com authentication and a Swift-owned session.
- PR #37: Node backend reads independent API key/identifier/password values from environment variables and creates a separate Capital.com session.
- This can create duplicate sessions and inconsistent connection/expiry/reconnect state. Environment variables are not the approved production credential store.

## Decision

One backend Credential Management Service and Broker Session Manager must own credentials and the broker session. The native macOS UI is a secure credential-entry/management client. The backend owns authentication and CST/X-SECURITY-TOKEN lifecycle. Market Data, streaming, Account Data and future OMS share this single managed session.

## Required implementation

1. Design authenticated local provisioning using a per-launch capability token or authenticated local IPC; the browser-origin marker alone is insufficient.
2. Implement backend CMS with encrypted vault/Keychain-backed storage, provider/account/environment isolation and audit-safe lifecycle operations.
3. Make the backend Broker Session Manager the sole Capital.com session owner.
4. Refactor Swift Broker Management to delegate connect/status/disconnect to the backend; remove duplicate direct Swift authentication after parity tests.
5. Replace production environment-credential use in `CapitalDemoRuntime`; retain env credentials only for isolated tests/development.
6. Route Market Data, streaming and future account/OMS services through the same session.
7. Test environment isolation, token secrecy, expiry, renewal, reconnect, concurrent connect, no-secret logs and local IPC authorization.
8. Complete DEMO qualification before any Live authorization. LIVE remains disabled.

## Merge gate

PR #37 remains draft and must not be merged as the completed broker integration until ATP-BRK-002 is implemented and DEMO-qualified.

## Documentation commits

- `5b221aa45cd1224caa8eb48b9ea5da2605c8e259` — `SECURITY.md`
- `923bff496c25a2f5576e9fe8409e4ecf0de10b04` — `docs/architecture/ATHEER_MARKET_DATA_STREAMING_ARCHITECTURE.md`
- `130fb1526f1bd57dc98a783dce0590c892f97052` — `docs/engineering/TASK_REGISTER.md`
- `b7ee36c17f79388d263131ba6572963d52d5586a` — `docs/engineering/IMPLEMENTATION_STATUS.md`
- `69d5944ccf80143b6a5e82355e0ccc872c6e617c` — `docs/engineering/ENGINEERING_DECISION_LOG.md`
- `efc6e079d74f8334b450916f8f3394c80a1f86ac` — `docs/engineering/PROJECT_CONTINUITY.md`
- `e84b09f674928e46eed33635bd6efab32a0fec79` — `docs/engineering/CONVERSATION_INDEX.md`

## Safety

No real broker credentials or sessions were accessed. No LIVE authentication, dealing or order execution was enabled.
