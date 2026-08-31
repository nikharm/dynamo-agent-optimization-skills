#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/lib.sh"
load_experiment_env
require_command jq
require_command python3

variant="${1:-}"
[[ -n "$variant" ]] || die "usage: $0 <variant>"

variants="$REPO_ROOT/config/variants.json"
jq -e --arg variant "$variant" '.[$variant]' "$variants" >/dev/null \
  || die "unknown variant '$variant'; see config/variants.json"

export VARIANT="$variant"
export MAX_NUM_BATCHED_TOKENS
export GPU_MEMORY_UTILIZATION
export ROUTER_DECAY
MAX_NUM_BATCHED_TOKENS="$(jq -r --arg variant "$variant" '.[$variant].max_num_batched_tokens' "$variants")"
GPU_MEMORY_UTILIZATION="$(jq -r --arg variant "$variant" '.[$variant].gpu_memory_utilization' "$variants")"
ROUTER_DECAY="$(jq -r --arg variant "$variant" '.[$variant].router_decay' "$variants")"

output="$REPO_ROOT/.rendered/$variant"
mkdir -p "$output"

python3 "$REPO_ROOT/scripts/render-template.py" "$REPO_ROOT/k8s/dgd.yaml.in" "$output/dgd.yaml"
python3 "$REPO_ROOT/scripts/render-template.py" "$REPO_ROOT/k8s/model-cache-pvc.yaml.in" "$output/model-cache-pvc.yaml"
python3 "$REPO_ROOT/scripts/render-template.py" "$REPO_ROOT/k8s/model-download-job.yaml.in" "$output/model-download-job.yaml"

echo "$output"
