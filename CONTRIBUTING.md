# Contributing

Contributions should preserve a fair within-environment comparison and the repository's public-safe boundary.

1. Read [Methodology](docs/methodology.md) and [Extending the experiment](docs/extending.md).
2. Add a narrowly scoped candidate to `config/variants.json` or parameterize the required manifest field.
3. Render the incumbent and candidate and inspect their semantic diff before GPU spend.
4. Run the same cold-state and immutable benchmark workflow.
5. Keep raw artifacts outside Git; contribute aggregate, reviewed results only.
6. Run `./scripts/validate-repository.sh` before opening a change.

Please do not add environment-specific manifests, credentials, raw network traces, or operational logs.
