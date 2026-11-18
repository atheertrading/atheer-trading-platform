#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
API_DIR="$ROOT/services/api"
BUILD_DIR="$ROOT/.build"
CAPABILITY_DIR=""
CAPABILITY_FILE=""

[[ -x "$API_DIR/node_modules/.bin/tsc" ]] || {
  echo "Backend dependencies are missing. Run make backend-setup first." >&2
  exit 2
}

mkdir -p "$BUILD_DIR"
umask 077
CAPABILITY_DIR="$(mktemp -d "$BUILD_DIR/backend-dev.XXXXXX")"
chmod 700 "$CAPABILITY_DIR"
CAPABILITY_FILE="$CAPABILITY_DIR/ipc-capability"
node --input-type=module -e 'import { randomBytes } from "node:crypto"; process.stdout.write(randomBytes(32).toString("base64url"))' > "$CAPABILITY_FILE"
chmod 600 "$CAPABILITY_FILE"

cleanup() {
  rm -rf "$CAPABILITY_DIR"
}
trap cleanup EXIT INT TERM

printf 'Starting local DEMO backend. Private development capability: %s\n' "$CAPABILITY_FILE"
printf 'Use the file only for local authenticated API diagnostics; it is removed when this process exits.\n'

cd "$API_DIR"
npm start < <(cat "$CAPABILITY_FILE"; printf '\n')
