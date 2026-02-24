#!/usr/bin/env bash
set -euo pipefail
BIN_DIR="${BIN_DIR:-/usr/local/bin}"
install -d "$BIN_DIR"
install -m 0755 ./branchwarden "$BIN_DIR/branchwarden"
echo "Installed branchwarden to $BIN_DIR/branchwarden"
