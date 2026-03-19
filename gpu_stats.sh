#!/usr/bin/env bash
set -euo pipefail

# Live GPU stats for vLLM troubleshooting.
#
# Usage:
#   bash gpu_stats.sh
#   INTERVAL=1 bash gpu_stats.sh
#   ONCE=1 bash gpu_stats.sh

INTERVAL="${INTERVAL:-2}"
ONCE="${ONCE:-0}"

if ! command -v nvidia-smi >/dev/null 2>&1; then
  echo "ERROR: nvidia-smi not found. NVIDIA driver may be missing."
  exit 1
fi

print_snapshot() {
  date '+%Y-%m-%d %H:%M:%S'
  nvidia-smi | awk '/NVIDIA-SMI/ {print "nvidia_smi_version, " $3; exit}'
  echo "=== NVIDIA-SMI Full Table ==="
  nvidia-smi
  echo
  echo "=== GPU Summary ==="
  nvidia-smi --query-gpu=index,name,utilization.gpu,utilization.memory,memory.used,memory.total,temperature.gpu,power.draw,power.limit \
    --format=csv,noheader,nounits
  echo
  echo "=== GPU Processes ==="
  # Safe fallback if no compute process is running.
  nvidia-smi --query-compute-apps=gpu_uuid,pid,process_name,used_gpu_memory \
    --format=csv,noheader,nounits 2>/dev/null || true
  echo
}

if [[ "$ONCE" == "1" ]]; then
  print_snapshot
  exit 0
fi

echo "Press Ctrl+C to stop. Refresh interval: ${INTERVAL}s"
while true; do
  clear || true
  print_snapshot
  sleep "$INTERVAL"
done
