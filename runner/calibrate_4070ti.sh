bash cleanup.sh >/dev/null 2>&1 || true

CONTAINER_CLI=podman \
MODEL_DIR="models/Qwen2.5-3B-Instruct" \
MODEL_NAME="Qwen2.5-3B-Instruct" \
DTYPE=float16 \
MAX_MODEL_LEN=128 \
GPU_MEMORY_UTILIZATION=0.85 \
CPU_OFFLOAD_GB=10 \
EXTRA_VLLM_ARGS="--enforce-eager --max-num-batched-tokens 16 --max-num-seqs 1" \
bash run_model_only.sh
