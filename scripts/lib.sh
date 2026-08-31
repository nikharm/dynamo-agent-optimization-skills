#!/usr/bin/env bash

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
EXPERIMENT_ENV="${EXPERIMENT_ENV:-$REPO_ROOT/config/experiment.env}"

die() {
  echo "ERROR: $*" >&2
  exit 1
}

require_command() {
  command -v "$1" >/dev/null 2>&1 || die "required command not found: $1"
}

load_experiment_env() {
  [[ -f "$EXPERIMENT_ENV" ]] || die "copy config/experiment.env.example to config/experiment.env and edit it"
  set -a
  # shellcheck disable=SC1090
  source "$EXPERIMENT_ENV"
  set +a

  local required=(
    KUBE_CONTEXT NAMESPACE DGD_NAME DYNAMO_IMAGE MODEL_ID MODEL_REVISION TOKENIZER_PATH
    MODEL_SECRET_NAME MODEL_CACHE_PVC MODEL_CACHE_STORAGE_CLASS MODEL_CACHE_SIZE
    GPU_NODE_LABEL_KEY GPU_NODE_LABEL_VALUE WORKER_REPLICAS
    BENCH_NODE_LABEL_KEY BENCH_NODE_LABEL_VALUE BENCH_IMAGE AIPERF_VERSION
    REQUEST_COUNT TTFT_THRESHOLD_MS ITL_THRESHOLD_MS GPU_COUNT HF_HUB_OFFLINE
  )
  local name value
  for name in "${required[@]}"; do
    value="${!name:-}"
    [[ -n "$value" ]] || die "$name is unset"
    [[ "$value" != *REPLACE_ME* ]] || die "$name still contains REPLACE_ME"
  done
}

k() {
  kubectl --context "$KUBE_CONTEXT" -n "$NAMESPACE" "$@"
}

safe_id() {
  printf '%s' "$1" \
    | tr '[:upper:]_' '[:lower:]-' \
    | tr -cd 'a-z0-9.-' \
    | cut -c1-40
}
