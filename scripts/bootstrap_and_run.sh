#!/usr/bin/env bash
set -euo pipefail

# Always resolve repo root to avoid path issues.
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

# End-to-end helper:
# 1) Prepare host (optional): install_offline.sh
# 2) Download model (optional): models/download_model.sh
# 3) Run vLLM with local model: run_vllm_docker_local.sh
#
# Usage:
#   bash bootstrap_and_run.sh
#   MODEL_ID="Qwen/Qwen2.5-7B-Instruct" bash bootstrap_and_run.sh
#   MODEL_DIR="models/Qwen2.5-7B-Instruct" SKIP_HOST_SETUP=1 bash bootstrap_and_run.sh
#
# Env vars:
#   MODEL_ID         Hugging Face repo id (default: Qwen/Qwen2.5-7B-Instruct)
#   MODEL_DIR        Local target dir (default: models/Qwen2.5-7B-Instruct)
#   MODEL_REVISION   HF revision (default: main)
#   SKIP_HOST_SETUP  1 to skip install_offline.sh (default: 0)
#   SKIP_DOWNLOAD    1 to skip model download step (default: 0)
#   HF_TOKEN         Optional HF token (private models)

MODEL_ID="${MODEL_ID:-Qwen/Qwen2.5-7B-Instruct}"
MODEL_DIR="${MODEL_DIR:-models/Qwen2.5-7B-Instruct}"
MODEL_REVISION="${MODEL_REVISION:-main}"
SKIP_HOST_SETUP="${SKIP_HOST_SETUP:-0}"
SKIP_DOWNLOAD="${SKIP_DOWNLOAD:-0}"
CONTAINER_CLI="${CONTAINER_CLI:-docker}"

echo "==> bootstrap_and_run"
echo "MODEL_ID=$MODEL_ID"
echo "MODEL_DIR=$MODEL_DIR"
echo "MODEL_REVISION=$MODEL_REVISION"
echo "SKIP_HOST_SETUP=$SKIP_HOST_SETUP"
echo "SKIP_DOWNLOAD=$SKIP_DOWNLOAD"
echo "CONTAINER_CLI=$CONTAINER_CLI"
echo

INSTALL_OFFLINE_SCRIPT="${ROOT_DIR}/scripts/install_offline.sh"
if [[ ! -f "$INSTALL_OFFLINE_SCRIPT" ]] || [[ ! -f "$ROOT_DIR/models/download_model.sh" ]] || [[ ! -d "$ROOT_DIR/models" ]]; then
  echo "ERROR: Missing expected scripts/data paths."
  echo "Expected:"
  echo "  $INSTALL_OFFLINE_SCRIPT"
  echo "  $ROOT_DIR/models/download_model.sh"
  exit 1
fi

if [[ "$SKIP_HOST_SETUP" != "1" ]]; then
  echo "==> Step 1/3: Host setup (requires sudo)"
  sudo bash "$INSTALL_OFFLINE_SCRIPT"
else
  echo "==> Step 1/3: Skipped host setup"
fi

if [[ "$SKIP_DOWNLOAD" != "1" ]]; then
  echo "==> Step 2/3: Download model (if needed)"
  bash "$ROOT_DIR/models/download_model.sh" "$MODEL_ID" "$MODEL_DIR" "$MODEL_REVISION"
else
  echo "==> Step 2/3: Skipped model download"
fi

RUN_VLLM_DOCKER_SCRIPT="${ROOT_DIR}/scripts/run_vllm_docker_local.sh"
if [[ ! -f "$RUN_VLLM_DOCKER_SCRIPT" ]]; then
  RUN_VLLM_DOCKER_SCRIPT="${ROOT_DIR}/run_vllm_docker_local.sh"
fi

if [[ ! -f "$RUN_VLLM_DOCKER_SCRIPT" ]]; then
  echo "ERROR: run_vllm_docker_local.sh not found in scripts/ or repo root."
  exit 1
fi

echo "==> Step 3/3: Start vLLM container"
CONTAINER_CLI="$CONTAINER_CLI" bash "$RUN_VLLM_DOCKER_SCRIPT" "$MODEL_DIR"

echo
echo "Done. Quick checks:"
echo "  curl http://localhost:8000/v1/models"
echo "  $CONTAINER_CLI logs -f vllm-dune"
