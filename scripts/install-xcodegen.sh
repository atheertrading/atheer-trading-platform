#!/usr/bin/env bash
set -euo pipefail

VERSION="2.36.1"
COMMIT_SHA="26e817b2deca1ceb9fdebfa963b86311fef3d05c"
CACHE_ROOT="${XDG_CACHE_HOME:-$HOME/.cache}/atheer"
SOURCE_DIR="$CACHE_ROOT/XcodeGen-$VERSION"
INSTALL_DIR="$HOME/.local/bin"
BINARY="$INSTALL_DIR/xcodegen"
MARKER="$INSTALL_DIR/xcodegen-source-commit"

mkdir -p "$CACHE_ROOT" "$INSTALL_DIR"

if [[ -x "$BINARY" && -f "$MARKER" ]] && grep -Fqx "$COMMIT_SHA" "$MARKER" && "$BINARY" --version 2>&1 | grep -Fq "$VERSION"; then
  echo "XcodeGen $VERSION is already installed at $BINARY"
else
  if [[ ! -d "$SOURCE_DIR/.git" ]]; then
    git init "$SOURCE_DIR"
    git -C "$SOURCE_DIR" remote add origin https://github.com/yonaskolb/XcodeGen.git
  fi
  if ! git -C "$SOURCE_DIR" remote get-url origin >/dev/null 2>&1; then
    git -C "$SOURCE_DIR" remote add origin https://github.com/yonaskolb/XcodeGen.git
  fi
  git -C "$SOURCE_DIR" fetch --depth 1 origin "$COMMIT_SHA"
  git -C "$SOURCE_DIR" checkout --detach FETCH_HEAD
  actual_sha="$(git -C "$SOURCE_DIR" rev-parse HEAD)"
  if [[ "$actual_sha" != "$COMMIT_SHA" ]]; then
    echo "XcodeGen source revision mismatch: $actual_sha" >&2
    exit 4
  fi

  (
    cd "$SOURCE_DIR"
    swift build -c release
  )
  install -m 755 "$SOURCE_DIR/.build/release/xcodegen" "$BINARY"
  printf "%s\n" "$COMMIT_SHA" > "$MARKER"
fi

"$BINARY" --version

if [[ -n "${GITHUB_PATH:-}" ]]; then
  echo "$INSTALL_DIR" >> "$GITHUB_PATH"
fi

echo "Installed pinned XcodeGen $VERSION ($COMMIT_SHA) at $BINARY"
echo "Add this to your shell profile if needed: export PATH=\"$INSTALL_DIR:\$PATH\""
