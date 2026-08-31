#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/lib.sh"
load_experiment_env
require_command kubectl

variant="${1:-}"
[[ -n "$variant" ]] || die "usage: $0 <variant>"
rendered="$($REPO_ROOT/scripts/render.sh "$variant")"

kubectl --context "$KUBE_CONTEXT" create namespace "$NAMESPACE" \
  --dry-run=client -o yaml \
  | kubectl --context "$KUBE_CONTEXT" apply -f -

k get secret "$MODEL_SECRET_NAME" >/dev/null \
  || die "missing model Secret '$MODEL_SECRET_NAME'"
k get pvc "$MODEL_CACHE_PVC" >/dev/null \
  || die "missing model cache PVC '$MODEL_CACHE_PVC'"

# Full replacement gives every comparison a fresh worker prefix cache.
k delete dynamographdeployment "$DGD_NAME" --ignore-not-found --wait=true --timeout=20m
for attempt in $(seq 1 120); do
  remaining="$(k get pods -o name 2>/dev/null | awk -F/ -v prefix="$DGD_NAME-" '$2 ~ "^" prefix {count++} END {print count+0}')"
  [[ "$remaining" -eq 0 ]] && break
  sleep 5
done
[[ "$remaining" -eq 0 ]] || die "previous DGD pods did not terminate"
k apply -f "$rendered/dgd.yaml"

for attempt in $(seq 1 180); do
  state="$(k get dynamographdeployment "$DGD_NAME" -o jsonpath='{.status.state}' 2>/dev/null || true)"
  if [[ "$state" == "successful" ]]; then
    echo "deployment ready: variant=$variant state=$state"
    exit 0
  fi
  if [[ "$state" =~ failed|error ]]; then
    k describe dynamographdeployment "$DGD_NAME"
    die "deployment entered state '$state'"
  fi
  sleep 10
done

k describe dynamographdeployment "$DGD_NAME"
die "deployment did not become successful within 30 minutes"
