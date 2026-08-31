#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/lib.sh"
load_experiment_env
for command in kubectl python3 shasum; do
  require_command "$command"
done

variant="${1:-}"
run_id="${2:-run-001}"
[[ -n "$variant" ]] || die "usage: $0 <variant> [run-id]"

# Validate the variant and load its exact knob values.
"$REPO_ROOT/scripts/render.sh" "$variant" >/dev/null

trace="$REPO_ROOT/data/toolagent-shape-trace.jsonl.gz"
expected_trace_sha="f081d6352e0f02862fb242146372b47ececc6f661e92935c528dcceefbdfcb20"
actual_trace_sha="$(shasum -a 256 "$trace" | awk '{print $1}')"
[[ "$actual_trace_sha" == "$expected_trace_sha" ]] || die "trace checksum mismatch"

safe_run_id="$(safe_id "$run_id")"
safe_variant="$(safe_id "$variant")"
export VARIANT="$variant"
export RUN_ID="$safe_run_id"
export BENCH_JOB_NAME="toolagent-${safe_variant}-${safe_run_id}"
export TRACE_CONFIGMAP="toolagent-shape-trace"

[[ "${#BENCH_JOB_NAME}" -le 63 ]] || die "rendered Job name is too long"

output="$REPO_ROOT/.rendered/$variant"
mkdir -p "$output"
python3 "$REPO_ROOT/scripts/render-template.py" \
  "$REPO_ROOT/k8s/aiperf-job.yaml.in" "$output/aiperf-$safe_run_id.yaml"

kubectl --context "$KUBE_CONTEXT" -n "$NAMESPACE" create configmap "$TRACE_CONFIGMAP" \
  --from-file=toolagent-shape-trace.jsonl.gz="$trace" \
  --dry-run=client -o yaml \
  | kubectl --context "$KUBE_CONTEXT" -n "$NAMESPACE" apply -f -

k delete job "$BENCH_JOB_NAME" --ignore-not-found --wait=true
k apply -f "$output/aiperf-$safe_run_id.yaml"

pod=""
for attempt in $(seq 1 180); do
  pod="$(k get pods -l "job-name=$BENCH_JOB_NAME" -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || true)"
  phase="$(k get pod "$pod" -o jsonpath='{.status.phase}' 2>/dev/null || true)"
  [[ -n "$pod" && "$phase" == "Running" ]] && break
  [[ "$phase" == "Failed" ]] && die "benchmark pod failed before measurement"
  sleep 5
done
[[ -n "$pod" ]] || die "benchmark pod was not created"
[[ "$phase" == "Running" ]] || die "benchmark pod did not reach Running state"

result=""
for attempt in $(seq 1 480); do
  if k exec "$pod" -- test -f /artifacts/AIPERF_DONE >/dev/null 2>&1; then
    result=done
    break
  fi
  if k exec "$pod" -- test -f /artifacts/AIPERF_FAILED >/dev/null 2>&1; then
    result=failed
    break
  fi
  sleep 5
done
[[ -n "$result" ]] || die "benchmark did not finish within 40 minutes"

artifact_dir="$REPO_ROOT/artifacts/$variant/$safe_run_id"
[[ ! -e "$artifact_dir" ]] || die "artifact directory already exists: $artifact_dir"
mkdir -p "$artifact_dir"
k cp "$pod:/artifacts/run/." "$artifact_dir"
k exec "$pod" -- touch /artifacts/COLLECTED
if [[ "$result" == "done" ]]; then
  k wait --for=condition=complete "job/$BENCH_JOB_NAME" --timeout=5m
else
  k wait --for=condition=failed "job/$BENCH_JOB_NAME" --timeout=5m || true
fi

profile="$artifact_dir/profile_export.jsonl"
[[ -f "$profile" ]] || die "profile_export.jsonl was not collected"
python3 "$REPO_ROOT/scripts/analyze-profile.py" "$profile" \
  --output "$artifact_dir/strict-summary.json" \
  --expected-requests "$REQUEST_COUNT" \
  --ttft-ms "$TTFT_THRESHOLD_MS" \
  --itl-ms "$ITL_THRESHOLD_MS" \
  --gpu-count "$GPU_COUNT"

[[ "$result" == "done" ]] || die "AIPerf failed; artifacts were preserved at $artifact_dir"
echo "benchmark complete: $artifact_dir"
