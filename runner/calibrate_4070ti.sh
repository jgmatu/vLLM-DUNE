#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

bash "$ROOT_DIR/scripts/cleanup.sh" >/dev/null 2>&1 || true

CONTAINER_CLI=podman \
MODEL_DIR="models/Qwen2.5-7B-Instruct" \
MODEL_NAME="Qwen2.5-7B-Instruct" \
DTYPE=float16 \
MAX_MODEL_LEN=128 \
GPU_MEMORY_UTILIZATION=0.85 \
CPU_OFFLOAD_GB=10 \
EXTRA_VLLM_ARGS="--enforce-eager --max-num-batched-tokens 16 --max-num-seqs 1" \
bash "$ROOT_DIR/scripts/run_model_only.sh"
