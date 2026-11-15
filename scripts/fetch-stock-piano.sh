#!/usr/bin/env bash
# Download the piano stock recovery partition from Xiaomi's full OTA by HTTP
# range, checking it against devices/piano.toml's SHA-256.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT/skyward"
cargo build --release -p skyward-pack
mkdir -p "$ROOT/stock/piano"
"$ROOT/skyward/target/release/skyward-pack" stock \
    --config "$ROOT/skyward/devices/piano.toml" \
    --out "$ROOT/stock/piano/recovery.img"
