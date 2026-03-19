#!/usr/bin/env bash
set -euo pipefail

# Run vLLM with Podman using a local model folder from models/.
#
# Examples:
#   bash run_vllm_podman_local.sh "models/Qwen2.5-7B-Instruct"
#   VLLM_PORT=8001 MAX_MODEL_LEN=8192 bash run_vllm_podman_local.sh "models/qwen2.5-7b"

MODEL_DIR="${1:-}"
IMAGE_NAME="${IMAGE_NAME:-vllm-dune:cuda12.4}"
CONTAINER_NAME="${CONTAINER_NAME:-vllm-dune}"
VLLM_PORT="${VLLM_PORT:-8000}"
MAX_MODEL_LEN="${MAX_MODEL_LEN:-4096}"
GPU_MEMORY_UTILIZATION="${GPU_MEMORY_UTILIZATION:-0.90}"

if [[ -z "$MODEL_DIR" ]]; then
  echo "ERROR: local model directory is required."
  echo "Usage: bash run_vllm_podman_local.sh \"models/<model-folder>\""
  exit 1
fi

if [[ ! -d "$MODEL_DIR" ]]; then
  echo "ERROR: model directory not found: $MODEL_DIR"
  exit 1
fi

if ! command -v podman >/dev/null 2>&1; then
  echo "ERROR: podman is not installed."
  echo "Run first: sudo bash install_offline.sh"
  exit 1
fi

if ! command -v nvidia-smi >/dev/null 2>&1 || ! nvidia-smi >/dev/null 2>&1; then
  echo "ERROR: host NVIDIA driver is not healthy (nvidia-smi failed)."
  exit 1
fi

if ! podman image exists "$IMAGE_NAME"; then
  echo "Building image '$IMAGE_NAME' from docker-images/Dockerfile.vllm-nvidia-rhel10 ..."
  podman build -t "$IMAGE_NAME" -f docker-images/Dockerfile.vllm-nvidia-rhel10 .
fi

if podman container exists "$CONTAINER_NAME"; then
  echo "Removing previous container '$CONTAINER_NAME' ..."
  podman rm -f "$CONTAINER_NAME" >/dev/null
fi

ABS_MODEL_DIR="$(realpath "$MODEL_DIR")"

echo "Starting vLLM container '$CONTAINER_NAME' on port $VLLM_PORT ..."
podman run -d \
  --name "$CONTAINER_NAME" \
  --hooks-dir=/usr/share/containers/oci/hooks.d \
  --security-opt=label=disable \
  --device nvidia.com/gpu=all \
  -p "${VLLM_PORT}:8000" \
  -v "${ABS_MODEL_DIR}:/models/local-model:ro" \
  "$IMAGE_NAME" \
  --model /models/local-model \
  --host 0.0.0.0 \
  --port 8000 \
  --max-model-len "$MAX_MODEL_LEN" \
  --gpu-memory-utilization "$GPU_MEMORY_UTILIZATION"

echo "vLLM is starting. Check logs with:"
echo "  podman logs -f $CONTAINER_NAME"
echo
echo "API test:"
echo "  curl http://localhost:${VLLM_PORT}/v1/models"
