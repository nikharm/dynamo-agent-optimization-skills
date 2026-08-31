#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/lib.sh"
load_experiment_env

variant="${1:-}"
[[ -n "$variant" ]] || die "usage: $0 <variant>"

# First deployment is used for end-to-end correctness checks.
"$REPO_ROOT/scripts/deploy.sh" "$variant"
"$REPO_ROOT/scripts/smoke.sh"

# Replace the full DGD after smoke so the measured run starts with fresh workers.
"$REPO_ROOT/scripts/deploy.sh" "$variant"
echo "cold measured state is ready; do not send inference traffic before the benchmark"
