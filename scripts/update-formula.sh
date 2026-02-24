#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
FORMULA_FILE="${FORMULA_FILE:-$ROOT_DIR/Formula/branchwarden.rb}"
OWNER_REPO="${OWNER_REPO:-danjdewhurst/branchwarden}"
TMP_TARBALL=""
TMP_FORMULA=""

usage() {
  cat >&2 <<USAGE
Usage: $0 [--print-only|--dry-run] [--sha256 <hex>] <tag>

Updates Formula/branchwarden.rb for a release tag (vX.Y.Z).

Options:
  --print-only, --dry-run  Print proposed values; do not modify formula
  --sha256 <hex>           Use provided sha256 instead of downloading tarball
USAGE
}

die() {
  echo "error: $*" >&2
  exit 1
}

cleanup() {
  if [[ -n "$TMP_TARBALL" ]]; then
    rm -f "$TMP_TARBALL"
  fi
  if [[ -n "$TMP_FORMULA" ]]; then
    rm -f "$TMP_FORMULA"
  fi
  return 0
}
trap cleanup EXIT

is_sha256() {
  [[ "$1" =~ ^[0-9a-f]{64}$ ]]
}

PRINT_ONLY=0
SHA256_OVERRIDE=""
TAG=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --print-only|--dry-run)
      PRINT_ONLY=1
      shift
      ;;
    --sha256)
      [[ $# -ge 2 ]] || die "--sha256 requires a value"
      SHA256_OVERRIDE="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    -* )
      usage
      die "unknown option: $1"
      ;;
    *)
      if [[ -n "$TAG" ]]; then
        usage
        die "unexpected extra argument: $1"
      fi
      TAG="$1"
      shift
      ;;
  esac
done

[[ -n "$TAG" ]] || {
  usage
  die "missing required tag argument"
}

[[ "$TAG" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]] || die "tag must match vX.Y.Z (got: $TAG)"
[[ -f "$FORMULA_FILE" ]] || die "formula file not found: $FORMULA_FILE"

if [[ -n "$SHA256_OVERRIDE" ]] && ! is_sha256 "$SHA256_OVERRIDE"; then
  die "--sha256 must be a 64-character lowercase hex string"
fi

TARBALL_URL="https://github.com/$OWNER_REPO/archive/refs/tags/$TAG.tar.gz"
NEW_SHA256="$SHA256_OVERRIDE"

if [[ -z "$NEW_SHA256" ]]; then
  TMP_TARBALL="$(mktemp)"
  curl -fsSL "$TARBALL_URL" -o "$TMP_TARBALL"
  NEW_SHA256="$(sha256sum "$TMP_TARBALL" | awk '{print $1}')"
fi

NEW_URL_LINE="  url \"$TARBALL_URL\""
NEW_SHA_LINE="  sha256 \"$NEW_SHA256\""

CURRENT_URL_LINE="$(grep -E '^  url \"https://github.com/.*/archive/refs/tags/v[0-9]+\.[0-9]+\.[0-9]+\.tar\.gz\"$' "$FORMULA_FILE" || true)"
CURRENT_SHA_LINE="$(grep -E '^  sha256 \"[0-9a-f]{64}\"$' "$FORMULA_FILE" || true)"

[[ -n "$CURRENT_URL_LINE" ]] || die "unable to find formula url line in $FORMULA_FILE"
[[ -n "$CURRENT_SHA_LINE" ]] || die "unable to find formula sha256 line in $FORMULA_FILE"

if [[ "$CURRENT_URL_LINE" == "$NEW_URL_LINE" && "$CURRENT_SHA_LINE" == "$NEW_SHA_LINE" ]]; then
  echo "Formula already up to date for $TAG"
  exit 0
fi

if [[ "$PRINT_ONLY" -eq 1 ]]; then
  echo "Would update formula: $FORMULA_FILE"
  echo "$NEW_URL_LINE"
  echo "$NEW_SHA_LINE"
  exit 0
fi

TMP_FORMULA="$(mktemp)"

sed -E \
  -e "s|^  url \"https://github.com/.*/archive/refs/tags/v[0-9]+\.[0-9]+\.[0-9]+\.tar\.gz\"$|$NEW_URL_LINE|" \
  -e "s|^  sha256 \"[0-9a-f]{64}\"$|$NEW_SHA_LINE|" \
  "$FORMULA_FILE" > "$TMP_FORMULA"

mv "$TMP_FORMULA" "$FORMULA_FILE"
TMP_FORMULA=""

# Validate exact expected lines are present after update.
grep -Fq -- "$NEW_URL_LINE" "$FORMULA_FILE" || die "url update validation failed"
grep -Fq -- "$NEW_SHA_LINE" "$FORMULA_FILE" || die "sha256 update validation failed"

echo "Updated $FORMULA_FILE for $TAG"
