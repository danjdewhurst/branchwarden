# Contributing

Thanks for contributing to `branchwarden`.

## Local development

```bash
git clone git@github.com:danjdewhurst/branchwarden.git
cd branchwarden
chmod +x ./branchwarden ./test.sh
./branchwarden --help
```

## Testing

Run all tests before commit:

```bash
./test.sh
```

The test suite includes mocked GitHub integration tests and does not require network access.

## Commit conventions

Use focused, coherent commits. Preferred style:

- `feat(scope): add ...`
- `fix(scope): ...`
- `docs(scope): ...`
- `test(scope): ...`

Guidelines:
- One logical change per commit where possible.
- Keep commit messages imperative and specific.
- Update README/changelog when behavior changes.

## Pull requests

- Include summary, motivation, and testing performed.
- Keep PR body newline-safe (no malformed heredocs/snippets).
- Ensure CI passes.
