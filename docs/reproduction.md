# Reproducing the Experiment

## 1. Prepare a Cluster

You need:

- Kubernetes with the NVIDIA Dynamo operator installed
- At least eight H100 GPUs visible through `nvidia.com/gpu`
- A ReadWriteMany storage class large enough for the model cache
- A CPU benchmark node with internet access to install AIPerf, or a prebuilt replacement image
- Access to the Dynamo vLLM runtime image and the public model repository

The reference topology used eight one-GPU workers. Keep total GPUs and worker count unchanged when reproducing a measured variant.

## 2. Configure the Repository

```bash
cp config/experiment.env.example config/experiment.env
```

Edit every `REPLACE_ME` value. The environment file is ignored by Git.

Create the namespace and model-access Secret without writing the token to disk:

```bash
kubectl --context YOUR_CONTEXT create namespace YOUR_NAMESPACE
read -s HF_TOKEN
kubectl --context YOUR_CONTEXT -n YOUR_NAMESPACE create secret generic model-access \
  --from-literal=HF_TOKEN="$HF_TOKEN"
unset HF_TOKEN
```

Use the Secret name you selected in `MODEL_SECRET_NAME`.

## 3. Validate and Cache the Model

```bash
./scripts/validate-repository.sh
./scripts/preflight.sh
./scripts/prepare-model-cache.sh
```

The setup creates a shared PVC and downloads the exact model revision once. If your cluster does not provide ReadWriteMany storage, replace the PVC templates with a node-local preloading strategy while preserving the same model revision on every worker.

## 4. Render Before Spending GPUs

```bash
./scripts/render.sh baseline
./scripts/render.sh winner-4096
diff -u .rendered/baseline/dgd.yaml .rendered/winner-4096/dgd.yaml
```

The meaningful diff should be the batched-token value. Variant definitions live in [`config/variants.json`](../config/variants.json).

## 5. Run the Baseline

```bash
./scripts/prepare-run.sh baseline
./scripts/run-benchmark.sh baseline run-001
```

`prepare-run.sh` deploys and smokes the configuration, then replaces the full DGD. Do not send inference traffic after that final replacement.

`run-benchmark.sh`:

1. Verifies the frozen trace hashes.
2. Stages the trace as a Kubernetes ConfigMap.
3. Runs the exact fixed-schedule AIPerf profile.
4. Holds the pod after success or failure.
5. Copies artifacts locally before releasing the Job.
6. Runs the strict-goodput analyzer.

Artifacts are written beneath `artifacts/<variant>/<run-id>/` and ignored by Git.

## 6. Run and Compare the Winner

```bash
./scripts/prepare-run.sh winner-4096
./scripts/run-benchmark.sh winner-4096 run-001

./scripts/compare.py \
  artifacts/baseline/run-001/strict-summary.json \
  artifacts/winner-4096/run-001/strict-summary.json
```

A reproduction should be judged on its within-cluster delta and correctness, not on matching the reference environment's absolute throughput exactly.

## Operational Notes

- The benchmark Job installs AIPerf 0.10.0 at runtime for portability. For controlled or air-gapped environments, build a pinned client image and set `BENCH_IMAGE`.
- The benchmark pod deliberately remains Running until artifacts are copied. Do not delete it before collection.
- The included trace has no text content; it reconstructs only request timing, token lengths, and prefix-sharing structure.
- Clean up terminal Jobs and ConfigMaps after preserving the run evidence.
