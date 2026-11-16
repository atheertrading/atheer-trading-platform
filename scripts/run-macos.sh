#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APP="$ROOT/.build/DerivedData/Build/Products/Debug/ATHEERTradingPro.app"
[[ -d "$APP" ]] || { echo "Built application not found. Run make build first." >&2; exit 2; }
open "$APP"
printf 'Requested application launch: %s\n' "$APP"
