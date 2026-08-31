# Repository Instructions

These rules apply to the entire repository.

## Preserve Experiment Fidelity

- Treat `winner-4096` as the measured incumbent.
- Keep the shape trace, request count, timestamps, TTFT/ITL thresholds, model revision, precision, context, and eight-GPU ceiling fixed when comparing candidates.
- Add one falsifiable lever per candidate. Functionally coupled topology fields may move together when documented as one mechanism.
- Promote only audited, zero-error strict-goodput improvements.

## Keep the Repository Public-safe

- Never commit `config/experiment.env`, `artifacts/`, raw HTTP traces, pod logs, credentials, cluster names, IPs, UIDs, node names, or local absolute paths.
- Add only sanitized aggregate results to `results/reference-results.json`.
- Parameterize infrastructure details through `config/experiment.env.example` and `@@NAME@@` template placeholders.
- Run `./scripts/validate-repository.sh` before every commit.

## Extend Reproducibly

- Define simple serving variants in `config/variants.json`.
- Update `k8s/dgd.yaml.in` and `scripts/render.sh` only when a lever requires a new manifest field.
- Add or update offline tests for analysis behavior.
- Document the hypothesis, engagement proof, result, and disposition in `docs/results.md`.
- Do not publish or push externally without explicit operator approval of the destination and payload.
