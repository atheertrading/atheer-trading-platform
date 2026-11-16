# Development Toolchain Manifest

| Component | Pinned baseline | Notes |
|---|---|---|
| macOS deployment target | 13.0 | Native app minimum deployment target |
| Historical local Xcode | 14.3.1 | Required compatibility baseline for the Intel workstation |
| Historical local Swift | 5.8.1 | Supplied by Xcode 14.3.1 |
| Swift language mode | 5 | Xcode project setting; compiler remains Xcode-managed |
| XcodeGen | 2.36.1, commit 26e817b2deca1ceb9fdebfa963b86311fef3d05c | Built from source by scripts/install-xcodegen.sh; upstream Package.resolved locks dependencies |
| Node.js | 24.x | Major version selected in .nvmrc |
| npm | Bundled with Node.js 24 | Backend toolchain |
| GitHub macOS CI | macos-15 | Hosted build and test environment |
| GitHub checkout action | actions/checkout@v4 | CI source retrieval |
| GitHub setup-node action | actions/setup-node@v4 | Node toolchain setup |
| Markdown lint action | DavidAnson/markdownlint-cli2-action@v19 | Markdown quality checks |
| CodeQL action | github/codeql-action@v4 | Swift and Actions static analysis |

## Compatibility policy

- Do not silently upgrade the local Xcode minimum or XcodeGen pin.
- XcodeGen is pinned by immutable commit SHA, not a floating tag. The installer verifies the checked-out commit and records its provenance beside the installed binary.
- The current XcodeGen release line requires a newer Xcode than the historical workstation. Requalify the toolchain before changing the pin.
- CI runs on a newer hosted macOS/Xcode image. A passing hosted build does not replace local Xcode 14.3.1 qualification.
- Node.js major version is controlled by .nvmrc and CI reads the same file.
- All toolchain changes must update this manifest, developer setup instructions, CI, and implementation evidence.
