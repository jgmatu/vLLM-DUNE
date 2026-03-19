#!/usr/bin/env bash
set -euo pipefail

# Always resolve repo root to avoid path issues.
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

# Run model only (no install, no download).
# Requires host/toolkit/image already prepared and model already present.
#
# Usage:
#   bash run_model_only.sh
#   MODEL_DIR="models/Qwen2.5-7B-Instruct" MODEL_NAME="Qwen2.5-7B-Instruct" bash run_model_only.sh

MODEL_DIR="${MODEL_DIR:-models/Qwen2.5-7B-Instruct}"
MODEL_NAME="${MODEL_NAME:-Qwen2.5-7B-Instruct}"
CONTAINER_CLI="${CONTAINER_CLI:-docker}"

if [[ ! -d "$MODEL_DIR" ]]; then
  echo "ERROR: model directory not found: $MODEL_DIR"
  echo "Download first with:"
  echo "  bash models/download_model.sh \"Qwen/Qwen2.5-7B-Instruct\" \"$MODEL_DIR\""
  exit 1
fi

RUN_VLLM_SCRIPT="${ROOT_DIR}/scripts/run_vllm_docker_local.sh"
if [[ ! -f "$RUN_VLLM_SCRIPT" ]]; then
  RUN_VLLM_SCRIPT="${ROOT_DIR}/run_vllm_docker_local.sh"
fi

if [[ ! -f "$RUN_VLLM_SCRIPT" ]]; then
  echo "ERROR: run_vllm_docker_local.sh not found in 'scripts/' or repo root."
  exit 1
fi

if ! command -v "$CONTAINER_CLI" >/dev/null 2>&1; then
  echo "ERROR: container CLI not found: $CONTAINER_CLI"
  exit 1
fi

if ! command -v nvidia-smi >/dev/null 2>&1 || ! nvidia-smi >/dev/null 2>&1; then
  echo "ERROR: nvidia-smi failed. Host NVIDIA driver is not ready."
  exit 1
fi

echo "Starting model with local directory: $MODEL_DIR"
MODEL_NAME="$MODEL_NAME" CONTAINER_CLI="$CONTAINER_CLI" bash "$RUN_VLLM_SCRIPT" "$MODEL_DIR"
