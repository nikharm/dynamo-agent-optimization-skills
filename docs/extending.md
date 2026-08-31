# Extending the Experiment

This repository is designed to support additional optimization work without weakening the original comparison.

## Add a Candidate

1. Start from the measured incumbent, currently `winner-4096`.
2. Add a named entry to [`config/variants.json`](../config/variants.json).
3. If the lever needs a new manifest field, add an explicit placeholder to [`k8s/dgd.yaml.in`](../k8s/dgd.yaml.in) and wire it through `render.sh`.
4. Render incumbent and candidate and review the semantic diff.
5. Record the hypothesis, expected mechanism, rollback, and required engagement proof before deployment.
6. Run `prepare-run.sh`, then the immutable benchmark.
7. Preserve the raw summary outside Git and add only sanitized aggregate results after review.

Do not bundle unrelated knobs. Changes that must move together for functionality—such as replica count, GPU request, and tensor-parallel size—should be documented as one topology mechanism.

## Candidate Review Checklist

- Same model ID and revision
- Same precision and context
- Same eight-GPU ceiling
- Same trace, timestamps, request count, and SLOs
- Exact declared configuration diff
- Resource and placement feasibility
- Mechanism engagement observable before spend
- Correctness and zero-restart smoke gates
- Full cold replacement after smoke
- Reversible rollback to the incumbent

## Result Policy

- Promote only audited, zero-error strict-goodput improvements.
- Treat small deltas as unresolved until a repeat or noise estimate can resolve them.
- Do not use server telemetry to overturn the client objective.
- Append new aggregate results; do not rewrite the reference measurements.
- Keep infrastructure identifiers and raw network traces out of Git.

## Suggested Next Sequence

1. Measure `candidate-3072`.
2. Compare four TP2 workers against eight TP1 workers.
3. Test `--attention-backend FLASHINFER` as a clean one-change backend trial.
4. Test native CPU KV offload and verify actual host-tier store/load events.
