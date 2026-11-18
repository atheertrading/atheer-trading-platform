#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
API_DIR="$ROOT/services/api"
BUILD_DIR="$ROOT/.build"
CAPABILITY_FILE="$BUILD_DIR/backend-ipc-capability"

[[ -x "$API_DIR/node_modules/.bin/tsc" ]] || {
  echo "Backend dependencies are missing. Run make backend-setup first." >&2
  exit 2
}

mkdir -p "$BUILD_DIR"
chmod 700 "$BUILD_DIR"
umask 077
node --input-type=module -e 'import { randomBytes } from "node:crypto"; process.stdout.write(randomBytes(32).toString("base64url"))' > "$CAPABILITY_FILE"
chmod 600 "$CAPABILITY_FILE"

cleanup() {
  rm -f "$CAPABILITY_FILE"
}
trap cleanup EXIT INT TERM

printf 'Starting local DEMO backend. Private development capability: %s\n' "$CAPABILITY_FILE"
printf 'Use the file only for local authenticated API diagnostics; it is removed when this process exits.\n'

cd "$API_DIR"
npm start < <(cat "$CAPABILITY_FILE"; printf '\n')
