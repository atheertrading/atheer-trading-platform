#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TARGET_DIR="${1:-${ATHEER_REPOSITORY_DIR:-$HOME/Developer/AtheerTradingPlatform}}"

bash "$SCRIPT_DIR/safe-sync.sh" "$TARGET_DIR"
cd "$TARGET_DIR"
current_branch="$(git branch --show-current)"
if [[ "$current_branch" != "main" ]]; then
  printf 'Main is synchronized, but the original branch (%s) was restored. This bootstrap will not move local work between branches. Review and preserve local changes, switch to main, then rerun bootstrap.\n' "$current_branch" >&2
  exit 3
fi
bash scripts/install-xcodegen.sh
bash scripts/doctor.sh
if [[ ! -x services/api/node_modules/.bin/tsc ]]; then
  (cd services/api && npm ci --ignore-scripts --no-audit --no-fund)
fi
cd apps/macos/ATHEERTradingPro
"$HOME/.local/bin/xcodegen" generate
printf '\nXcode project generated. Start the local API with make backend-start, then build/test/run with make build, make test, and make app-run.\n'
