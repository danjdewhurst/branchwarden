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

    git checkout -b release/1.0 >/dev/null
    echo "release" > release.txt
    git add release.txt
    git commit -m "release prep" >/dev/null
    git checkout main >/dev/null
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

  set +e
  out="$($TOOL clean --plan yaml 2>&1)"
  rc=$?
  set -e
  [[ $rc -ne 0 ]] || fail "expected clean --plan yaml to fail"
  assert_contains "$out" "--plan must be one of: text, json"
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

    local plan_json
    plan_json="$($TOOL clean --mode merged --plan json)"
    assert_contains "$plan_json" '"dryRun":true'
    assert_contains "$plan_json" '"feature/old"'

    local clean_out
    clean_out="$($TOOL clean --mode merged --yes)"
    assert_contains "$clean_out" "Deleted feature/old"

    if git branch --list feature/old | grep -q "feature/old"; then
      fail "branch should be deleted"
    fi
  )
}

test_presets_and_config() {
  local repo
  repo="$(setup_repo)"
  (
    cd "$repo"

    local strict_out
    strict_out="$($TOOL stale --days 1 --preset strict)"
    if grep -Fq "release/1.0" <<<"$strict_out"; then
      fail "release/1.0 should be protected by strict preset"
    fi

    cat > branchwarden.config <<'CFG'
PRESET=solo-dev
PROTECT=release/*
MODE=merged
CFG

    local config_out
    config_out="$($TOOL clean --plan json)"
    if grep -Fq '"release/1.0"' <<<"$config_out"; then
      fail "release/1.0 should be protected by config pattern"
    fi
  )
}

echo "Running tests..."
test_validation_errors
test_status_and_clean_flow
test_presets_and_config
echo "All tests passed."
