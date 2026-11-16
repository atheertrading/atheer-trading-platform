#!/usr/bin/env bash
set -euo pipefail
failures=0
check() {
  local name="$1"; shift
  if "$@" >/dev/null 2>&1; then printf 'OK      %s\n' "$name"
  else printf 'MISSING %s\n' "$name"; failures=$((failures + 1)); fi
}
printf '%s\n' 'ATHEER local environment diagnostic'
printf 'macOS: '; sw_vers -productVersion 2>/dev/null || echo 'not macOS'
check "Git" git --version
check "Xcode command line tools" xcode-select -p
check "Xcode build system" xcodebuild -version
check "Swift compiler" swift --version
check "Homebrew" brew --version
check "XcodeGen" xcodegen --version
check "Node.js 24" bash -c 'node -e "process.exit(Number(process.versions.node.split(\".\")[0]) === 24 ? 0 : 1)"'
check "npm" npm --version
if [[ "$failures" -gt 0 ]]; then
  printf '\n%d prerequisite check(s) failed. See docs/development/DEVELOPER_SETUP.md.\n' "$failures"
  exit 1
fi
printf '\nAll required local checks passed.\n'
