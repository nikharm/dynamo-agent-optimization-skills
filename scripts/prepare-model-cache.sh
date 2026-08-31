#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/lib.sh"
load_experiment_env
require_command kubectl

rendered="$($REPO_ROOT/scripts/render.sh winner-4096)"

kubectl --context "$KUBE_CONTEXT" create namespace "$NAMESPACE" \
  --dry-run=client -o yaml \
  | kubectl --context "$KUBE_CONTEXT" apply -f -

k get secret "$MODEL_SECRET_NAME" >/dev/null 2>&1 \
  || die "create Secret '$MODEL_SECRET_NAME' with HF_TOKEN before downloading the model"

k apply -f "$rendered/model-cache-pvc.yaml"
k delete job toolagent-model-download --ignore-not-found --wait=true
k apply -f "$rendered/model-download-job.yaml"
k wait --for=condition=complete job/toolagent-model-download --timeout=60m
k wait --for=jsonpath='{.status.phase}'=Bound "pvc/$MODEL_CACHE_PVC" --timeout=2m
k logs job/toolagent-model-download --tail=20

echo "model cache prepared at exact revision $MODEL_REVISION"
