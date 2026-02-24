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

  set +e
  out="$($TOOL audit --output xml 2>&1)"
  rc=$?
  set -e
  [[ $rc -ne 0 ]] || fail "expected audit --output xml to fail"
  assert_contains "$out" "--output must be one of: text, markdown, json, sarif"
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

test_audit_help() {
  local out
  out="$($TOOL audit --help)"
  assert_contains "$out" "Usage: branchwarden audit"
}

test_apply_help() {
  local out
  out="$($TOOL apply --help)"
  assert_contains "$out" "Usage: branchwarden apply"
  assert_contains "$out" "--fix"
}

test_bulk_help() {
  local out
  out="$($TOOL bulk --help)"
  assert_contains "$out" "Usage: branchwarden bulk"
  assert_contains "$out" "--org"
}

test_pr_gates_help() {
  local out
  out="$($TOOL pr-gates --help)"
  assert_contains "$out" "Usage: branchwarden pr-gates"
  assert_contains "$out" "--min-reviewers"
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

test_workflow_templates_exist() {
  [[ -f "$ROOT_DIR/.github/workflows/branchwarden-reusable-enforce.yml" ]] || fail "missing reusable enforce workflow"
  [[ -f "$ROOT_DIR/.github/workflows/branchwarden-scheduled-enforce.yml" ]] || fail "missing scheduled enforce workflow"
}

echo "Running tests..."
test_validation_errors
test_status_and_clean_flow
test_audit_help
test_apply_help
test_bulk_help
test_pr_gates_help
test_presets_and_config
test_workflow_templates_exist
echo "All tests passed."
