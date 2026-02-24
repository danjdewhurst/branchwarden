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

Actually delete candidates:

```bash
branchwarden clean --mode both --yes
```

Modes:
- `merged`
- `gone`
- `both`

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

GitHub Actions workflow runs on:
- pushes to `main`
- pull requests to `main`

Checks:
- shell syntax check (`bash -n`)
- end-to-end test script (`./test.sh`)

## License

MIT — see [LICENSE](./LICENSE)
