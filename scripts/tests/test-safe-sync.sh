#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SYNC_SCRIPT="$(cd "$SCRIPT_DIR/.." && pwd)/safe-sync.sh"
TEST_ROOT="$(mktemp -d)"
trap 'rm -rf "$TEST_ROOT"' EXIT

export GIT_CONFIG_GLOBAL="$TEST_ROOT/gitconfig"
git config --global user.name "ATHEER Sync Test"
git config --global user.email "sync-test@example.invalid"

BARE="$TEST_ROOT/remote.git"
SEED="$TEST_ROOT/seed"
TARGET="$TEST_ROOT/AtheerTradingPlatform"
BACKUPS="$TEST_ROOT/backups"
EXPECTED_URL="https://github.com/atheertrading/atheer-trading-platform.git"

git init --bare --initial-branch=main "$BARE" >/dev/null
git init --initial-branch=main "$SEED" >/dev/null
printf 'baseline\n' > "$SEED/README.md"
git -C "$SEED" add README.md
git -C "$SEED" commit -m "baseline" >/dev/null
git -C "$SEED" remote add origin "$BARE"
git -C "$SEED" push -u origin main >/dev/null

git config --global url."file://$BARE".insteadOf "$EXPECTED_URL"
git clone "$EXPECTED_URL" "$TARGET" >/dev/null 2>&1
git -C "$TARGET" remote set-url origin "$EXPECTED_URL"
CLEAN_TARGET="$TEST_ROOT/CleanRepository"
git clone "$EXPECTED_URL" "$CLEAN_TARGET" >/dev/null 2>&1
git -C "$CLEAN_TARGET" remote set-url origin "$EXPECTED_URL"

git -C "$TARGET" switch -c chore/local-work >/dev/null
printf 'staged local line\n' >> "$TARGET/README.md"
git -C "$TARGET" add README.md
printf 'unstaged local line\n' >> "$TARGET/README.md"
printf 'untracked session report\n' > "$TARGET/local-session-report.md"

printf 'remote main update\n' > "$SEED/REMOTE_UPDATE.md"
git -C "$SEED" add REMOTE_UPDATE.md
git -C "$SEED" commit -m "remote main update" >/dev/null
git -C "$SEED" push origin main >/dev/null

original_head="$(git -C "$TARGET" rev-parse HEAD)"
ATHEER_SYNC_BACKUP_ROOT="$BACKUPS" bash "$SYNC_SCRIPT" "$TARGET" > "$TEST_ROOT/sync-output.txt"

[[ "$(git -C "$TARGET" branch --show-current)" == "chore/local-work" ]]
backup_branch="$(git -C "$TARGET" for-each-ref --format="%(refname:short)" refs/heads/backup/pre-sync-*)"
[[ -n "$backup_branch" ]]
[[ "$(git -C "$TARGET" rev-parse "$backup_branch")" == "$original_head" ]]
git -C "$TARGET" show main:REMOTE_UPDATE.md >/dev/null
grep -q "staged local line" "$TARGET/README.md"
grep -q "unstaged local line" "$TARGET/README.md"
grep -q "untracked session report" "$TARGET/local-session-report.md"
[[ -n "$(git -C "$TARGET" diff --cached -- README.md)" ]]
[[ -n "$(git -C "$TARGET" diff -- README.md)" ]]
[[ -n "$(git -C "$TARGET" stash list)" ]]
[[ -n "$(find "$BACKUPS" -name staged.patch -print -quit)" ]]
[[ -n "$(find "$BACKUPS" -name unstaged.patch -print -quit)" ]]
[[ "$(cat "$(find "$BACKUPS" -name head.txt -print -quit)")" == "$original_head" ]]
[[ -n "$(find "$BACKUPS" -path "*/untracked/local-session-report.md" -print -quit)" ]]

ATHEER_SYNC_BACKUP_ROOT="$TEST_ROOT/clean-backups" bash "$SYNC_SCRIPT" "$CLEAN_TARGET" >/dev/null
[[ "$(git -C "$CLEAN_TARGET" branch --show-current)" == "main" ]]
[[ "$(git -C "$CLEAN_TARGET" rev-parse HEAD)" == "$(git -C "$CLEAN_TARGET" rev-parse origin/main)" ]]
[[ -z "$(git -C "$CLEAN_TARGET" status --porcelain=v1 -uall)" ]]
[[ -z "$(git -C "$CLEAN_TARGET" stash list)" ]]
[[ ! -d "$TEST_ROOT/clean-backups" ]]

WRONG_TARGET="$TEST_ROOT/WrongOrigin"
git clone "$EXPECTED_URL" "$WRONG_TARGET" >/dev/null 2>&1
git -C "$WRONG_TARGET" remote set-url origin "https://github.com/example/wrong-repository.git"
wrong_head="$(git -C "$WRONG_TARGET" rev-parse HEAD)"
if ATHEER_SYNC_BACKUP_ROOT="$TEST_ROOT/wrong-backups" bash "$SYNC_SCRIPT" "$WRONG_TARGET" >/dev/null 2>&1; then
  echo "safe-sync unexpectedly accepted a mismatched origin" >&2
  exit 1
fi
[[ "$(git -C "$WRONG_TARGET" rev-parse HEAD)" == "$wrong_head" ]]

DIVERGED_TARGET="$TEST_ROOT/DivergedMain"
git clone "$EXPECTED_URL" "$DIVERGED_TARGET" >/dev/null 2>&1
git -C "$DIVERGED_TARGET" remote set-url origin "$EXPECTED_URL"
printf 'local-only commit\n' > "$DIVERGED_TARGET/LOCAL_ONLY.md"
git -C "$DIVERGED_TARGET" add LOCAL_ONLY.md
git -C "$DIVERGED_TARGET" commit -m "local main commit" >/dev/null
local_head="$(git -C "$DIVERGED_TARGET" rev-parse HEAD)"
printf 'remote-only commit\n' > "$SEED/REMOTE_ONLY.md"
git -C "$SEED" add REMOTE_ONLY.md
git -C "$SEED" commit -m "remote main diverged commit" >/dev/null
git -C "$SEED" push origin main >/dev/null
if ATHEER_SYNC_BACKUP_ROOT="$TEST_ROOT/diverged-backups" bash "$SYNC_SCRIPT" "$DIVERGED_TARGET" >/dev/null 2>&1; then
  echo "safe-sync unexpectedly reconciled divergent main history" >&2
  exit 1
fi
[[ "$(git -C "$DIVERGED_TARGET" rev-parse HEAD)" == "$local_head" ]]
[[ -f "$DIVERGED_TARGET/LOCAL_ONLY.md" ]]
[[ ! -f "$DIVERGED_TARGET/REMOTE_ONLY.md" ]]

echo "safe-sync tests passed: dirty-worktree preservation, clean fast-forward, origin identity rejection, and divergent-main refusal."
