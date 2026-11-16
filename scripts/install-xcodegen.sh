#!/usr/bin/env bash
set -euo pipefail

VERSION="2.36.1"
CACHE_ROOT="${XDG_CACHE_HOME:-$HOME/.cache}/atheer"
SOURCE_DIR="$CACHE_ROOT/XcodeGen-$VERSION"
INSTALL_DIR="$HOME/.local/bin"
BINARY="$INSTALL_DIR/xcodegen"

mkdir -p "$CACHE_ROOT" "$INSTALL_DIR"

if [[ -x "$BINARY" ]] && "$BINARY" --version 2>&1 | grep -Fq "$VERSION"; then
  echo "XcodeGen $VERSION is already installed at $BINARY"
else
  if [[ ! -d "$SOURCE_DIR/.git" ]]; then
    git clone --depth 1 --branch "$VERSION" https://github.com/yonaskolb/XcodeGen.git "$SOURCE_DIR"
  else
    git -C "$SOURCE_DIR" fetch --depth 1 origin "refs/tags/$VERSION:refs/tags/$VERSION"
    git -C "$SOURCE_DIR" checkout "$VERSION"
  fi

  (
    cd "$SOURCE_DIR"
    swift build -c release
  )
  install -m 755 "$SOURCE_DIR/.build/release/xcodegen" "$BINARY"
fi

"$BINARY" --version

if [[ -n "${GITHUB_PATH:-}" ]]; then
  echo "$INSTALL_DIR" >> "$GITHUB_PATH"
fi

echo "Installed pinned XcodeGen at $BINARY"
echo "Add this to your shell profile if needed: export PATH=\"$INSTALL_DIR:\$PATH\""
