# branchwarden

`branchwarden` is a practical Git hygiene CLI for auditing and cleaning local branches safely.

## Install / run

### Quick local

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

### Homebrew (tap)

```bash
brew tap danjdewhurst/tools
brew install branchwarden
```

Tap maintainers can publish/update formula from this repo via:

```bash
scripts/homebrew-tap-bootstrap.sh /path/to/homebrew-tools
```

Formula source in this repo: `Formula/branchwarden.rb`

### Install script path

If your team mirrors install scripts, document a pinned script path such as:

```bash
curl -fsSL https://raw.githubusercontent.com/danjdewhurst/branchwarden/main/scripts/install.sh | bash
```

## Subcommands

- `status` — branch health (merged/gone/diverged)
- `stale` — stale branches by age
- `clean` — safe cleanup (dry-run default)
- `audit` — branch-protection drift detection
- `apply` — enforce branch-protection policy
- `bulk` — audit/apply across org repos
- `pr-gates` — PR quality checks
- `doctor` — environment/auth diagnostics with fixes
- `init` — scaffold config + workflow templates
- `completion` — emit shell completions

All operational subcommands support `--format text|json`.

## Examples

```bash
branchwarden status --base origin/main --format json
branchwarden stale --days 45 --format json
branchwarden clean --mode both --plan json
branchwarden audit --repo owner/repo --base main --output sarif
branchwarden apply --repo owner/repo --base main --fix --format json
branchwarden bulk --org your-org --topic platform --action audit --format json
branchwarden pr-gates --repo owner/repo --pr 42 --require-label ready --min-reviewers 2 --format json
branchwarden doctor --format json
branchwarden init --workflow both
```

## Config file (`branchwarden.config`)

```ini
BASE=origin/main
MODE=both
DAYS=45
PRESET=balanced
PROTECT=release/*,hotfix/*
REQUIRED_CHECKS=CI / test
REQUIRED_APPROVALS=1
REQUIRE_CONVERSATION_RESOLUTION=true
ENFORCE_ADMINS=true
REQUIRED_LABELS=ready
REQUIRE_LINKED_ISSUE=true
MIN_REVIEWERS=1
```

## Shell completions

Generate and install:

```bash
# bash
branchwarden completion bash > /etc/bash_completion.d/branchwarden

# zsh
mkdir -p ~/.zsh/completions
branchwarden completion zsh > ~/.zsh/completions/_branchwarden

# fish
branchwarden completion fish > ~/.config/fish/completions/branchwarden.fish
```

## `init` scaffolding

`branchwarden init` generates:
- `branchwarden.config`
- `.github/workflows/branchwarden-audit.yml`
- `.github/workflows/branchwarden-enforce.yml`

Use `--workflow audit|enforce|both` and `--force` to overwrite existing files.

## Exit code contract

- `0` success / compliant / no drift
- `1` usage or runtime error
- `2` policy violation or actionable drift/failures detected (e.g. `audit`, `apply` preview, `pr-gates`, `doctor`)

## CI

Checks:
- shell syntax check (`bash -n`)
- end-to-end test script (`./test.sh`)
- integration-style GitHub command tests via mock mode (`BRANCHWARDEN_MOCK_DIR`)

## Docs

- [CONTRIBUTING.md](./CONTRIBUTING.md)
- [CHANGELOG.md](./CHANGELOG.md)
- [SECURITY.md](./SECURITY.md)

## Roadmap

- [x] Add `--format json` support for all subcommands (`status`, `stale`, `clean`, `audit`, `apply`, `bulk`, `pr-gates`)
- [x] Add `doctor` command (GitHub auth, repo detection, token scopes, actionable fixes)
- [x] Add practical Homebrew tap/install script docs
- [x] Add versioned `CHANGELOG.md` entries including `v0.1.0` and `v0.2.0`
- [x] Add `CONTRIBUTING.md` with local dev/test workflow and commit conventions
- [x] Add shell completions (bash/zsh/fish) and documentation
- [x] Add integration tests for GitHub-facing commands using mock/stub mode (no network dependency)
- [x] Add `branchwarden init` scaffolding (config + workflow template)
- [x] Document explicit exit code contract in README
- [x] Add `SECURITY.md` vulnerability reporting + support policy

## License

MIT — see [LICENSE](./LICENSE)
