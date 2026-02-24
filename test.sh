#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
TOOL="$ROOT_DIR/branchwarden"

fail() {
  echo "FAIL: $1" >&2
  exit 1
}

assert_contains() {
  local haystack="$1"
  local needle="$2"
  grep -Fq -- "$needle" <<<"$haystack" || fail "expected output to contain '$needle'"
}

setup_repo() {
  local dir
  dir="$(mktemp -d)"
  local repo="$dir/repo"
  local remote="$dir/remote.git"

  git init --bare "$remote" >/dev/null
  git init -b main "$repo" >/dev/null
  (
    cd "$repo"
    git config user.name "Test User"
    git config user.email "test@example.com"
    echo "hello" > README.md
    git add README.md
    git commit -m "init" >/dev/null
    git remote add origin "$remote"
    git push -u origin main >/dev/null

    git checkout -b feature/old >/dev/null
    echo "feature" > feature.txt
    git add feature.txt
    git commit -m "feature" >/dev/null
    git checkout main >/dev/null
    git merge --no-ff feature/old -m "merge feature" >/dev/null
    git push origin main >/dev/null
  )

  echo "$repo"
}

test_validation_errors() {
  local out rc
  set +e
  out="$($TOOL stale --days 0 2>&1)"
  rc=$?
  set -e
  [[ $rc -ne 0 ]] || fail "expected stale --days 0 to fail"
  assert_contains "$out" "--days must be > 0"
}

test_status_and_clean_flow() {
  local repo
  repo="$(setup_repo)"
  (
    cd "$repo"

    local status_out
    status_out="$($TOOL status --base origin/main)"
    assert_contains "$status_out" "feature/old"
    assert_contains "$status_out" "merged"

    local dry_out
    dry_out="$($TOOL clean --mode merged)"
    assert_contains "$dry_out" "Dry run"
    git branch --list feature/old | grep -q "feature/old" || fail "branch should still exist after dry run"

    local clean_out
    clean_out="$($TOOL clean --mode merged --yes)"
    assert_contains "$clean_out" "Deleted feature/old"

    if git branch --list feature/old | grep -q "feature/old"; then
      fail "branch should be deleted"
    fi
  )
}

echo "Running tests..."
test_validation_errors
test_status_and_clean_flow
echo "All tests passed."
