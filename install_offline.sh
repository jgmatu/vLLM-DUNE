#!/usr/bin/env bash
set -euo pipefail

# Bootstrap script for RHEL 10 + Podman + NVIDIA GPU containers.
# It prepares NVIDIA container runtime pieces and validates with nvidia-smi
# inside a CUDA container pulled from docker.io.

if [[ "${EUID}" -ne 0 ]]; then
  echo "This script needs root privileges."
  echo "Run with: sudo bash install_offline.sh"
  exit 1
fi

echo "==> Step 1: Host diagnostics"
if command -v mokutil >/dev/null 2>&1; then
  mokutil --sb-state || true
else
  echo "mokutil not found; skipping Secure Boot check."
fi

if ! command -v nvidia-smi >/dev/null 2>&1; then
  echo "ERROR: nvidia-smi is not available on host."
  echo "Install NVIDIA driver first, then re-run."
  exit 1
fi

if ! nvidia-smi >/dev/null 2>&1; then
  echo "ERROR: nvidia-smi exists but cannot talk to NVIDIA driver."
  echo "Fix host driver state first, then re-run."
  exit 1
fi

echo "Host NVIDIA driver looks healthy."

echo "==> Step 2: Ensure Podman is installed"
if ! command -v podman >/dev/null 2>&1; then
  dnf install -y podman
fi

echo "==> Step 3: Configure NVIDIA repo for libnvidia-container"
cat >/etc/yum.repos.d/nvidia-container-toolkit.repo <<'EOF'
[nvidia-container-toolkit]
name=NVIDIA Container Toolkit
baseurl=https://nvidia.github.io/libnvidia-container/stable/rpm/$basearch
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://nvidia.github.io/libnvidia-container/gpgkey
EOF

echo "==> Step 4: Install NVIDIA container toolkit"
dnf clean all
dnf install -y nvidia-container-toolkit

echo "==> Step 5: Enable Docker CLI emulation quiet mode"
mkdir -p /etc/containers
touch /etc/containers/nodocker

echo "==> Step 6: Validate hook directory"
if [[ ! -d /usr/share/containers/oci/hooks.d ]]; then
  echo "WARNING: hooks directory not found: /usr/share/containers/oci/hooks.d"
  echo "Podman GPU injection may fail without OCI hooks."
fi

echo "==> Step 7: Pull CUDA image from docker.io (explicit registry)"
podman pull docker.io/nvidia/cuda:12.4.1-base-ubuntu22.04

echo "==> Step 8: Run GPU test inside container"
podman run --rm \
  --hooks-dir=/usr/share/containers/oci/hooks.d \
  --security-opt=label=disable \
  --device nvidia.com/gpu=all \
  docker.io/nvidia/cuda:12.4.1-base-ubuntu22.04 \
  nvidia-smi

echo
echo "SUCCESS: Podman can access NVIDIA GPU in container."
echo "Next step: run your vLLM container/build."
