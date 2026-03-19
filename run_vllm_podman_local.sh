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
MODEL_NAME="${MODEL_NAME:-Qwen2.5-7B-Instruct}"
VLLM_PORT="${VLLM_PORT:-8000}"
MAX_MODEL_LEN="${MAX_MODEL_LEN:-2048}"
GPU_MEMORY_UTILIZATION="${GPU_MEMORY_UTILIZATION:-0.72}"
DTYPE="${DTYPE:-float16}"
CPU_OFFLOAD_GB="${CPU_OFFLOAD_GB:-4}"
LOG_DIR="${LOG_DIR:-logs}"
PYTORCH_CUDA_ALLOC_CONF="${PYTORCH_CUDA_ALLOC_CONF:-expandable_segments:True}"
EXTRA_VLLM_ARGS="${EXTRA_VLLM_ARGS:-}"
EXTRA_ARGS=()
if [[ -n "$EXTRA_VLLM_ARGS" ]]; then
  # Space-separated extra args, e.g. "--enforce-eager --max-num-seqs 8"
  read -r -a EXTRA_ARGS <<< "$EXTRA_VLLM_ARGS"
fi

if [[ -z "$MODEL_DIR" ]]; then
  echo "ERROR: local model directory is required."
  echo "Usage: bash run_vllm_podman_local.sh \"models/<model-folder>\""
  exit 1
fi

if [[ ! -d "$MODEL_DIR" ]]; then
  echo "ERROR: model directory not found: $MODEL_DIR"
  exit 1
fi

MODEL_SUBDIR=""
if [[ -f "$MODEL_DIR/config.json" || -f "$MODEL_DIR/params.json" ]]; then
  MODEL_SUBDIR="."
else
  for d in "$MODEL_DIR"/*; do
    [[ -d "$d" ]] || continue
    if [[ -f "$d/config.json" || -f "$d/params.json" ]]; then
      MODEL_SUBDIR="$(basename "$d")"
      break
    fi
  done
fi

if [[ -z "$MODEL_SUBDIR" ]]; then
  echo "ERROR: no valid model config found in '$MODEL_DIR'."
  echo "Expected one of:"
  echo "  $MODEL_DIR/config.json"
  echo "  $MODEL_DIR/params.json"
  echo "or inside one direct subfolder."
  echo "The directory appears empty or incomplete."
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

# Extra safety for race/stale state: do not fail if absent.
podman rm -f "$CONTAINER_NAME" >/dev/null 2>&1 || true

ABS_MODEL_DIR="$(realpath "$MODEL_DIR")"
MODEL_PATH_IN_CONTAINER="/models/local-model"
if [[ "$MODEL_SUBDIR" != "." ]]; then
  MODEL_PATH_IN_CONTAINER="/models/local-model/$MODEL_SUBDIR"
fi

echo "Starting vLLM container '$CONTAINER_NAME' on port $VLLM_PORT ..."
echo "Checking GPU visibility inside Podman runtime ..."
if ! podman run --rm \
  --hooks-dir=/usr/share/containers/oci/hooks.d \
  --security-opt=label=disable \
  --device nvidia.com/gpu=all \
  docker.io/nvidia/cuda:12.4.1-base-ubuntu22.04 nvidia-smi >/dev/null 2>&1; then
  echo "ERROR: GPU is not visible inside Podman containers."
  echo "Re-run host prep and toolkit setup:"
  echo "  sudo bash install_offline.sh"
  exit 1
fi

podman run -d \
  --replace \
  --name "$CONTAINER_NAME" \
  --hooks-dir=/usr/share/containers/oci/hooks.d \
  --security-opt=label=disable \
  --device nvidia.com/gpu=all \
  -e NVIDIA_VISIBLE_DEVICES=all \
  -e NVIDIA_DRIVER_CAPABILITIES=compute,utility \
  -e PYTORCH_CUDA_ALLOC_CONF="$PYTORCH_CUDA_ALLOC_CONF" \
  -p "${VLLM_PORT}:8000" \
  -v "${ABS_MODEL_DIR}:/models/local-model:ro" \
  "$IMAGE_NAME" \
  --model "$MODEL_PATH_IN_CONTAINER" \
  --served-model-name "$MODEL_NAME" \
  --dtype "$DTYPE" \
  --host 0.0.0.0 \
  --port 8000 \
  --max-model-len "$MAX_MODEL_LEN" \
  --gpu-memory-utilization "$GPU_MEMORY_UTILIZATION" \
  --cpu-offload-gb "$CPU_OFFLOAD_GB" \
  "${EXTRA_ARGS[@]}"

mkdir -p "$LOG_DIR"
LOG_FILE="${LOG_DIR}/${CONTAINER_NAME}.log"
PID_FILE="${LOG_DIR}/${CONTAINER_NAME}.log.pid"

if [[ -f "$PID_FILE" ]]; then
  OLD_PID="$(cat "$PID_FILE" 2>/dev/null || true)"
  if [[ -n "$OLD_PID" ]] && kill -0 "$OLD_PID" >/dev/null 2>&1; then
    kill "$OLD_PID" >/dev/null 2>&1 || true
  fi
fi

: > "$LOG_FILE"
podman logs -f "$CONTAINER_NAME" >"$LOG_FILE" 2>&1 &
LOG_PID=$!
echo "$LOG_PID" > "$PID_FILE"

echo "vLLM is starting. Check logs with:"
echo "  podman logs -f $CONTAINER_NAME"
echo "Container log file:"
echo "  $LOG_FILE (collector pid: $LOG_PID)"
echo
echo "API test:"
echo "  curl http://localhost:${VLLM_PORT}/v1/models"
