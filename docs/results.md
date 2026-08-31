# Results and Interpretation

## Best Configuration

The winning configuration retained eight TP1 workers, FP8 weights/KV, 131,072-token context, block size 64, GPU memory utilization 0.90, async scheduling, and KV-aware routing. Its only change from baseline was:

```text
max_num_batched_tokens: 8192 -> 4096
```

It produced:

- Strict goodput: **1.7523235 requests/s**
- Strict-good requests: **2,131 / 5,775**
- Improvement over baseline: **25.17%**
- Total request throughput: **4.74879 requests/s**
- Output throughput: **863.69 tokens/s**
- Request errors: **0**

Average TTFT fell 27.50%, average ITL fell 43.17%, and average request latency fell 23.68% relative to baseline.

## Candidate Outcomes

| Candidate | Outcome | Interpretation |
|---|---|---|
| Batched tokens `8192 -> 4096` | +25.17%; promoted | Lower scheduling budget materially improved latency-SLO attainment. |
| Router KV overlap decay `0 -> 1.0` | −11.81%; rejected | Worker balance improved, but useful locality was lost and client goodput regressed. |
| GPU memory utilization `0.90 -> 0.95` | Two-run mean −0.20%; rejected | KV blocks increased 9.33%, but extra capacity did not improve the primary objective. |
| Batched tokens `4096 -> 3072` | Reviewed, unmeasured | Next sequential scheduler candidate. |

Machine-readable values are in [`reference-results.json`](../results/reference-results.json).

## Open Search Space

The following families remain suitable for future work:

- Four TP2 workers using the same eight GPUs
- FlashInfer instead of FlashAttention 3
- Native CPU KV offload through vLLM's `OffloadingConnector`
- The reviewed 3,072-token scheduler candidate

Speculative decoding needs a compatible method or draft model before it becomes an exact candidate. Disaggregated serving needs a qualified transport/topology and isolated role-rate measurements.

The measured winner is conclusive; the broader optimization objective is not exhausted.
