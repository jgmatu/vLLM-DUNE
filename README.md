# vLLM-DUNE
Base conceptual de una vLLM air-gapped para entornos RHEL10

## Arranque rapido con Docker + NVIDIA (RHEL 10 host)

1. Pre-requisitos en el host:
   - Driver NVIDIA instalado (`nvidia-smi` debe funcionar).
   - Docker Engine.
   - NVIDIA Container Toolkit configurado para Docker.

2. Configura variables:
   - `cp .env.example .env`
   - Edita `MODEL_ID` y `HF_TOKEN` (si el modelo requiere autenticacion).

3. Construye y levanta:
   - `docker compose build`
   - `docker compose up -d`

4. Prueba la API OpenAI-compatible:
   - `curl http://localhost:8000/v1/models`

Archivos principales:
- `docker-images/Dockerfile.vllm-nvidia-rhel10`: imagen base CUDA + vLLM.
- `docker-compose.yaml`: servicio vLLM con reserva de GPU.

## Descargar modelo en `models/`

Script incluido: `models/download_model.sh`

1. Dependencia minima:
   - `python3 -m pip install -U huggingface_hub`

2. Descargar modelo:
   - `bash models/download_model.sh "Qwen/Qwen2.5-7B-Instruct"`
   - Opcional destino/revision: `bash models/download_model.sh "Qwen/Qwen2.5-7B-Instruct" "models/qwen2.5-7b" "main"`
   - Si el repo es privado: `HF_TOKEN=hf_xxx bash models/download_model.sh "org/model-privado"`

## Script de bootstrap RHEL10 + Podman + NVIDIA

Ejecuta desde cero:

- `sudo bash install_offline.sh`

Este script:
- valida `nvidia-smi` en host,
- instala `nvidia-container-toolkit`,
- crea `/etc/containers/nodocker`,
- prueba GPU en contenedor con `docker.io/nvidia/cuda:12.4.1-base-ubuntu22.04`.
