#!/usr/bin/env bash
set -euo pipefail

REPOSITORY_URL="https://github.com/atheertrading/atheer-trading-platform.git"
TARGET_DIR="${1:-$HOME/Developer/ATHEER/atheer-trading-platform}"

if [[ -e "$TARGET_DIR" ]]; then
  if [[ ! -d "$TARGET_DIR/.git" ]]; then
    echo "Refusing to use existing non-repository path: $TARGET_DIR" >&2
    exit 2
  fi
  if [[ -n "$(git -C "$TARGET_DIR" status --porcelain)" ]]; then
    echo "Working tree is not clean. Preserve or commit local changes before updating." >&2
    git -C "$TARGET_DIR" status --short --branch
    exit 3
  fi
  git -C "$TARGET_DIR" fetch origin --prune
  git -C "$TARGET_DIR" switch main
  git -C "$TARGET_DIR" pull --ff-only origin main
else
  mkdir -p "$(dirname "$TARGET_DIR")"
  git clone "$REPOSITORY_URL" "$TARGET_DIR"
  git -C "$TARGET_DIR" switch main
  git -C "$TARGET_DIR" pull --ff-only origin main
fi

cd "$TARGET_DIR"
printf '\nRepository synchronized: %s\n' "$TARGET_DIR"
git status --short --branch
bash scripts/install-xcodegen.sh
bash scripts/doctor.sh
cd apps/macos/ATHEERTradingPro
$HOME/.local/bin/xcodegen generate
printf '\nXcode project generated successfully. Open ATHEERTradingPro.xcodeproj in Xcode or run make build and make test from the repository root.\n'
