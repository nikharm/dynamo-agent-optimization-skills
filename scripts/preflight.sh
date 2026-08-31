#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/lib.sh"
load_experiment_env

for command in kubectl jq python3 curl; do
  require_command "$command"
done

kubectl config get-contexts "$KUBE_CONTEXT" >/dev/null \
  || die "kubectl context not found: $KUBE_CONTEXT"

kubectl --context "$KUBE_CONTEXT" get crd dynamographdeployments.nvidia.com >/dev/null \
  || die "DynamoGraphDeployment CRD is not installed"

gpu_total="$(kubectl --context "$KUBE_CONTEXT" get nodes -o json \
  | jq '[.items[].status.allocatable["nvidia.com/gpu"] // "0" | tonumber] | add')"
[[ "$gpu_total" -ge "$GPU_COUNT" ]] \
  || die "cluster exposes $gpu_total GPUs; experiment requires $GPU_COUNT"

if ! kubectl --context "$KUBE_CONTEXT" get namespace "$NAMESPACE" >/dev/null 2>&1; then
  echo "namespace '$NAMESPACE' does not exist yet; setup scripts will create it"
fi

if kubectl --context "$KUBE_CONTEXT" -n "$NAMESPACE" get secret "$MODEL_SECRET_NAME" >/dev/null 2>&1; then
  echo "model access secret: present"
else
  echo "model access secret: missing ($MODEL_SECRET_NAME)"
fi

if kubectl --context "$KUBE_CONTEXT" -n "$NAMESPACE" get pvc "$MODEL_CACHE_PVC" >/dev/null 2>&1; then
  echo "model cache PVC: present"
else
  echo "model cache PVC: missing ($MODEL_CACHE_PVC)"
fi

echo "preflight passed: context=$KUBE_CONTEXT GPUs=$gpu_total required=$GPU_COUNT"
