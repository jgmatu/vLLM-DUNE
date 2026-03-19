#!/usr/bin/env bash
set -euo pipefail

# Download a Hugging Face model into models/ using huggingface_hub.
#
# Usage:
#   ./models/download_model.sh "Qwen/Qwen2.5-7B-Instruct"
#   HF_TOKEN=hf_xxx ./models/download_model.sh "meta-llama/Llama-3.1-8B-Instruct" "models/Llama-3.1-8B"
#   ./models/download_model.sh "Qwen/Qwen2.5-7B-Instruct" "models/qwen" "main"
#
# Args:
#   $1 MODEL_ID   (required)  e.g. org/model
#   $2 DEST_DIR   (optional)  default: models/<repo_name>
#   $3 REVISION   (optional)  default: main

MODEL_ID="${1:-}"
DEST_DIR="${2:-}"
REVISION="${3:-main}"
HF_TOKEN="${HF_TOKEN:-}"

if [[ -z "$MODEL_ID" ]]; then
  echo "ERROR: MODEL_ID is required."
  echo "Example: ./models/download_model.sh \"Qwen/Qwen2.5-7B-Instruct\""
  exit 1
fi

if [[ -z "$DEST_DIR" ]]; then
  REPO_NAME="${MODEL_ID##*/}"
  DEST_DIR="models/${REPO_NAME}"
fi

mkdir -p "$DEST_DIR"

python3 - <<'PY' "$MODEL_ID" "$DEST_DIR" "$REVISION" "$HF_TOKEN"
import os
import sys

model_id = sys.argv[1]
dest_dir = sys.argv[2]
revision = sys.argv[3]
hf_token = sys.argv[4] or None

try:
    from huggingface_hub import snapshot_download
except Exception as exc:
    raise SystemExit(
        "huggingface_hub is not installed. Install with:\n"
        "  python3 -m pip install -U huggingface_hub\n"
        f"Original error: {exc}"
    )

print(f"Downloading '{model_id}' to '{dest_dir}' (revision={revision})...")
snapshot_download(
    repo_id=model_id,
    revision=revision,
    local_dir=dest_dir,
    local_dir_use_symlinks=False,
    token=hf_token,
    resume_download=True,
)
print("Download completed.")
PY

echo "Model files are in: $DEST_DIR"
