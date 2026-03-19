#!/usr/bin/env bash
set -euo pipefail

# Cleanup helper for vLLM-DUNE runtime artifacts.
#
# Default behavior:
# - Stop/remove container (if exists)
# - Remove log collector pid file if present
# - Keep logs, image, and models
#
# Options:
#   --purge-logs    Remove files inside logs/
#   --purge-image   Remove local image (default vllm-dune:cuda12.4)
#   --purge-cache   Remove Hugging Face cache at models/hf-cache/
#   --purge-models  Remove downloaded model folders under models/ (keeps scripts/notes)
#   --all           Enable all purge options
#   -h, --help      Show help

CONTAINER_CLI="${CONTAINER_CLI:-docker}"
CONTAINER_NAME="${CONTAINER_NAME:-vllm-dune}"
IMAGE_NAME="${IMAGE_NAME:-vllm-dune:cuda12.4}"
LOG_DIR="${LOG_DIR:-logs}"

PURGE_LOGS=0
PURGE_IMAGE=0
PURGE_CACHE=0
PURGE_MODELS=0

usage() {
  cat <<'EOF'
Usage: bash cleanup.sh [options]

Options:
  --purge-logs
  --purge-image
  --purge-cache
  --purge-models
  --all
  -h, --help

Environment overrides:
  CONTAINER_CLI (docker|podman), CONTAINER_NAME, IMAGE_NAME, LOG_DIR
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --purge-logs) PURGE_LOGS=1 ;;
    --purge-image) PURGE_IMAGE=1 ;;
    --purge-cache) PURGE_CACHE=1 ;;
    --purge-models) PURGE_MODELS=1 ;;
    --all)
      PURGE_LOGS=1
      PURGE_IMAGE=1
      PURGE_CACHE=1
      PURGE_MODELS=1
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      usage
      exit 1
      ;;
  esac
  shift
done

if ! command -v "$CONTAINER_CLI" >/dev/null 2>&1; then
  echo "ERROR: container CLI not found: $CONTAINER_CLI"
  exit 1
fi

echo "==> Cleanup with $CONTAINER_CLI"

if "$CONTAINER_CLI" container inspect "$CONTAINER_NAME" >/dev/null 2>&1; then
  echo "Removing container: $CONTAINER_NAME"
  "$CONTAINER_CLI" rm -f "$CONTAINER_NAME" >/dev/null || true
else
  echo "Container not found: $CONTAINER_NAME"
fi

if [[ -f "${LOG_DIR}/${CONTAINER_NAME}.log.pid" ]]; then
  PID="$(cat "${LOG_DIR}/${CONTAINER_NAME}.log.pid" 2>/dev/null || true)"
  if [[ -n "${PID}" ]] && kill -0 "${PID}" >/dev/null 2>&1; then
    echo "Stopping log collector pid: ${PID}"
    kill "${PID}" >/dev/null 2>&1 || true
  fi
  rm -f "${LOG_DIR}/${CONTAINER_NAME}.log.pid"
fi

if [[ "$PURGE_LOGS" == "1" ]]; then
  echo "Purging logs in ${LOG_DIR}/"
  mkdir -p "$LOG_DIR"
  for f in "$LOG_DIR"/*; do
    [[ -e "$f" ]] || continue
    if [[ "$f" != "${LOG_DIR}/.gitkeep" ]]; then
      rm -f "$f"
    fi
  done
fi

if [[ "$PURGE_IMAGE" == "1" ]]; then
  echo "Removing image: $IMAGE_NAME"
  "$CONTAINER_CLI" rmi "$IMAGE_NAME" >/dev/null 2>&1 || true
fi

if [[ "$PURGE_CACHE" == "1" ]]; then
  echo "Removing cache: models/hf-cache/"
  rm -rf models/hf-cache
fi

if [[ "$PURGE_MODELS" == "1" ]]; then
  echo "Removing downloaded model folders under models/"
  mkdir -p models
  for p in models/*; do
    [[ -e "$p" ]] || continue
    base="$(basename "$p")"
    if [[ "$base" == "note.txt" || "$base" == "download_model.sh" || "$base" == "hf-cache" ]]; then
      continue
    fi
    rm -rf "$p"
  done
fi

echo "Cleanup completed."
