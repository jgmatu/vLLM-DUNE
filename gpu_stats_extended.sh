#!/usr/bin/env bash
set -euo pipefail

# Extended GPU stats + metadata report.
#
# Usage:
#   bash gpu_stats_extended.sh
#   MODE=live INTERVAL=2 bash gpu_stats_extended.sh
#   MODE=snapshot OUTPUT=logs/gpu_report.txt bash gpu_stats_extended.sh
#
# Env:
#   MODE=snapshot|live (default: snapshot)
#   INTERVAL=<seconds>  (default: 2, only for live)
#   OUTPUT=<file>       (optional, only for snapshot)

MODE="${MODE:-snapshot}"
INTERVAL="${INTERVAL:-2}"
OUTPUT="${OUTPUT:-}"

if ! command -v nvidia-smi >/dev/null 2>&1; then
  echo "ERROR: nvidia-smi not found. NVIDIA driver may be missing."
  exit 1
fi

print_snapshot() {
  echo "===== TIMESTAMP ====="
  date
  echo

  echo "===== HOST METADATA ====="
  hostnamectl 2>/dev/null || true
  uname -a
  echo

  echo "===== NVIDIA SUMMARY ====="
  # driver_version is queryable; CUDA version is read from nvidia-smi header.
  nvidia-smi --query-gpu=driver_version --format=csv,noheader | head -n 1 | awk -F',' '{print "driver_version, "$1}'
  nvidia-smi | awk -F'CUDA Version: ' '/CUDA Version/ {split($2,a," "); print "cuda_version, " a[1]; exit}'
  echo

  echo "===== GPU DETAILS ====="
  nvidia-smi \
    --query-gpu=index,uuid,name,pci.bus_id,pstate,utilization.gpu,utilization.memory,memory.used,memory.free,memory.total,temperature.gpu,power.draw,power.limit,clocks.current.graphics,clocks.current.memory,fan.speed \
    --format=csv,noheader,nounits
  echo

  echo "===== GPU PROCESSES (compute apps) ====="
  nvidia-smi \
    --query-compute-apps=gpu_uuid,pid,process_name,used_gpu_memory \
    --format=csv,noheader,nounits 2>/dev/null || echo "No compute processes found."
  echo

  echo "===== GPU PROCESSES (full nvidia-smi table) ====="
  nvidia-smi
  echo

  echo "===== CONTAINERS ====="
  echo "-- podman --"
  podman ps -a --format "table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}" 2>/dev/null || true
  echo
  echo "-- docker --"
  docker ps -a --format "table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}" 2>/dev/null || true
}

run_live() {
  echo "Live mode. Ctrl+C to stop. Interval: ${INTERVAL}s"
  while true; do
    clear || true
    echo "===== TIMESTAMP ====="
    date
    echo
    echo "===== GPU QUICK STATS ====="
    nvidia-smi \
      --query-gpu=index,name,utilization.gpu,utilization.memory,memory.used,memory.total,temperature.gpu,power.draw,power.limit \
      --format=csv,noheader,nounits
    echo
    echo "===== GPU PROCESSES ====="
    nvidia-smi \
      --query-compute-apps=pid,process_name,used_gpu_memory \
      --format=csv,noheader,nounits 2>/dev/null || echo "No compute processes found."
    echo
    sleep "$INTERVAL"
  done
}

case "$MODE" in
  snapshot)
    if [[ -n "$OUTPUT" ]]; then
      mkdir -p "$(dirname "$OUTPUT")"
      print_snapshot | tee "$OUTPUT"
      echo
      echo "Saved report to: $OUTPUT"
    else
      print_snapshot
    fi
    ;;
  live)
    run_live
    ;;
  *)
    echo "ERROR: invalid MODE='$MODE'. Use snapshot or live."
    exit 1
    ;;
esac
