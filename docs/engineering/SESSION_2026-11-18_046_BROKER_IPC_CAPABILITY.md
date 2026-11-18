# SESSION_2026-11-18_046 — Broker IPC Capability Boundary

**Repository:** `atheertrading/atheer-trading-platform`  
**Documentation branch:** `docs/session-2026-11-18-engineering-continuation`  
**Main baseline:** `3bb2f0b68c11eff019bbd88ce09cf3b7155b9ea4`  
**Implementation PR:** #51  
**Current implementation head:** `1e312352696bcc5e18ba00a15dc426d37aa26c5a`

## Scope and implementation

PR #51 is the first bounded ATP-BRK-002 implementation slice, created from current `main`:

- `services/api/src/security/ipc-capability.ts`: canonical 256-bit base64url capability bootstrap from private stdin; constant-time bearer validation; bounded input; temporary byte-buffer clearing.
- `services/api/src/main.ts`: require the startup capability before binding the service and clear it immediately during shutdown.
- `services/api/src/server.ts`: fail closed with HTTP 401 for every `/market-data/*` route without the capability.
- `services/api/types/node-builtins.d.ts`, `services/api/types/node-crypto.d.ts`: narrow local Node declarations; no new runtime dependency.
- `services/api/test/ipc-capability.test.mjs` and `services/api/test/market-data-runtime.test.mjs`: valid/invalid bootstrap, size limit, unauthenticated denial, repeated authenticated requests, and market-data behavior.
- `scripts/backend-dev.sh` and `Makefile`: local development bootstrap uses a unique temporary directory (0700) and capability file (0600), removes it on exit, and supplies the capability only through stdin.

## Verification

- CI run `44268533151` on parent head `df97d30ec4b46bd369b3a3efb6a1ce890f1b8e59`: backend type-check, backend tests, and repository hygiene passed.
- CodeQL run `44268533257` on that parent head passed.
- Intel and Apple Silicon jobs in that run were cancelled when superseded; they are not counted as passes.
- Current head `1e312352696bcc5e18ba00a15dc426d37aa26c5a`: Local Sync Safety `44268907711` passed.
- The changes after `df97d30` are limited to local temporary-directory isolation, earlier shutdown capability clearing, and clearing copied stdin chunks. A full CI result for the current exact head is not available in this report.
- Earlier intermediate test failures were diagnosed and fixed: Node typings were deliberately minimal in this repository; the first type-check exposed missing declarations. Tests then exposed Buffer.slice aliasing that cleared the retained capability and an unauthenticated wrong-method fixture. The implementation now copies with `Uint8Array.from`, and the test exercises repeated authorized requests.

## Integration gate — do not merge yet

The current native `URLSessionMarketSearchClient` does not yet attach the IPC bearer capability. The app also does not yet own a supervised backend child process or send the capability through a private pipe. Merging PR #51 before that app-side integration would make native market-data requests receive HTTP 401.

Still required:
1. Swift capability generation using the platform cryptographic random source.
2. App-managed backend process lifecycle and private stdin bootstrap.
3. Authenticated Swift market-data client and backend status/session integration.
4. Credential handoff from Keychain through authenticated IPC; remove the independent direct native Capital.com authentication authority.
5. Backend-owned credential/session lifecycle and restart/account-switch tests.
6. A packaged/runtime strategy for Node and compiled API assets; the current repository developer setup requires Node 24 and is not yet a distributable app bundle.
7. Exact-head Intel and Apple Silicon qualification before merge.

The existing backend broker credential adapter still reads environment variables. The local development script is explicitly a developer diagnostic path, not the production credential bridge. ATP-BRK-002 remains PARTIAL.

## Trading safety and workstation boundary

- No broker credentials were accessed.
- No authentic Capital.com DEMO session was created.
- No order, dealing, or LIVE endpoint was called.
- Trading remains disabled.
- No local Mac shell/worktree was available. No local pull, Xcode build, launch, Keychain qualification, or visual QA is claimed.

## Next batch

Continue ATP-BRK-002 with the Swift process supervisor, capability provider, authenticated market-data client, and app composition-root integration. Preserve the current Keychain implementation as the secure credential persistence layer during migration; make the backend the only broker-session owner. Only then merge the server capability boundary and proceed to reconstruct PR #37's diverged streaming stack.
