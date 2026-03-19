#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

SUDO=""
if [[ "${EUID:-$(id -u)}" -ne 0 ]]; then
  SUDO="sudo"
fi

echo "==> install_offline"
echo "ROOT_DIR=$ROOT_DIR"
echo

# Allow skipping heavyweight steps if the host is already prepared.
SKIP_NVIDIA_TOOLKIT="${SKIP_NVIDIA_TOOLKIT:-0}"   # set to 1 to only validate
SKIP_PODMAN_INSTALL="${SKIP_PODMAN_INSTALL:-0}"   # set to 1 to only validate
SKIP_GPU_TEST="${SKIP_GPU_TEST:-0}"               # set to 1 to skip container test

have_cmd() { command -v "$1" >/dev/null 2>&1; }

echo "==> Check host GPU (nvidia-smi)"
if ! have_cmd nvidia-smi; then
  echo "ERROR: nvidia-smi no encontrado en el host."
  exit 1
fi
nvidia-smi >/dev/null
echo "OK: nvidia-smi funciona."

echo "==> Ensure /etc/containers/nodocker (silence podman docker emulation msg)"
"$SUDO" mkdir -p /etc/containers
"$SUDO" touch /etc/containers/nodocker

echo "==> Ensure Podman present"
if ! have_cmd podman; then
  if [[ "$SKIP_PODMAN_INSTALL" == "1" ]]; then
    echo "ERROR: podman no está instalado y SKIP_PODMAN_INSTALL=1."
    exit 1
  fi
  if have_cmd dnf; then
    echo "Installing podman via dnf ..."
    "$SUDO" dnf -y install podman || true
  fi
fi

if ! have_cmd podman; then
  echo "ERROR: podman no está disponible."
  exit 1
fi
podman --version || true

echo "==> Ensure NVIDIA Container Toolkit present"
if ! have_cmd nvidia-ctk; then
  if [[ "$SKIP_NVIDIA_TOOLKIT" == "1" ]]; then
    echo "WARN: nvidia-ctk no encontrado y SKIP_NVIDIA_TOOLKIT=1."
  else
    if have_cmd dnf; then
      echo "Installing nvidia-container-toolkit via dnf ..."
      "$SUDO" dnf -y install nvidia-container-toolkit || true
    fi
  fi
fi

if ! have_cmd nvidia-ctk; then
  echo "ERROR: nvidia-ctk no está disponible; no puedo configurar el runtime para Podman."
  echo "Solución: instala NVIDIA Container Toolkit en el host o vuelve a ejecutar con red/paquetes disponibles."
  exit 1
fi

"$SUDO" nvidia-ctk runtime configure --runtime=podman || true

# Hooks are expected by Podman GPU integration.
"$SUDO" mkdir -p /usr/share/containers/oci/hooks.d

echo "==> Validation (GPU in container via Podman hooks)"
if [[ "$SKIP_GPU_TEST" == "1" ]]; then
  echo "SKIP_GPU_TEST=1 => saltando prueba de contenedor."
  exit 0
fi

# Image name matches the ones used in the vLLM scripts.
CUDA_IMAGE="docker.io/nvidia/cuda:12.4.1-base-ubuntu22.04"

echo "Pull/test image: $CUDA_IMAGE"

if ! podman run --rm \
  --hooks-dir=/usr/share/containers/oci/hooks.d \
  --security-opt=label=disable \
  --device nvidia.com/gpu=all \
  "$CUDA_IMAGE" nvidia-smi -L >/dev/null 2>&1; then
  echo "ERROR: La GPU NO se ve dentro del contenedor (Podman + NVIDIA hooks falló)."
  echo "Revisa que el runtime de Podman esté configurado correctamente y vuelve a ejecutar."
  exit 1
fi

echo "OK: GPU visible dentro del contenedor."
echo "==> install_offline: done"

