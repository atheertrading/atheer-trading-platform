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
if [[ -x "$HOME/.local/bin/xcodegen" ]]; then
  xcodegen_bin="$HOME/.local/bin/xcodegen"
elif command -v xcodegen >/dev/null 2>&1; then
  xcodegen_bin="$(command -v xcodegen)"
else
  xcodegen_bin=""
fi
if [[ -n "$xcodegen_bin" ]] && "$xcodegen_bin" --version 2>&1 | grep -Fq "2.36.1"; then
  printf 'OK      XcodeGen 2.36.1\n'
else
  printf 'MISSING or incompatible XcodeGen (required: 2.36.1; run bash scripts/install-xcodegen.sh)\n'
  failures=$((failures + 1))
fi
if command -v node >/dev/null 2>&1; then
  node_major="$(node -p 'process.versions.node.split(".")[0]')"
  if [[ "$node_major" == "24" ]]; then printf 'OK      Node.js 24\n'
  else printf 'MISMATCH Node.js major version %s (expected 24)\n' "$node_major"; failures=$((failures + 1)); fi
else
  printf 'MISSING Node.js 24\n'; failures=$((failures + 1))
fi
check "npm" npm --version
if [[ "$failures" -gt 0 ]]; then
  printf '\n%d prerequisite check(s) failed. See docs/development/DEVELOPER_SETUP.md.\n' "$failures"
  exit 1
fi
printf '\nAll required local checks passed.\n'
