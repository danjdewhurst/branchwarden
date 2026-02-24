#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
TOOL="$ROOT_DIR/branchwarden"

fail() { echo "FAIL: $1" >&2; exit 1; }
assert_contains() { grep -Fq -- "$2" <<<"$1" || fail "expected output to contain '$2'"; }

setup_repo() {
  local dir repo remote
  dir="$(mktemp -d)"; repo="$dir/repo"; remote="$dir/remote.git"
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
  set +e; out="$($TOOL stale --days 0 2>&1)"; rc=$?; set -e
  [[ $rc -ne 0 ]] || fail "expected stale --days 0 to fail"
  assert_contains "$out" "--days must be > 0"

  set +e; out="$($TOOL clean --plan yaml 2>&1)"; rc=$?; set -e
  [[ $rc -ne 0 ]] || fail "expected clean --plan yaml to fail"
  assert_contains "$out" "--plan must be one of: text, json"

  set +e; out="$($TOOL audit --output xml 2>&1)"; rc=$?; set -e
  [[ $rc -ne 0 ]] || fail "expected audit --output xml to fail"
  assert_contains "$out" "--output must be one of: text, markdown, json, sarif"
}

test_status_and_clean_flow() {
  local repo; repo="$(setup_repo)"
  (
    cd "$repo"
    local status_out; status_out="$($TOOL status --base origin/main)"
    assert_contains "$status_out" "feature/old"
    assert_contains "$status_out" "merged"

    local status_json; status_json="$($TOOL status --base origin/main --format json)"
    assert_contains "$status_json" '"summary"'

    local dry_out; dry_out="$($TOOL clean --mode merged)"
    assert_contains "$dry_out" "Dry run"

    local plan_json; plan_json="$($TOOL clean --mode merged --plan json)"
    assert_contains "$plan_json" '"dryRun"'
    assert_contains "$plan_json" '"feature/old"'

    local clean_out; clean_out="$($TOOL clean --mode merged --yes)"
    assert_contains "$clean_out" "Deleted feature/old"

    local clean_json; clean_json="$($TOOL clean --mode gone --format json)"
    assert_contains "$clean_json" '"count"'
  )
}

test_presets_and_config() {
  local repo; repo="$(setup_repo)"
  (
    cd "$repo"
    local strict_out; strict_out="$($TOOL stale --days 1 --preset strict)"
    if grep -Fq "release/1.0" <<<"$strict_out"; then fail "release/1.0 should be protected by strict preset"; fi

    cat > branchwarden.config <<'CFG'
PRESET=solo-dev
PROTECT=release/*
MODE=merged
CFG
    local config_out; config_out="$($TOOL clean --plan json)"
    if grep -Fq '"release/1.0"' <<<"$config_out"; then fail "release/1.0 should be protected by config pattern"; fi
  )
}

test_mocked_github_commands() {
  local repo; repo="$(setup_repo)"
  (
    cd "$repo"
    git remote set-url origin git@github.com:example-org/repo-a.git
    export BRANCHWARDEN_MOCK_DIR="$ROOT_DIR/tests/fixtures/mock"

    set +e
    local audit_out rc
    audit_out="$($TOOL audit --base main --format json 2>&1)"; rc=$?
    set -e
    [[ $rc -eq 2 ]] || fail "expected mocked audit to detect drift"
    assert_contains "$audit_out" '"ok": false'

    set +e
    local apply_preview rc2
    apply_preview="$($TOOL apply --base main --format json 2>&1)"; rc2=$?
    set -e
    [[ $rc2 -eq 2 ]] || fail "expected mocked apply preview to exit 2"
    assert_contains "$apply_preview" '"preview":true'

    local pr_ok
    pr_ok="$($TOOL pr-gates --pr 12 --repo example-org/repo-a --require-label ready --require-linked-issue --min-reviewers 1 --format json)"
    assert_contains "$pr_ok" '"ok": true'

    local bulk
    bulk="$($TOOL bulk --org example-org --topic platform --pattern '^repo-' --action audit --format json)"
    assert_contains "$bulk" '"count":2'

    local doctor
    doctor="$($TOOL doctor --repo example-org/repo-a --format json)"
    assert_contains "$doctor" '"ok": true'
  )
}

test_init_and_completion() {
  local dir; dir="$(mktemp -d)"
  "$TOOL" init --path "$dir" --workflow both
  [[ -f "$dir/branchwarden.config" ]] || fail "missing generated config"
  [[ -f "$dir/.github/workflows/branchwarden-audit.yml" ]] || fail "missing audit workflow"
  [[ -f "$dir/.github/workflows/branchwarden-enforce.yml" ]] || fail "missing enforce workflow"

  local bash_comp; bash_comp="$($TOOL completion bash)"; assert_contains "$bash_comp" "complete -F"
  local zsh_comp; zsh_comp="$($TOOL completion zsh)"; assert_contains "$zsh_comp" "#compdef"
  local fish_comp; fish_comp="$($TOOL completion fish)"; assert_contains "$fish_comp" "complete -c"
}

echo "Running tests..."
test_validation_errors
test_status_and_clean_flow
test_presets_and_config
test_mocked_github_commands
test_init_and_completion
echo "All tests passed."
