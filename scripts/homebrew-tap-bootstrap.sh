#!/usr/bin/env bash
set -euo pipefail

# Create/update a Homebrew tap repo with the current formula.
# Usage:
#   scripts/homebrew-tap-bootstrap.sh /path/to/homebrew-tools

TAP_DIR="${1:-}"
if [[ -z "$TAP_DIR" ]]; then
  echo "usage: $0 /path/to/homebrew-tools" >&2
  exit 1
fi

mkdir -p "$TAP_DIR/Formula"
cp "$(cd "$(dirname "$0")/.." && pwd)/Formula/branchwarden.rb" "$TAP_DIR/Formula/branchwarden.rb"

echo "Copied formula to: $TAP_DIR/Formula/branchwarden.rb"
echo "Next steps:"
echo "  cd $TAP_DIR"
echo "  git add Formula/branchwarden.rb"
echo "  git commit -m 'feat: add/update branchwarden formula'"
echo "  git push"
