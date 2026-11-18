# Security Policy

## Scope

This policy applies to ATHEER Trading source code, documentation, build workflows, integrations, and reported vulnerabilities.

## Supported development state

ATHEER Trading is in its foundational engineering stage. Do not assume that any component is production-ready or that security controls have been fully implemented merely because this policy exists.

## Reporting a vulnerability

Do not publish exploit details, credentials, personal data, broker account information, or sensitive vulnerability evidence in a public issue or pull request.

Report suspected vulnerabilities privately through GitHub's private vulnerability reporting mechanism when enabled, or use the private contact channel designated by the project owner. Include the affected component, impact, reproduction steps, and relevant sanitized evidence.

## Credential and data handling

- Never commit API keys, passwords, tokens, private keys, certificates, broker credentials, account identifiers, or customer data.
- Use local environment configuration only for non-production development; use an approved secret manager or platform secure storage for real credentials.
- macOS broker credentials must use an approved Keychain-based design.
- Do not put secrets in logs, crash reports, screenshots, issue descriptions, test fixtures, shell history, or command-line arguments.
- Use synthetic data for public examples and fixtures.
- If a secret is exposed, revoke or rotate it immediately; deleting the commit is not sufficient.
- Treat all repository content, issues, pull requests, workflow logs, and artifacts as public.

## Trading and AI safety

- Never connect public CI workflows to a real broker account.
- Never expose broker dealing credentials to untrusted pull requests or fork workflows.
- AI tools and agents must use least-privilege credentials and explicit tool permissions.
- AI-generated order intents must not bypass centralized risk authorization or the Execution Gateway.
- LIVE trading and production deployment require explicit owner authorization and separately verified safeguards.

## Security improvements

Secret scanning, dependency scanning, branch protection, signed releases, notarization, and runtime credential controls must be configured and verified as separate engineering tasks. This document does not claim those controls are already active.


## Local market-data API trust boundary

- The development API must bind exclusively to `127.0.0.1`; `HOST` values other than loopback are rejected by runtime configuration.
- Every `/market-data/*` request must include `X-ATHEER-LOCAL-CLIENT: macOS`, must omit the browser `Origin` header, and may only omit `Sec-Fetch-Site` or use `none`.
- No CORS permissions are granted. Browser-origin and unidentified requests are rejected before broker/session/stream operations.
- The native macOS HTTP adapter must send the client marker header. Future SSE/stream consumers must do the same.
- **Threat-model limitation:** this marker is not a secret or user authentication credential. It mitigates browser CSRF/cross-origin access; it does not authenticate arbitrary local processes running as the same user. Production packaging must add a per-launch local API capability token or authenticated local IPC before exposing broker/session controls beyond this development boundary.
