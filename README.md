# Dynamo ToolAgent Optimization

A public-ready, reproducible record of an NVIDIA Dynamo configuration optimization exercise for `Qwen/Qwen3-32B` on eight H100 GPUs.

The best measured change was reducing vLLM `max_num_batched_tokens` from 8,192 to 4,096. On the frozen 5,775-request ToolAgent shape trace, strict goodput increased from **1.39999 to 1.75232 requests/s**—a **25.17% improvement**—with zero request errors.

Strict goodput counts only requests satisfying both TTFT `< 5,000 ms` and ITL `< 100 ms`.

## What This Repository Provides

- Parameterized DynamoGraphDeployment templates with no cluster-specific names
- Exact model, runtime, workload, and configuration pins
- A shape-only trace containing no prompt or response content
- Scripts for preflight, model caching, deployment, cold-state preparation, benchmarking, collection, analysis, and comparison
- Sanitized aggregate results and a clear record of rejected candidates
- Guidance for adding and evaluating future variants without invalidating the comparison

## Reference Result

| Variant | Strict goodput | Strict-good requests | Decision |
|---|---:|---:|---|
| Baseline, batched tokens 8,192 | 1.39999 req/s | 1,709 / 5,775 | Baseline |
| Batched tokens 4,096 | **1.75232 req/s** | **2,131 / 5,775** | **Promoted** |
| Router decay 1.0 | 1.54545 req/s | 1,888 / 5,775 | Rejected |
| GPU memory 0.95, two-run mean | 1.74880 req/s | — | Rejected |

See [Results and interpretation](docs/results.md) for the complete story.

## Quick Start

Prerequisites: a Kubernetes cluster with the NVIDIA Dynamo operator, eight H100 GPUs, `kubectl`, `jq`, `curl`, Ruby, and Python 3.

```bash
cp config/experiment.env.example config/experiment.env
# Edit config/experiment.env for your cluster.

./scripts/validate-repository.sh
./scripts/preflight.sh
./scripts/prepare-model-cache.sh

# Correctness smoke followed by a full cold DGD replacement.
./scripts/prepare-run.sh baseline
./scripts/run-benchmark.sh baseline run-001

./scripts/prepare-run.sh winner-4096
./scripts/run-benchmark.sh winner-4096 run-001

./scripts/compare.py \
  artifacts/baseline/run-001/strict-summary.json \
  artifacts/winner-4096/run-001/strict-summary.json
```

The full setup, Secret creation, storage requirements, and collection behavior are described in [Reproducing the experiment](docs/reproduction.md).

## Repository Map

```text
config/       User-owned environment file and measured variant definitions
data/         Frozen shape-only trace
docs/         Methodology, results, reproduction, extension, and privacy guidance
k8s/          Portable templates rendered from config/experiment.env
results/      Sanitized aggregate reference results
scripts/      Deploy, benchmark, analyze, compare, and validate workflows
tests/        Offline tests for the strict-goodput analyzer
```

## Status

The 4,096-token winner is conclusive for the reference environment. The broader search is intentionally open: a 3,072-token candidate was reviewed but not measured, and TP2×4, FlashInfer attention, and native CPU KV offload remain worthwhile future families.

Before publishing a fork, run `./scripts/validate-repository.sh` and review [Privacy and publishing](docs/privacy.md).

No redistribution license has been selected yet. Choose an appropriate license before making the repository public.
