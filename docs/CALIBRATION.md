# Guia tecnica de calibracion vLLM (30B-70B, entorno air-gapped)

## 1) Objetivo

Definir un procedimiento repetible para calibrar un despliegue vLLM en entorno air-gapped, con objetivo ajustable entre modelos 30B y 70B, controlando:

- carga de pesos (weights),
- uso de VRAM y RAM,
- picos de asignacion en arranque y primer trafico,
- estabilidad de servicio para carga tipo ingenieria (agente IA + IDE).

Adicionalmente, la calibracion debe observar comportamientos especificos de:

- prompts (longitud, complejidad, contexto acumulado),
- agentes (patrones multi-turn, uso de herramientas y variabilidad de latencia).

## 2) Alcance y supuestos

- **Modelo 30B**: calibracion orientada a **adaptar el servicio al hardware disponible** (VRAM limitada, menos GPUs o nodos). Suele permitir contextos mayores, mas concurrencia o menor offload; es el punto de partida habitual cuando la infra no alcanza comodamente 70B.
- **Modelo 70B**: calibracion de **referencia de alta calidad** en despliegue distribuido (multi-GPU / multi-nodo), cuando el presupuesto de hardware lo permite.
- El mismo procedimiento iterativo aplica a ambos tamanos; los valores numericos de perfiles (seccion 6) estan pensados como guia sobre todo para 70B; con 30B se suelen poder relajar `max_model_len`, batch y offload segun margen medido.
- Infraestructura objetivo: desde **1 nodo / pocas GPUs** (30B) hasta **multi-GPU / multi-nodo** (70B).
- Runtime: Podman o Docker con soporte NVIDIA.
- Precision recomendada inicial: `float16` o `bfloat16` segun compatibilidad.
- Telemetria minima: `nvidia-smi`, logs de vLLM y metricas de latencia API.

## 3) Modos de fallo esperables (30B y 70B)

- OOM durante carga de pesos:
  - sintoma: `torch.OutOfMemoryError` en init.
- Fallo de inicializacion de KV cache:
  - sintoma: `No available memory for the cache blocks`.
- Fallos en profile/compile o warmup:
  - sintoma: `CUBLAS_STATUS_ALLOC_FAILED` o errores de compilacion/runtime.
- Inestabilidad por fragmentacion:
  - reinicios esporadicos o degradacion de latencia tras varios prompts.

## 4) Variables de calibracion (palancas)

Orden de impacto practico:

1. `max_model_len` (impacta directamente en KV cache).
2. `gpu_memory_utilization` (reserva efectiva para vLLM).
3. `cpu_offload_gb` (desplaza presion de VRAM a RAM/PCIe).
4. `max-num-batched-tokens` (picos de memoria por batch).
5. `max-num-seqs` (concurrencia interna y presion de scheduler).
6. `--enforce-eager` (reduce picos de compilacion/cudagraph en hardware sensible).

## 5) Procedimiento iterativo de calibracion

### Fase A: Baseline conservador (arranque garantizado)

Objetivo: arrancar estable y responder `GET /v1/models`.

Valores iniciales sugeridos para 70B:

- `dtype=float16`
- `max_model_len=2048`
- `gpu_memory_utilization=0.88`
- `cpu_offload_gb=8`
- `--enforce-eager --max-num-batched-tokens 128 --max-num-seqs 2`

Si falla arranque:

- bajar `max_model_len` a `1024`,
- subir `cpu_offload_gb` (+2 o +4 GB),
- bajar `max-num-batched-tokens` a `64`.

### Fase B: Ajuste de pesos y RAM host

Objetivo: asegurar que la carga de pesos no sature VRAM ni RAM.

Checklist:

- medir VRAM ocupada tras carga de pesos (sin trafico),
- medir RAM host consumida por offload y page cache,
- validar que queda margen de seguridad:
  - VRAM libre >= 10-15%,
  - RAM libre >= 15-20%.

Si RAM host queda justa:

- reducir `cpu_offload_gb`,
- o ampliar RAM por nodo antes de subir concurrencia.

### Fase C: Control de picos

Objetivo: evitar picos en primer token y bajo rafagas.

Prueba en 3 escalones:

1. 1 sesion activa,
2. concurrencia media (25% del objetivo),
3. pico controlado (40-50% del objetivo).

En cada escalon registrar:

- p50/p95 tiempo a primer token,
- p95 latencia total,
- maximo de VRAM y RAM,
- errores por minuto.

Regla de tuning:

- si hay picos/errores -> bajar `max-num-batched-tokens` y `max-num-seqs`,
- si hay estabilidad y margen -> subir de forma gradual (pasos pequenos).

### Fase D: Optimizacion de capacidad

Objetivo: subir throughput sin romper SLO.

Iterar en ciclos cortos:

1. cambiar una sola variable,
2. ejecutar prueba de 15-30 min,
3. comparar contra baseline,
4. conservar solo cambios con mejora neta.

## 6) Perfiles de referencia para 70B

### Perfil `safe-start`

- `max_model_len=1024`
- `gpu_memory_utilization=0.90`
- `cpu_offload_gb=10`
- `--enforce-eager --max-num-batched-tokens 64 --max-num-seqs 1`

Uso: recuperacion o arranque en infra muy ajustada.

### Perfil `balanced-70b`

- `max_model_len=2048`
- `gpu_memory_utilization=0.88`
- `cpu_offload_gb=8`
- `--enforce-eager --max-num-batched-tokens 128 --max-num-seqs 2`

Uso: baseline recomendado para calibracion.

### Perfil `throughput-70b`

- `max_model_len=4096`
- `gpu_memory_utilization=0.92`
- `cpu_offload_gb=6`
- `--max-num-batched-tokens 256 --max-num-seqs 4`

Uso: solo cuando baseline estable y con margen claro de memoria.

## 7) Criterios de aceptacion tecnica

Se considera calibracion valida si:

- arranque estable en frio y en caliente (>=3 ciclos),
- `GET /v1/models` y prompts de prueba sin errores recurrentes,
- p95 TTFB dentro del objetivo definido por el equipo,
- sin OOM ni fallos de KV cache durante prueba de pico controlado,
- margen de memoria sostenido (sin degradacion progresiva).

## 8) Evidencias minimas a documentar

Por cada iteracion guardar:

- parametros exactos de vLLM,
- logs de arranque y errores,
- snapshot de `nvidia-smi`,
- RAM/Swap host,
- metrica de latencia y throughput.

Esto permite trazar decisiones y repetir la configuracion ganadora en produccion.

