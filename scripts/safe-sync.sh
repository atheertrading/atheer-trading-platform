#!/usr/bin/env bash
set -euo pipefail

EXPECTED_REPO_URL="https://github.com/atheertrading/atheer-trading-platform.git"
TARGET_DIR="${1:-${ATHEER_REPOSITORY_DIR:-$HOME/Developer/AtheerTradingPlatform}}"
BACKUP_ROOT="${ATHEER_SYNC_BACKUP_ROOT:-$HOME/Developer/AtheerTradingPlatform-backups}"

fail() {
  printf 'ERROR: %s\n' "$1" >&2
  exit "${2:-1}"
}

verify_origin() {
  local origin_url
  origin_url="$(git -C "$TARGET_DIR" config --get remote.origin.url 2>/dev/null)" || fail "The repository has no origin remote."
  case "$origin_url" in
    https://github.com/atheertrading/atheer-trading-platform|https://github.com/atheertrading/atheer-trading-platform.git|git@github.com:atheertrading/atheer-trading-platform|git@github.com:atheertrading/atheer-trading-platform.git|ssh://git@github.com/atheertrading/atheer-trading-platform.git) ;;
    *) fail "Unexpected origin '$origin_url'. No synchronization was attempted." 5 ;;
  esac
}

if [[ -e "$TARGET_DIR" ]]; then
  git -C "$TARGET_DIR" rev-parse --is-inside-work-tree >/dev/null 2>&1 || fail "Existing path is not a Git repository: $TARGET_DIR" 2
  verify_origin
else
  mkdir -p "$(dirname "$TARGET_DIR")"
  git clone "$EXPECTED_REPO_URL" "$TARGET_DIR"
fi

original_branch="$(git -C "$TARGET_DIR" branch --show-current)"
[[ -n "$original_branch" ]] || fail "Detached HEAD detected. Switch to a named branch before synchronization." 6

stash_oid=""
backup_dir=""
backup_branch=""
worktree_status="$(git -C "$TARGET_DIR" status --porcelain=v1 -uall)"

if [[ -n "$worktree_status" ]]; then
  backup_id="$(date -u +%Y%m%dT%H%M%SZ)-$$"
  backup_dir="$BACKUP_ROOT/$backup_id"
  backup_branch="backup/pre-sync-$backup_id"
  umask 077
  mkdir -p "$backup_dir/untracked"
  chmod 700 "$backup_dir"

  git -C "$TARGET_DIR" status --short --branch > "$backup_dir/status.txt"
  git -C "$TARGET_DIR" rev-parse HEAD > "$backup_dir/head.txt"
  printf '%s\n' "$original_branch" > "$backup_dir/branch.txt"
  git -C "$TARGET_DIR" diff --cached --binary > "$backup_dir/staged.patch"
  git -C "$TARGET_DIR" diff --binary > "$backup_dir/unstaged.patch"

  while IFS= read -r -d '' relative_path; do
    source_path="$TARGET_DIR/$relative_path"
    destination_path="$backup_dir/untracked/$relative_path"
    mkdir -p "$(dirname "$destination_path")"
    cp -pR "$source_path" "$destination_path"
  done < <(git -C "$TARGET_DIR" ls-files --others --exclude-standard -z)

  git -C "$TARGET_DIR" branch "$backup_branch" HEAD
  stash_before="$(git -C "$TARGET_DIR" rev-parse -q --verify refs/stash 2>/dev/null || true)"
  git -C "$TARGET_DIR" stash push --include-untracked -m "ATHEER pre-sync backup $backup_id"
  stash_after="$(git -C "$TARGET_DIR" rev-parse -q --verify refs/stash 2>/dev/null || true)"
  [[ -n "$stash_after" && "$stash_after" != "$stash_before" ]] || fail "Could not verify creation of the preservation stash. External backup remains at $backup_dir." 7
  stash_oid="$stash_after"
  [[ -z "$(git -C "$TARGET_DIR" status --porcelain=v1 -uall)" ]] || fail "Worktree did not become clean after stashing. Backup and stash remain preserved." 8
fi

restore_original_branch() {
  local current_branch
  current_branch="$(git -C "$TARGET_DIR" branch --show-current 2>/dev/null || true)"
  if [[ -n "$original_branch" && "$current_branch" == "main" && "$original_branch" != "main" ]]; then
    git -C "$TARGET_DIR" switch "$original_branch" >/dev/null 2>&1 || true
  fi
}
trap restore_original_branch EXIT

git -C "$TARGET_DIR" fetch origin
if git -C "$TARGET_DIR" show-ref --verify --quiet refs/heads/main; then
  git -C "$TARGET_DIR" switch main
else
  git -C "$TARGET_DIR" switch --track -c main origin/main
fi
git -C "$TARGET_DIR" merge --ff-only origin/main

if [[ "$original_branch" != "main" ]]; then
  git -C "$TARGET_DIR" switch "$original_branch"
fi

if [[ -n "$stash_oid" ]]; then
  if ! git -C "$TARGET_DIR" stash apply --index "$stash_oid"; then
    fail "Local changes could not be reapplied cleanly. Original branch restored; stash $stash_oid and backup $backup_dir are preserved. Resolve manually; do not drop the stash." 10
  fi
fi

trap - EXIT
printf '\nMain synchronized to %s. Original branch restored: %s\n' "$(git -C "$TARGET_DIR" rev-parse --short main)" "$original_branch"
if [[ -n "$stash_oid" ]]; then
  printf 'Preservation branch: %s\nExternal backup: %s\nRetained stash object: %s\n' "$backup_branch" "$backup_dir" "$stash_oid"
  printf 'The stash was intentionally retained. Inspect the restored worktree and backup before considering stash removal.\n'
else
  printf 'Worktree was clean; no preservation backup was required.\n'
fi
printf 'Ignored files are not copied into the external backup. Review important ignored local configuration separately.\n'
printf 'The original feature branch is not rebased or merged onto main automatically.\n\n'
git -C "$TARGET_DIR" status --short --branch
