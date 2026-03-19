# vLLM-DUNE
Base conceptual de una vLLM air-gapped para entornos RHEL10

## Uso recomendado (RHEL10 + Podman + NVIDIA)

### Quickstart en 1 comando

`bash bootstrap_and_run.sh`

Opcional (si ya tienes host/modelo preparado):

`SKIP_HOST_SETUP=1 SKIP_DOWNLOAD=1 MODEL_DIR="models/Qwen2.5-7B-Instruct" bash bootstrap_and_run.sh`

Si ya esta todo instalado y solo quieres ejecutar el modelo:

`bash run_model_only.sh`

Arranque con reintento automatico (OOM-friendly en 12GB VRAM):

`bash start_retry.sh`

El reintento prueba 3 perfiles: `balanced-stable`, `aggressive-stable` y `safe-eager` (todos con `--enforce-eager` y batch reducido para evitar `CUBLAS_STATUS_ALLOC_FAILED`).
Nota: si aparece `No available memory for the cache blocks`, hay que subir `GPU_MEMORY_UTILIZATION` (no bajarlo) y reducir batch/seq.

Para limpiar contenedor y artefactos:

`bash cleanup.sh`

Opcional limpieza completa:

`bash cleanup.sh --all`

Limpiar solo contenedor + imagen (para forzar rebuild):

`bash cleanup.sh --purge-image`

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
- Si ves error de `Invalid repository ID or local directory`, revisa que exista `config.json` dentro de la carpeta descargada.

### 3) Levantar vLLM con el modelo local

Pasos con tu carpeta actual (`models/Qwen2.5-7B-Instruct`):

1. Arrancar contenedor:
   - `bash run_vllm_docker_local.sh "models/Qwen2.5-7B-Instruct"`
   - Para forzar nombre de modelo servido: `MODEL_NAME="Qwen2.5-7B-Instruct" bash run_vllm_docker_local.sh "models/Qwen2.5-7B-Instruct"`
   - Si tienes OOM en 12GB VRAM: `DTYPE=float16 MAX_MODEL_LEN=2048 GPU_MEMORY_UTILIZATION=0.72 CPU_OFFLOAD_GB=4 bash run_vllm_docker_local.sh "models/Qwen2.5-7B-Instruct"`

2. Ver logs de carga del modelo:
   - `docker logs -f vllm-dune`
   - Al arrancar, se guarda en un unico fichero: `logs/vllm-dune.log`.

3. Probar endpoint OpenAI-compatible:
   - `curl http://localhost:8000/v1/models`

4. (Opcional) Probar una generacion:
   - `curl http://localhost:8000/v1/chat/completions -H "Content-Type: application/json" -d '{"model":"Qwen2.5-7B-Instruct","messages":[{"role":"user","content":"Di hola en una linea"}]}'`

Tambien puedes usar script Docker-compatible (Docker o Podman emulando Docker):

`bash run_vllm_docker_local.sh "models/Qwen2.5-7B-Instruct"`

Nota: si `docker` esta emulado por Podman, el script detecta ese caso y aplica flags GPU de Podman automaticamente.
Antes de arrancar vLLM, el script verifica que `nvidia-smi` funciona dentro de contenedor.

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

### 6) Stats GPU extendidas

Script simple (`gpu_stats.sh`):
- Una sola muestra:
  - `ONCE=1 bash gpu_stats.sh`
- Modo live:
  - `bash gpu_stats.sh`
- Modo live cada 1s:
  - `INTERVAL=1 bash gpu_stats.sh`

Script extendido (`gpu_stats_extended.sh`):
- Snapshot:
  - `bash gpu_stats_extended.sh`
- Tabla clasica exacta de `nvidia-smi`:
  - `TABLE_ONLY=1 bash gpu_stats_extended.sh`
- Live:
  - `MODE=live INTERVAL=2 bash gpu_stats_extended.sh`
- Live sin limpiar pantalla:
  - `MODE=live NO_CLEAR=1 bash gpu_stats_extended.sh`

Ejemplo de salida ASCII (`TABLE_ONLY=1 bash gpu_stats_extended.sh`):

```text
Thu Mar 19 14:15:40 2026       
+-----------------------------------------------------------------------------------------+
| NVIDIA-SMI 590.48.01              Driver Version: 590.48.01      CUDA Version: 13.1     |
+-----------------------------------------+------------------------+----------------------+
| GPU  Name                 Persistence-M | Bus-Id          Disp.A | Volatile Uncorr. ECC |
| Fan  Temp   Perf          Pwr:Usage/Cap |           Memory-Usage | GPU-Util  Compute M. |
|                                         |                        |               MIG M. |
|=========================================+========================+======================|
|   0  NVIDIA GeForce RTX 4070 Ti     Off |   00000000:2D:00.0  On |                  N/A |
|  0%   35C    P8             16W /  285W |     298MiB /  12282MiB |      0%      Default |
|                                         |                        |                  N/A |
+-----------------------------------------+------------------------+----------------------+

+-----------------------------------------------------------------------------------------+
| Processes:                                                                              |
|  GPU   GI   CI              PID   Type   Process name                        GPU Memory |
|        ID   ID                                                               Usage      |
|=========================================================================================|
|    0   N/A  N/A            3238      G   /usr/bin/gnome-shell                     82MiB |
|    0   N/A  N/A            4178    C+G   /usr/bin/ptyxis                          51MiB |
|    0   N/A  N/A            4273      G   /usr/bin/Xwayland                         4MiB |
|    0   N/A  N/A            4568      G   /usr/share/cursor/cursor                 96MiB |
+-----------------------------------------------------------------------------------------+
```
- Verbose:
  - `VERBOSE=1 bash gpu_stats_extended.sh`
  - `MODE=live VERBOSE=1 FULL_TABLE=1 INTERVAL=3 bash gpu_stats_extended.sh`

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
