#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
failures=0

check() {
  local name="$1"; shift
  if "$@" >/dev/null 2>&1; then
    printf 'OK       %s\n' "$name"
  else
    printf 'MISSING  %s\n' "$name"
    failures=$((failures + 1))
  fi
}

printf '%s\n' 'ATHEER local environment diagnostic'
printf 'Repository: %s\n' "$ROOT"
printf 'macOS: '
sw_vers -productVersion 2>/dev/null || echo 'not macOS / unverified'

check "Git" git --version
if git -C "$ROOT" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  origin_url="$(git -C "$ROOT" config --get remote.origin.url 2>/dev/null || true)"
  case "$origin_url" in
    https://github.com/atheertrading/atheer-trading-platform|https://github.com/atheertrading/atheer-trading-platform.git|git@github.com:atheertrading/atheer-trading-platform|git@github.com:atheertrading/atheer-trading-platform.git|ssh://git@github.com/atheertrading/atheer-trading-platform.git)
      printf 'OK       Git origin identity\n' ;;
    *)
      printf 'MISMATCH Git origin identity: %s\n' "${origin_url:-missing}"; failures=$((failures + 1)) ;;
  esac
  printf 'Branch: %s\n' "$(git -C "$ROOT" branch --show-current)"
  if [[ -n "$(git -C "$ROOT" status --porcelain=v1 -uall)" ]]; then
    printf 'WARNING  Working tree contains modified or untracked files; safe-sync.sh preserves them before updating main.\n'
    git -C "$ROOT" status --short
  else
    printf 'OK       Git working tree clean\n'
  fi
else
  printf 'MISSING  Git repository metadata\n'
  failures=$((failures + 1))
fi

check "Xcode command line tools" xcode-select -p
check "Xcode build system" xcodebuild -version
check "Swift compiler" swift --version
check "XcodeGen project specification" test -f "$ROOT/apps/macos/ATHEERTradingPro/project.yml"
check "API package manifest" test -f "$ROOT/services/api/package.json"
check "API dependency lockfile" test -f "$ROOT/services/api/package-lock.json"

if [[ -x "$HOME/.local/bin/xcodegen" ]]; then
  xcodegen_bin="$HOME/.local/bin/xcodegen"
elif command -v xcodegen >/dev/null 2>&1; then
  xcodegen_bin="$(command -v xcodegen)"
else
  xcodegen_bin=""
fi
if [[ -n "$xcodegen_bin" ]] && "$xcodegen_bin" --version 2>&1 | grep -Fq "2.36.1"; then
  printf 'OK       XcodeGen 2.36.1\n'
else
  printf 'MISSING  or incompatible XcodeGen (required: 2.36.1; run bash scripts/install-xcodegen.sh)\n'
  failures=$((failures + 1))
fi

if command -v node >/dev/null 2>&1; then
  if [[ "$(node --version)" == "v24.22.3" ]]; then
    printf 'OK       Node.js 24.22.3 (pinned backend runtime)\n'
  else
    printf 'MISMATCH Node.js version %s (expected v24.22.3)\n' "$(node --version)"
    failures=$((failures + 1))
  fi
else
  printf 'MISSING  Node.js 24.22.3\n'
  failures=$((failures + 1))
fi

if command -v sw_vers >/dev/null 2>&1; then
  macos_version="$(sw_vers -productVersion)"
  macos_major="${macos_version%%.*}"
  macos_minor="${macos_version#*.}"
  macos_minor="${macos_minor%%.*}"
  if (( macos_major > 13 || (macos_major == 13 && macos_minor >= 5) )); then
    printf 'OK       macOS %s supports the bundled Node.js runtime\n' "$macos_version"
  else
    printf 'MISMATCH macOS %s (bundled Node.js runtime requires 13.5 or later)\n' "$macos_version"
    failures=$((failures + 1))
  fi
fi
check "npm" npm --version

if command -v gh >/dev/null 2>&1; then
  if gh auth status >/dev/null 2>&1; then printf 'OK       GitHub CLI authentication\n'
  else printf 'WARNING  GitHub CLI is installed but not authenticated\n'; fi
else
  printf 'OPTIONAL GitHub CLI is not installed\n'
fi
if command -v psql >/dev/null 2>&1; then printf 'AVAILABLE PostgreSQL client: %s\n' "$(psql --version)"
else printf 'PENDING  PostgreSQL client not installed; persistence setup remains a separate phase\n'; fi
if command -v pg_isready >/dev/null 2>&1; then
  if pg_isready >/dev/null 2>&1; then printf 'AVAILABLE PostgreSQL server accepts connections\n'
  else printf 'PENDING  PostgreSQL utility present; no accepting local server detected\n'; fi
fi
if command -v docker >/dev/null 2>&1; then printf 'OPTIONAL Docker: %s\n' "$(docker --version)"
else printf 'OPTIONAL Docker is not installed\n'; fi

if [[ "$failures" -gt 0 ]]; then
  printf '\n%d required prerequisite check(s) failed. See docs/development/DEVELOPER_SETUP.md.\n' "$failures"
  exit 1
fi
printf '\nAll required local prerequisite checks passed. Optional database and Docker state is reported separately.\n'
