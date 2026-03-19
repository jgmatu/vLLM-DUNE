# vLLM-DUNE
Base conceptual de una vLLM air-gapped para entornos RHEL10

## Uso recomendado (RHEL10 + Podman + NVIDIA)

### Quickstart en 1 comando

`bash bootstrap_and_run.sh`

Opcional (si ya tienes host/modelo preparado):

`SKIP_HOST_SETUP=1 SKIP_DOWNLOAD=1 MODEL_DIR="models/Qwen2.5-7B-Instruct" bash bootstrap_and_run.sh`

Si ya esta todo instalado y solo quieres ejecutar el modelo:

`bash run_model_only.sh`

Para limpiar contenedor y artefactos:

`bash cleanup.sh`

Opcional limpieza completa:

`bash cleanup.sh --all`

### 1) Preparar host desde cero

Ejecuta:

`sudo bash install_offline.sh`

Este script:
- valida `nvidia-smi` en host,
- instala `nvidia-container-toolkit`,
- crea `/etc/containers/nodocker`,
- prueba GPU en contenedor con `docker.io/nvidia/cuda:12.4.1-base-ubuntu22.04`.

### 2) Descargar modelo en `models/`

Dependencia minima:

`python3 -m pip install -U huggingface_hub`

Ejemplos:
- `bash models/download_model.sh "Qwen/Qwen2.5-7B-Instruct"`
- `bash models/download_model.sh "Qwen/Qwen2.5-7B-Instruct" "models/qwen2.5-7b" "main"`
- `HF_TOKEN=hf_xxx bash models/download_model.sh "org/model-privado"`
- Si por error pasas `models/Qwen2.5-7B-Instruct` como `MODEL_ID`, el script lo corrige a `Qwen/Qwen2.5-7B-Instruct`.

### 3) Levantar vLLM con el modelo local

Pasos con tu carpeta actual (`models/Qwen2.5-7B-Instruct`):

1. Arrancar contenedor:
   - `bash run_vllm_docker_local.sh "models/Qwen2.5-7B-Instruct"`
   - Para forzar nombre de modelo servido: `MODEL_NAME="Qwen2.5-7B-Instruct" bash run_vllm_docker_local.sh "models/Qwen2.5-7B-Instruct"`

2. Ver logs de carga del modelo:
   - `docker logs -f vllm-dune`
   - Al arrancar, tambien se guarda un fichero en `logs/` con timestamp.

3. Probar endpoint OpenAI-compatible:
   - `curl http://localhost:8000/v1/models`

4. (Opcional) Probar una generacion:
   - `curl http://localhost:8000/v1/chat/completions -H "Content-Type: application/json" -d '{"model":"Qwen2.5-7B-Instruct","messages":[{"role":"user","content":"Di hola en una linea"}]}'`

Tambien puedes usar script Docker-compatible (Docker o Podman emulando Docker):

`bash run_vllm_docker_local.sh "models/Qwen2.5-7B-Instruct"`

### 4) Verificar servicio

- `curl http://localhost:8000/v1/models`
- `podman logs -f vllm-dune`
- `ls -lah logs/`

### 5) Agente de prueba (prompt tonto)

Script: `src/test_agent.py`

- Prompt por defecto:
  - `python3 src/test_agent.py`
- Prompt personalizado:
  - `python3 src/test_agent.py "cuenta un chiste corto"`
- Stream anonimo para usuarios de prueba:
  - `python3 src/test_agent.py --stream "hola, responde en una frase"`
- Si cambias endpoint/modelo:
  - `VLLM_BASE_URL="http://localhost:8000" VLLM_MODEL="Qwen2.5-7B-Instruct" python3 src/test_agent.py "hola"`

---

## Alternativa: Docker Compose

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
