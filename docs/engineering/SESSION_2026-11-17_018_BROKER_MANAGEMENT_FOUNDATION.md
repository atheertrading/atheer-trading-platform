# Engineering Session 018 — Broker Management and Capital.com DEMO Authentication

**Status:** Initial implementation committed; build and runtime qualification pending.  
**Branch:** `feat/broker-management-keychain-demo`  
**Base:** PR #25 head `bdcdab3592347473ff9ec0ca0a9d4f99d6eccc5b`

## Implemented in this increment

- Added a Settings entry point and a Brokers management destination to the existing native macOS application.
- Added Capital.com DEMO credential entry, edit, and clear flows.
- Added a Keychain-backed credential store. Items are namespaced by broker and environment and use `kSecAttrAccessibleWhenUnlockedThisDeviceOnly`.
- Added a Keychain access abstraction so persistence behavior can be tested without relying on a developer's login Keychain.
- Added a DEMO-only Capital.com REST authentication service. It creates a session with `POST /session`, captures CST and X-SECURITY-TOKEN in memory, and verifies the session using read-only `GET /session`.
- Added explicit connection states and account identity/currency display only when returned by the provider.
- Added read-only session verification every 60 seconds while the Brokers screen is active; verification starts immediately when the screen opens. Provider rejection marks the session expired and clears local session tokens.
- Credential replacement first disconnects the previous session. Credential clearing disconnects before deleting the Keychain item and reports a failure without claiming deletion.
- The connection service contains no order, position-dealing, account mutation, or LIVE endpoint methods.

## Provider contract verification

Official Capital.com API documentation: https://open-api.capital.com/  
Official help article (updated 12 October 2026): https://help.capital.com/hc/en-us/articles/39735999073554-How-can-I-get-CST-and-X-SECURITY-TOKEN-parameters

Verified authentication inputs:
- `X-CAP-API-KEY` header.
- `identifier` account login.
- `password` API-key custom password.
- `encryptedPassword: false` for the documented unencrypted-password flow.

Verified lifecycle:
- `POST /api/v1/session` creates the session.
- CST and X-SECURITY-TOKEN are returned in response headers and required for subsequent authenticated requests.
- `GET /api/v1/session` returns session/account context.
- `DELETE /api/v1/session` terminates the session.
- REST sessions expire after ten minutes of inactivity; the UI must not equate an authenticated REST session with market streaming or trading readiness.

## Security boundary and limitations

- Secrets are persisted only in macOS Keychain; they are not stored in UserDefaults, source files, JSON configuration, or logs.
- Session tokens are held only in the authentication service's in-memory state and cleared locally on disconnect/failure.
- LIVE is represented as a disabled environment and is rejected by the authentication service.
- Capital.com currently documents API keys as trading-capable; no read-only API-key privilege is available. ATHEER therefore exposes no dealing methods in this feature and keeps trading disabled.
- The native app-side Keychain flow is a deliberate implementation boundary for the owner-requested desktop credential workflow. Requests use an ephemeral URLSession configuration with URL caching and cookie persistence disabled; authentication/session requests carry Cache-Control: no-store. It must not be copied into remote clients; future multi-client deployments should move credential ownership to a dedicated secure backend vault with explicit account-level authorization.
- REST authentication does not establish WebSocket market-data streaming.

## Verification status

- Source-level review completed against the existing SwiftUI navigation, token, project, and backend integration conventions.
- Automated tests and Xcode builds have not yet been executed by this GitHub-only implementation session.
- Live Capital.com DEMO authentication has not been performed; no owner credentials were supplied.
- Phase A CI qualification remains separate and blocked as previously recorded.

## Additional account isolation and authentication tests

- Credential collections are stored in one Keychain item per broker/environment and keyed internally by normalized account login identity. The most recently saved identity is selected by default; account-specific load/delete operations preserve other stored identities.
- Added URLProtocol-based authentication tests:
  - `testDemoAuthenticationUsesOfficialRequestContractAndVerifiesSession`
  - `testDemoAuthenticationMapsUnauthorizedResponseWithoutExposingSecrets`
  - `testLiveEnvironmentIsRejectedBeforeNetworkAccess`
- Authentication requests use an ephemeral URLSession with URL caching and cookie persistence disabled, plus Cache-Control: no-store.

- The workspace distinguishes the last successful authentication time from the latest session verification time. These timestamps are currently in-memory only and reset after application restart; persistence of non-secret connection metadata remains a follow-up.
