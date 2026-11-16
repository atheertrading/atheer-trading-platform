# Developer Setup — macOS and Backend

## Compatibility baseline

Historical primary workstation: Intel iMac, macOS 13.7.8, Xcode 14.3.1, Swift 5.8.1. Preserve this compatibility floor until the active machine is requalified. CI uses hosted macOS and a current Xcode image; the application deployment target remains macOS 13.0.

## Required software

| Tool | Requirement | Purpose |
|---|---|---|
| macOS | 13.0+ deployment target | Native application runtime |
| Xcode | 14.3.1 minimum for historical workstation | IDE, SDKs, compiler, xcodebuild |
| Command Line Tools | Match selected Xcode | Build utilities |
| Swift | Xcode-provided compiler | Native application and XcodeGen build |
| Git | Current supported version | Version control and pinned tool source |
| XcodeGen | Pinned 2.36.1 | Generate project from project.yml |
| Node.js | 24.x | Backend runtime/tooling |
| npm | Bundled with Node 24 | Package scripts |

Homebrew is optional and is not required by the repository bootstrap. The XcodeGen installer builds a pinned release with the Swift compiler supplied by the selected Xcode.

## Install and verify

1. Install Xcode from Apple's supported distribution. Launch it once, accept the license, then select it:
   sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
2. Install Command Line Tools if needed:
   xcode-select --install
3. Install Node.js using the official installer or a version manager. The repository's .nvmrc selects Node.js 24; with nvm installed, run nvm install and nvm use from the repository root.
4. Clone the repository using the instructions below.
5. From the repository root, build and install the XcodeGen 2.36.1 tool:
   bash scripts/install-xcodegen.sh
6. Verify prerequisites:
   make doctor

XcodeGen 2.36.1 is pinned to source commit 26e817b2deca1ceb9fdebfa963b86311fef3d05c for the Xcode 14.3 / Swift 5.8 compatibility baseline. Its upstream Package.resolved is used to lock dependencies. Do not upgrade it without requalifying the workstation toolchain and generated project.

## Clone and update

```bash
mkdir -p ~/Developer/ATHEER
cd ~/Developer/ATHEER
git clone https://github.com/atheertrading/atheer-trading-platform.git
cd atheer-trading-platform
git switch main
git pull --ff-only origin main
```

For each task, branch from the latest main:

```bash
git switch main
git pull --ff-only origin main
git switch -c feat/short-scope
```

## Generate, build, test

```bash
bash scripts/install-xcodegen.sh
make doctor
make generate
make build
make test
```

For a guarded clone/update flow that refuses to overwrite dirty or unrelated directories, run `bash scripts/bootstrap-local.sh`. It targets `~/Developer/ATHEER/atheer-trading-platform` by default and does not modify the earlier `atheer-trading-pro` checkout.

The generated Xcode project is reproducible from the committed `project.yml` and is not the source of truth.

## Xcode configuration policy

The XcodeGen specification is the canonical project configuration:

- Product/project: `ATHEERTradingPro`; display name: `ATHEER Trading Pro`.
- Bundle identifier: `com.atheertrading.desktop`.
- Deployment target: macOS 13.0.
- Swift language mode: Swift 5 (`SWIFT_VERSION=5.0`); the compiler version is supplied by the selected Xcode toolchain.
- Debug: no Swift optimization, testability enabled, active-architecture build, DWARF debug information.
- Release: optimized Swift build, dSYM debug symbols, assertions disabled, all standard architectures requested.
- Targeted Swift concurrency diagnostics are enabled as a migration baseline; warnings are not globally promoted to errors.
- Hardened-runtime capability remains enabled in build settings, but code signing is disabled for the current local/CI unsigned qualification. This is not a signed or notarized release.
- App Sandbox, entitlements, signing team, provisioning profiles, and app icon assets are intentionally not fabricated. Add them when product capabilities and Phase 3 signing requirements are specified and verified.
- No UI-test target or package dependency is added until a concrete UI acceptance suite or production dependency exists.

The CI workflow generates the project, lists schemes, builds Debug, runs unit tests, and builds Release on an Intel macOS runner. This qualifies the x86_64 CI environment only; Apple Silicon/arm64 remains a separate qualification item. Run the same checks locally before declaring Phase 2 complete.

## Backend local health service

Node.js 24 is the selected backend runtime. The initial local API service is implemented under services/api and uses a pinned TypeScript compiler with no runtime npm dependencies.

From the repository root:

```bash
cd services/api
npm ci
npm run typecheck
npm test
npm start
```

The service binds only to 127.0.0.1:4100. Keep it running while using the macOS application health panel. The application reports API connectivity separately from platform readiness; readiness remains not ready and trading remains disabled while persistence and broker adapters are not configured.

This health slice does not require PostgreSQL, broker credentials, market data, or trading permissions. Do not install or configure a database until persistence contracts, ownership, migrations, backup, and recovery requirements are reconciled. Do not expose the local API on a LAN or public interface.

## Credentials

Never put real credentials in source, shell command arguments, logs, public CI, or PRs. Use an approved Keychain design on macOS and secure runtime secret injection on servers. Trading remains disabled by default.

## Verification limitation

GitHub configuration cannot install Xcode or update your local clone. Local setup is unverified until the diagnostic, Debug/Release build, and test commands complete on the Mac.
