#!/usr/bin/env bash
set -euo pipefail

# Always resolve repo root to avoid path issues.
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

# Start vLLM with retry profiles for 12GB-class GPUs.
#
# Usage:
#   bash start_retry.sh
#   MODEL_DIR="models/Qwen2.5-7B-Instruct" CONTAINER_CLI=podman bash start_retry.sh

MODEL_DIR="${MODEL_DIR:-models/Qwen2.5-7B-Instruct}"
CONTAINER_CLI="${CONTAINER_CLI:-podman}"
HEALTH_URL="${HEALTH_URL:-http://localhost:8000/v1/models}"

if [[ ! -f "run_model_only.sh" ]] || [[ ! -f "cleanup.sh" ]]; then
  echo "ERROR: run from repository root."
  exit 1
fi

RUN_MODEL_ONLY_SCRIPT="${ROOT_DIR}/scripts/run_model_only.sh"
if [[ ! -f "$RUN_MODEL_ONLY_SCRIPT" ]]; then
  RUN_MODEL_ONLY_SCRIPT="${ROOT_DIR}/run_model_only.sh"
fi

CLEANUP_SCRIPT="${ROOT_DIR}/scripts/cleanup.sh"
if [[ ! -f "$CLEANUP_SCRIPT" ]]; then
  CLEANUP_SCRIPT="${ROOT_DIR}/cleanup.sh"
fi

if [[ ! -f "$RUN_MODEL_ONLY_SCRIPT" ]] || [[ ! -f "$CLEANUP_SCRIPT" ]]; then
  echo "ERROR: missing run/model scripts (checked scripts/ and repo root)."
  exit 1
fi

run_profile() {
  local name="$1"
  local dtype="$2"
  local max_model_len="$3"
  local gpu_mem="$4"
  local cpu_offload="$5"
  local extra_vllm_args="${6:-}"

  echo
  echo "=== Trying profile: $name ==="
  echo "DTYPE=$dtype MAX_MODEL_LEN=$max_model_len GPU_MEMORY_UTILIZATION=$gpu_mem CPU_OFFLOAD_GB=$cpu_offload"
  if [[ -n "$extra_vllm_args" ]]; then
    echo "EXTRA_VLLM_ARGS=$extra_vllm_args"
  fi

  bash "$CLEANUP_SCRIPT" >/dev/null 2>&1 || true

  MODEL_DIR="$MODEL_DIR" \
  CONTAINER_CLI="$CONTAINER_CLI" \
  DTYPE="$dtype" \
  MAX_MODEL_LEN="$max_model_len" \
  GPU_MEMORY_UTILIZATION="$gpu_mem" \
  CPU_OFFLOAD_GB="$cpu_offload" \
  EXTRA_VLLM_ARGS="$extra_vllm_args" \
  bash "$RUN_MODEL_ONLY_SCRIPT" || return 1

  # wait for startup
  for _ in {1..25}; do
    if curl -fsS "$HEALTH_URL" >/dev/null 2>&1; then
      echo "OK: API responding at $HEALTH_URL"
      return 0
    fi
    sleep 2
  done

  echo "API did not become ready in time."
  return 1
}

# Profile A: balanced-stable
if run_profile "balanced-stable" "float16" "1024" "0.82" "4" "--enforce-eager --max-num-batched-tokens 256 --max-num-seqs 4"; then
  exit 0
fi

# Profile B: aggressive memory saving but higher KV allocation
if run_profile "aggressive-stable" "float16" "768" "0.88" "6" "--enforce-eager --max-num-batched-tokens 192 --max-num-seqs 3"; then
  exit 0
fi

# Profile C: safest startup for fragmented/limited VRAM
if run_profile "safe-eager" "float16" "512" "0.92" "8" "--enforce-eager --max-num-batched-tokens 128 --max-num-seqs 2"; then
  exit 0
fi

# Profile D: ultra-min bootstrap (prioritize successful startup)
if run_profile "ultra-min" "float16" "256" "0.97" "8" "--enforce-eager --max-num-batched-tokens 64 --max-num-seqs 1"; then
  exit 0
fi

echo
echo "ERROR: retries exhausted."
echo "Check latest logs in logs/ and run:"
echo "  bash gpu_stats_extended.sh"
exit 1
