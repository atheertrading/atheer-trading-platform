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
3. Install Node.js 24 using the official installer or a version manager.
4. Clone the repository using the instructions below.
5. From the repository root, build and install the XcodeGen 2.36.1 tool:
   bash scripts/install-xcodegen.sh
6. Verify prerequisites:
   make doctor

XcodeGen 2.36.1 is deliberately pinned for the Xcode 14.3 / Swift 5.8 compatibility baseline. Do not upgrade it without requalifying the workstation toolchain and generated project.

## Clone and update

~bash
mkdir -p ~/Developer/ATHEER
cd ~/Developer/ATHEER
git clone https://github.com/atheertrading/atheer-trading-platform.git
cd atheer-trading-platform
git switch main
git pull --ff-only origin main
~

For each task, branch from the latest main:

~bash
git switch main
git pull --ff-only origin main
git switch -c feat/short-scope
~

## Generate, build, test

~bash
bash scripts/install-xcodegen.sh
make doctor
make generate
make build
make test
~

For a guarded clone/update flow that refuses to overwrite dirty or unrelated directories, run bash scripts/bootstrap-local.sh. It targets ~/Developer/ATHEER/atheer-trading-platform by default and does not modify the earlier atheer-trading-pro checkout.

The generated Xcode project is reproducible from the committed project.yml and is not the source of truth.

## Backend

Node.js 24 is the selected backend runtime direction. Add TypeScript packages only when their service boundary and contracts are specified. Do not add dependencies without a concrete consumer and security review.

## Credentials

Never put real credentials in source, shell command arguments, logs, public CI, or PRs. Use an approved Keychain design on macOS and secure runtime secret injection on servers. Trading remains disabled by default.

## Verification limitation

GitHub configuration cannot install Xcode or update your local clone. Local setup is unverified until the diagnostic, build, and test commands complete on the Mac.
