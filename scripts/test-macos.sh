#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PROJECT="$ROOT/apps/macos/ATHEERTradingPro/ATHEERTradingPro.xcodeproj"
[[ -d "$PROJECT" ]] || { echo "Missing generated Xcode project. Run make generate." >&2; exit 2; }
xcodebuild -project "$PROJECT" -scheme ATHEERTradingPro -configuration Debug -destination 'platform=macOS' CODE_SIGNING_ALLOWED=NO test
