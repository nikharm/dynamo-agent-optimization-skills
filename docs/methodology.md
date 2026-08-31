# Methodology

## Performance Question

At the fixed ToolAgent arrival schedule, which Dynamo/vLLM configuration maximizes requests per second that simultaneously meet TTFT `< 5,000 ms` and ITL `< 100 ms`, while maintaining zero request errors?

## Frozen Conditions

- Model: `Qwen/Qwen3-32B`
- Model revision: `9216db5781bf21249d130ec9da846c4624c16137`
- Runtime: Dynamo vLLM image 1.4.1 with vLLM 0.26.0
- Hardware: eight H100 GPUs
- Serving topology: eight TP1 workers, one GPU each
- Precision: FP8 weights and FP8 KV cache
- Context: 131,072 tokens with retained YaRN scaling
- Trace: 5,775 requests at original timestamps over 1,196.248 seconds
- Endpoint: streaming chat completions
- AIPerf: 0.10.0, seed 42, `ignore_eos=true`, no warmup requests

Only the candidate's declared lever changes between comparison points.

## Optimization Loop

The exercise followed the [Dynamo agent-optimization skills](https://docs.dynamo.nvidia.com/dynamo/dev/digest/agent-optimization-skills) workflow:

1. Generate one falsifiable candidate from the measured incumbent.
2. Prove its semantic diff and resource footprint.
3. Review the hypothesis independently before GPU spend.
4. Deploy the exact candidate and verify the mechanism engaged.
5. Run model and chat smoke tests.
6. Replace the full DGD after smoke to establish fresh worker caches.
7. Replay the immutable trace without additional inference traffic.
8. Collect artifacts before the benchmark pod exits.
9. Audit every record and recompute strict threshold semantics.
10. Promote only a zero-error end-to-end improvement.

Mechanism telemetry can explain a result but cannot override client-visible strict goodput.

## Why Strict Recalculation Matters

AIPerf 0.10.0 reports its native goodput using inclusive `<=` thresholds. The experiment's contract uses strict `<` thresholds. [`analyze-profile.py`](../scripts/analyze-profile.py) independently checks request status, cancellation, uniqueness, timing, and metric values before recomputing strict goodput from `profile_export.jsonl`.

## Comparison Discipline

- Use full DGD replacement between measured configurations.
- Do not send smoke or warmup traffic after the final cold replacement.
- Run benchmark clients sequentially so the client is not a shared bottleneck.
- Preserve all 5,775 records and zero errors.
- Repeat only when a small delta cannot be resolved from available variation evidence.
- Compare variants within the same cluster and time window; do not compare absolute numbers across unrelated hardware.
