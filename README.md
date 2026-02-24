# branchwarden

`branchwarden` is a practical Git hygiene CLI for auditing and cleaning local branches safely.

## Problem solved

In busy repos, stale and merged branches accumulate and slow down day-to-day Git workflows.

`branchwarden` helps you quickly:
- audit branch health,
- detect stale branches by age,
- prune merged/orphaned branches with dry-run safety.

## Install / run

```bash
git clone git@github.com:danjdewhurst/branchwarden.git
cd branchwarden
chmod +x ./branchwarden
./branchwarden --help
```

(Optional) add to PATH:

```bash
install -m 0755 ./branchwarden /usr/local/bin/branchwarden
```

## Subcommands

### 1) `status`

Audit branch state against a base branch:

```bash
branchwarden status --base origin/main
```

Use protection presets or custom patterns:

```bash
branchwarden status --preset strict
branchwarden status --protect 'release/*' --protect 'hotfix/*'
```

Shows branches that are:
- merged,
- upstream gone,
- ahead/behind remote.

### 2) `stale`

Find branches with no recent commits:

```bash
branchwarden stale --days 45
```

### 3) `clean`

Dry-run cleanup by default:

```bash
branchwarden clean --mode both
```

Planner output as JSON:

```bash
branchwarden clean --mode both --plan json
```

Actually delete candidates:

```bash
branchwarden clean --mode both --yes
```

Modes:
- `merged`
- `gone`
- `both`

### 4) `audit`

Detect branch protection drift versus desired policy (classic branch protection + matching rulesets visibility):

```bash
branchwarden audit --repo danjdewhurst/branchwarden --base main
branchwarden audit --repo danjdewhurst/branchwarden --base main --output markdown
branchwarden audit --repo danjdewhurst/branchwarden --base main --output sarif
```

### 5) `apply`

Preview branch-protection drift and auto-fix when needed:

```bash
branchwarden apply --repo danjdewhurst/branchwarden --base main
branchwarden apply --repo danjdewhurst/branchwarden --base main --fix
```

### 6) `bulk`

Audit or enforce policy across organization repos filtered by topic/pattern:

```bash
branchwarden bulk --org your-org --topic platform --pattern '^api-' --action audit
branchwarden bulk --org your-org --topic platform --pattern '^api-' --action apply --fix
```

### 7) `pr-gates`

Validate pull request quality gates:

```bash
branchwarden pr-gates --repo danjdewhurst/branchwarden --pr 42 \
  --require-label ready --require-linked-issue --min-reviewers 2
```

Defaults expect:
- required check: `CI / test`
- required approvals: `1`
- conversation resolution: `true`
- enforce admins: `true`

Override via `branchwarden.config` using:
`REQUIRED_CHECKS`, `REQUIRED_APPROVALS`, `REQUIRE_CONVERSATION_RESOLUTION`, `ENFORCE_ADMINS`.

## Config file (`branchwarden.config`)

You can define team defaults in a simple config file at repo root:

```ini
BASE=origin/main
MODE=both
DAYS=45
PRESET=balanced
PROTECT=release/*,hotfix/*
```

CLI flags always override config values.

## Input -> transformation -> output

- **Input:** your local Git repository state (`refs/heads`, upstream tracking info, commit timestamps).
- **Transformation:** branch classification (merged/gone/diverged/stale) with safety filtering for protected branches (`main`, `master`, `develop`, `dev`).
- **Output:** actionable terminal report + optional branch deletion.

## Before / after value

Before:
- ad-hoc manual commands,
- inconsistent cleanup,
- risk of deleting the wrong branch.

After:
- repeatable branch audit,
- safer cleanup workflow with dry-run default,
- clearer hygiene in team repos.

## Validation & helpful errors

Examples:
- `error: --days must be > 0`
- `error: --mode must be one of: merged, gone, both`
- `error: --base cannot be empty`
- `error: not inside a git repository`

## CI

GitHub Actions workflows:
- CI on pushes/PRs to `main`
- Reusable enforcement workflow: `.github/workflows/branchwarden-reusable-enforce.yml`
- Example scheduled enforcement: `.github/workflows/branchwarden-scheduled-enforce.yml`

Reusable workflow usage (from another workflow):

```yaml
jobs:
  enforce:
    uses: ./.github/workflows/branchwarden-reusable-enforce.yml
    with:
      repo: ${{ github.repository }}
      base: main
```

Checks:
- shell syntax check (`bash -n`)
- end-to-end test script (`./test.sh`)

## Roadmap

- [x] Protected-branch presets (`strict`, `balanced`, `solo-dev`) and custom protection patterns
- [x] Config file support (`branchwarden.config`) for team policy defaults
- [x] Drift detection (`audit`) against desired policy and live repo state
- [x] Auto-fix mode (`apply --fix`) to enforce policy quickly
- [x] GitHub Rulesets support (alongside classic branch protection)
- [x] Org/bulk mode for repos by topic/pattern
- [x] PR quality gates (labels, linked issue, reviewer minimums)
- [x] Improved dry-run planner output (`--plan text|json`)
- [x] Audit report export (`--output markdown|json|sarif`)
- [x] Scheduled enforcement via reusable GitHub Action template

## License

MIT — see [LICENSE](./LICENSE)
