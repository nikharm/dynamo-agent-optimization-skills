#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/lib.sh"
load_experiment_env
require_command kubectl
require_command curl
require_command jq

local_port="${LOCAL_PORT:-18000}"
log_file="$(mktemp)"
models_file="$(mktemp)"
k port-forward "service/$DGD_NAME-frontend" "$local_port:8000" >"$log_file" 2>&1 &
forward_pid=$!
trap 'kill "$forward_pid" 2>/dev/null || true; rm -f "$log_file" "$models_file"' EXIT

for attempt in $(seq 1 60); do
  if curl -fsS "http://127.0.0.1:$local_port/v1/models" >"$models_file" 2>/dev/null; then
    break
  fi
  sleep 2
done

jq -e --arg model "$MODEL_ID" '.data[] | select(.id == $model)' "$models_file" >/dev/null \
  || die "model endpoint did not expose $MODEL_ID"

response="$(curl -fsS "http://127.0.0.1:$local_port/v1/chat/completions" \
  -H 'Content-Type: application/json' \
  -d "{\"model\":\"$MODEL_ID\",\"messages\":[{\"role\":\"user\",\"content\":\"Reply with exactly: READY\"}],\"max_tokens\":8,\"temperature\":0}")"
printf '%s' "$response" | jq -e '.choices[0].message.content | type == "string"' >/dev/null

echo "smoke test passed"
