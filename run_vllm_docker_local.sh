#!/usr/bin/env bash
set -euo pipefail

# Run vLLM with Docker-compatible CLI using a local model directory.
# Works with real Docker or Docker CLI emulated by Podman.
#
# Usage:
#   bash run_vllm_docker_local.sh "models/qwen2.5-7b"
#   CONTAINER_CLI=podman VLLM_PORT=8001 bash run_vllm_docker_local.sh "models/qwen2.5-7b"

MODEL_DIR="${1:-}"
CONTAINER_CLI="${CONTAINER_CLI:-docker}"
IMAGE_NAME="${IMAGE_NAME:-vllm-dune:cuda12.4}"
CONTAINER_NAME="${CONTAINER_NAME:-vllm-dune}"
MODEL_NAME="${MODEL_NAME:-Qwen2.5-7B-Instruct}"
VLLM_PORT="${VLLM_PORT:-8000}"
MAX_MODEL_LEN="${MAX_MODEL_LEN:-4096}"
GPU_MEMORY_UTILIZATION="${GPU_MEMORY_UTILIZATION:-0.90}"
LOG_DIR="${LOG_DIR:-logs}"

if [[ -z "$MODEL_DIR" ]]; then
  echo "ERROR: local model directory is required."
  echo "Usage: bash run_vllm_docker_local.sh \"models/<model-folder>\""
  exit 1
fi

if [[ ! -d "$MODEL_DIR" ]]; then
  echo "ERROR: model directory not found: $MODEL_DIR"
  exit 1
fi

if ! command -v "$CONTAINER_CLI" >/dev/null 2>&1; then
  echo "ERROR: container CLI not found: $CONTAINER_CLI"
  echo "Set CONTAINER_CLI=docker or CONTAINER_CLI=podman."
  exit 1
fi

if ! command -v nvidia-smi >/dev/null 2>&1 || ! nvidia-smi >/dev/null 2>&1; then
  echo "ERROR: host NVIDIA driver is not healthy (nvidia-smi failed)."
  exit 1
fi

if ! "$CONTAINER_CLI" image inspect "$IMAGE_NAME" >/dev/null 2>&1; then
  echo "Building image '$IMAGE_NAME' ..."
  "$CONTAINER_CLI" build -t "$IMAGE_NAME" -f docker-images/Dockerfile.vllm-nvidia-rhel10 .
fi

# Remove same-name container if present (safe no-op if missing).
if "$CONTAINER_CLI" container inspect "$CONTAINER_NAME" >/dev/null 2>&1; then
  echo "Removing previous container '$CONTAINER_NAME' ..."
  "$CONTAINER_CLI" rm -f "$CONTAINER_NAME" >/dev/null || true
fi

ABS_MODEL_DIR="$(realpath "$MODEL_DIR")"

RUN_ARGS=(
  run -d
  --name "$CONTAINER_NAME"
  -p "${VLLM_PORT}:8000"
  -v "${ABS_MODEL_DIR}:/models/local-model:ro"
  "$IMAGE_NAME"
  --model /models/local-model
  --served-model-name "$MODEL_NAME"
  --host 0.0.0.0
  --port 8000
  --max-model-len "$MAX_MODEL_LEN"
  --gpu-memory-utilization "$GPU_MEMORY_UTILIZATION"
)

if [[ "$CONTAINER_CLI" == "podman" ]]; then
  RUN_ARGS=(
    run -d
    --replace
    --name "$CONTAINER_NAME"
    --hooks-dir=/usr/share/containers/oci/hooks.d
    --security-opt=label=disable
    --device nvidia.com/gpu=all
    -p "${VLLM_PORT}:8000"
    -v "${ABS_MODEL_DIR}:/models/local-model:ro"
    "$IMAGE_NAME"
    --model /models/local-model
    --served-model-name "$MODEL_NAME"
    --host 0.0.0.0
    --port 8000
    --max-model-len "$MAX_MODEL_LEN"
    --gpu-memory-utilization "$GPU_MEMORY_UTILIZATION"
  )
else
  RUN_ARGS=(
    run -d
    --name "$CONTAINER_NAME"
    --gpus all
    -p "${VLLM_PORT}:8000"
    -v "${ABS_MODEL_DIR}:/models/local-model:ro"
    "$IMAGE_NAME"
    --model /models/local-model
    --served-model-name "$MODEL_NAME"
    --host 0.0.0.0
    --port 8000
    --max-model-len "$MAX_MODEL_LEN"
    --gpu-memory-utilization "$GPU_MEMORY_UTILIZATION"
  )
fi

echo "Starting vLLM container '$CONTAINER_NAME' on port $VLLM_PORT ..."
"$CONTAINER_CLI" "${RUN_ARGS[@]}"

mkdir -p "$LOG_DIR"
TIMESTAMP="$(date +%Y%m%d-%H%M%S)"
LOG_FILE="${LOG_DIR}/${CONTAINER_NAME}-${TIMESTAMP}.log"
"$CONTAINER_CLI" logs -f "$CONTAINER_NAME" >"$LOG_FILE" 2>&1 &
LOG_PID=$!
echo "$LOG_PID" > "${LOG_DIR}/${CONTAINER_NAME}.log.pid"

echo "vLLM is starting. Check logs with:"
echo "  $CONTAINER_CLI logs -f $CONTAINER_NAME"
echo "Container log file:"
echo "  $LOG_FILE (collector pid: $LOG_PID)"
echo
echo "API test:"
echo "  curl http://localhost:${VLLM_PORT}/v1/models"
