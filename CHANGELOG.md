# Changelog

All notable changes to this project are documented in this file.

## v0.2.0 - 2026-02-24

### Added
- `--format json` for `status`, `stale`, `clean`, `audit`, `apply`, `bulk`, and `pr-gates`.
- New `doctor` command for auth/repo/scope diagnostics with actionable fixes.
- New `init` command for scaffolding `branchwarden.config` and workflow templates.
- Shell completion generation via `branchwarden completion <bash|zsh|fish>` plus checked-in completion files.
- Integration tests for GitHub-facing commands using mock fixtures (`BRANCHWARDEN_MOCK_DIR`).
- Homebrew/install-script documentation path.
- `CONTRIBUTING.md` and `SECURITY.md`.

### Changed
- README expanded with exit code contract, install options, completion docs, and new command coverage.

## v0.1.0 - 2026-02-24

### Added
- Core branch hygiene commands: `status`, `stale`, `clean`.
- GitHub policy features: `audit`, `apply`, `bulk`, `pr-gates`.
- Config-file support and protected-branch presets.
- CI workflows and base test script.
