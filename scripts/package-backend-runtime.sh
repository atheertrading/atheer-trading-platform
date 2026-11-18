#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
API_DIR="$ROOT/services/api"
APP_DIR="$ROOT/apps/macos/ATHEERTradingPro"
RESOURCE_DIR="$APP_DIR/Resources"
NODE_VERSION="24.22.3"
DIST_URL="https://nodejs.org/dist/v$NODE_VERSION"
TMP_DIR="$(mktemp -d "\${TMPDIR:-/tmp}/atheer-node-runtime.XXXXXX")"
trap 'rm -rf "$TMP_DIR"' EXIT

EXPECTED_NODE_X64="977614af0504c81045e7fd85596dbca0e5f951b96681516dadafedcca8c447f7"
EXPECTED_NODE_ARM64="ff6e17d4874b76d272212b908cc020d6e815fba5a6c7eaaa06add725840307fd"

actual_node_version="$(node -p 'process.versions.node')"
if [[ "$actual_node_version" != "$NODE_VERSION" ]]; then
  echo "Node.js $NODE_VERSION is required to package the managed backend; found $actual_node_version." >&2
  exit 2
fi

download_and_verify() {
  local architecture="$1"
  local expected_sha="$2"
  local archive="node-v$NODE_VERSION-darwin-$architecture.tar.gz"

  curl --fail --location --silent --show-error "$DIST_URL/$archive" --output "$TMP_DIR/$archive"
  printf '%s  %s\n' "$expected_sha" "$archive" | (cd "$TMP_DIR" && shasum -a 256 -c -)
  tar -xzf "$TMP_DIR/$archive" -C "$TMP_DIR"
  cp "$TMP_DIR/node-v$NODE_VERSION-darwin-$architecture/bin/node" "$TMP_DIR/node-$architecture"
  cp "$TMP_DIR/node-v$NODE_VERSION-darwin-$architecture/LICENSE" "$TMP_DIR/LICENSE-$architecture"
}

download_and_verify "x64" "$EXPECTED_NODE_X64"
download_and_verify "arm64" "$EXPECTED_NODE_ARM64"

if ! cmp -s "$TMP_DIR/LICENSE-x64" "$TMP_DIR/LICENSE-arm64"; then
  echo "The official Node.js runtime license files do not match." >&2
  exit 3
fi

rm -rf "$RESOURCE_DIR/Backend" "$RESOURCE_DIR/Runtime"
mkdir -p "$RESOURCE_DIR/Backend" "$RESOURCE_DIR/Runtime"

lipo -create "$TMP_DIR/node-x64" "$TMP_DIR/node-arm64" -output "$RESOURCE_DIR/Runtime/node"
chmod 755 "$RESOURCE_DIR/Runtime/node"

architectures="$(lipo -archs "$RESOURCE_DIR/Runtime/node")"
if [[ " $architectures " != *" x86_64 "* || " $architectures " != *" arm64 "* ]]; then
  echo "Packaged Node runtime is not universal: $architectures" >&2
  exit 4
fi

cp "$TMP_DIR/LICENSE-x64" "$RESOURCE_DIR/Runtime/LICENSE"

(
  cd "$API_DIR"
  npm ci --ignore-scripts --no-audit --no-fund
  npm run build
)

cp -R "$API_DIR/dist" "$RESOURCE_DIR/Backend/dist"
test -f "$RESOURCE_DIR/Backend/dist/main.js"

echo "Packaged ATHEER backend with Node.js $NODE_VERSION ($architectures)."
echo "The official Node.js 24 macOS runtime requires macOS 13.5 or later."
