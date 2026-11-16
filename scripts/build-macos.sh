#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PROJECT="$ROOT/apps/macos/ATHEERTradingPro/ATHEERTradingPro.xcodeproj"
DERIVED_DATA="$ROOT/.build/DerivedData"
[[ -d "$PROJECT" ]] || { echo "Missing generated Xcode project. Run make generate." >&2; exit 2; }
mkdir -p "$DERIVED_DATA"
xcodebuild -project "$PROJECT" -scheme ATHEERTradingPro -configuration "${CONFIGURATION:-Debug}" -destination "${DESTINATION:-platform=macOS}" -derivedDataPath "$DERIVED_DATA" CODE_SIGNING_ALLOWED=NO build
