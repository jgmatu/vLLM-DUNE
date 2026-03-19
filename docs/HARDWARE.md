# Hardware Guide for vLLM (Air-Gapped, NVIDIA A100/H100)

## 1) Objetivo

Definir una base de infraestructura de hardware para servir modelos con vLLM en entornos air-gapped, usando GPUs NVIDIA A100 para:

- mayor capacidad de VRAM por GPU,
- mejor estabilidad de inferencia en modelos 7B+,
- escalado horizontal y vertical de throughput.

## 2) Requisitos funcionales

La plataforma debe permitir:

- carga de modelos grandes sin ajustes extremos de memoria,
- servicio OpenAI-compatible de vLLM con baja latencia,
- operación sin salida a internet (air-gapped),
- mantenimiento y observabilidad local.

## 3) Opciones de GPU A100 recomendadas

### A100 40GB (PCIe/SXM)

- Adecuada para 7B/13B con margen de KV cache.
- Buen equilibrio costo/rendimiento para inferencia.

### A100 80GB (PCIe/SXM)

- Recomendada para 30B+ y contextos largos.
- Mayor margen para batching y concurrencia.

### H100 80GB (PCIe/SXM)

- Recomendada para cargas de alta concurrencia, latencia baja y modelos grandes.
- Mejor rendimiento por GPU para inferencia intensiva y contextos largos.
- Mayor coste inicial, pero menor coste por token en cargas sostenidas.

## 4) Topologias recomendadas

### Escenario A: 1 nodo, 1-2 GPUs A100

- Uso: PoC robusta / entorno preproduccion air-gapped.
- Beneficio: simplicidad operativa.

### Escenario B: 1 nodo, 4 GPUs A100

- Uso: produccion con alta concurrencia.
- Beneficio: paralelismo tensor/data y mayor throughput.

### Escenario C: 2+ nodos, 4-8 GPUs por nodo

- Uso: cluster de inferencia multi-modelo.
- Requiere red de baja latencia (200GbE o InfiniBand segun diseño).

## 5) Especificacion tecnica recomendada (servidor IA air-gapped)

### Perfil minimo (A100 40GB x2)

- CPU: 2x AMD EPYC o 2x Intel Xeon (>=48 cores totales)
- RAM: 512 GB ECC
- GPU: 2x NVIDIA A100 40GB
- Storage SO: 2x NVMe 1.92TB en RAID1
- Storage modelos/datasets: 4x NVMe 3.84TB (RAID10 o ZFS mirror+stripe)
- Red: 2x 25GbE (management + data)
- PSU: redundante N+1 (1600W+ segun chasis)
- BMC/IPMI: obligatorio para operacion remota

### Perfil recomendado (A100 80GB x4)

- CPU: 2x EPYC/Xeon (>=64 cores totales)
- RAM: 1 TB ECC
- GPU: 4x NVIDIA A100 80GB
- Interconexion GPU: NVLink/NVSwitch (preferible si chasis SXM)
- Storage SO: 2x NVMe 1.92TB RAID1
- Storage modelos: 8x NVMe U.2/U.3 3.84TB+ (alto IOPS)
- Red: 2x 100GbE o 1x 200GbE (segun arquitectura)
- PSU: redundante N+1/N+N, margen para picos de GPU

### Perfil alto rendimiento (H100 80GB x4)

- CPU: 2x EPYC/Xeon (>=96 cores totales)
- RAM: 1-2 TB ECC
- GPU: 4x NVIDIA H100 80GB
- Interconexion GPU: NVLink/NVSwitch (preferible en SXM)
- Storage SO: 2x NVMe 1.92TB RAID1
- Storage modelos: 8x NVMe 3.84TB+ (alto IOPS, baja latencia)
- Red: 2x 200GbE o InfiniBand 200/400Gbps
- PSU: redundante N+N con margen para picos de acelerador

## 6) Dimensionamiento rapido por modelo

- 7B: 1x A100 40GB suele sobrar para inferencia estable.
- 13B: 1x A100 80GB recomendado (o 2x 40GB segun config).
- 30B+: 2x A100 80GB o mas, dependiendo de contexto y batch.
- 70B: 4x A100 80GB (o arquitectura distribuida equivalente).

Nota: el consumo de memoria depende de dtype, longitud de contexto, KV cache, batch y estrategia de paralelismo.

## 7) Presupuesto aproximado (CAPEX orientativo, EUR)

Rangos orientativos para 2026, sin incluir IVA, soporte premium ni costes de obra CPD.

- Escenario A (1 nodo, 1-2x A100 40GB): **35k-85k EUR**
- Escenario B (1 nodo, 4x A100 80GB): **150k-280k EUR**
- Escenario C (2 nodos, 4-8 GPUs A100 por nodo): **320k-1.2M EUR**
- Perfil H100 (1 nodo, 4x H100 80GB): **320k-550k EUR**

Costes OPEX a considerar aparte: energia, refrigeracion, soporte hardware, repuestos y personal de operacion.

## 8) Throughput estimado (tokens/s)

Valores aproximados para vLLM, dependientes de modelo, longitud de contexto, batch, precision (`fp16`/`bf16`) y mezcla de prompts.

- 1x A100 40GB (modelo 7B): **120-300 tok/s**
- 2x A100 40GB (7B, mayor concurrencia): **220-550 tok/s**
- 4x A100 80GB (7B/13B): **700-1800 tok/s**
- 4x A100 80GB (30B): **250-700 tok/s**
- 4x H100 80GB (7B/13B): **1400-3500 tok/s**
- 4x H100 80GB (30B/70B con paralelismo): **450-1500 tok/s**

Para SLO formales, se recomienda benchmark interno con prompts reales y 3 perfiles de carga: interactivo, mixto y throughput.

## 9) Requisitos de plataforma (software/firmware)

- BIOS/UEFI:
  - Above 4G decoding: habilitado
  - SR-IOV/IOMMU: segun politica de virtualizacion
  - Secure Boot: gestionar firma de modulos NVIDIA o deshabilitar en laboratorio
- OS base: RHEL-compatible de ciclo largo
- Driver NVIDIA: version certificada para CUDA objetivo
- NVIDIA Container Toolkit: instalado y validado
- Runtime: Podman o Docker (con GPU runtime funcional)

## 10) Flujo de despliegue air-gapped

1. Preparar repositorio local de paquetes OS y dependencias Python.
2. Validar driver y `nvidia-smi` en host.
3. Validar `nvidia-smi` dentro de contenedor CUDA.
4. Cargar imagenes OCI de forma offline (`.tar`).
5. Cargar modelos en almacenamiento local (`models/` o NAS interno).
6. Arrancar vLLM con perfiles de memoria definidos.
7. Verificar API (`/v1/models`) y monitorizar VRAM/latencia.

## 11) Checklist de aceptacion de hardware

- El host detecta todas las A100 sin errores ECC criticos.
- `nvidia-smi` y telemetria de potencia/temperatura estables.
- Contenedor GPU funcional con `nvidia-smi`.
- vLLM arranca modelo objetivo sin `EngineCore failed to start`.
- Latencia y throughput cumplen SLO internos.
- Procedimientos de backup y reemplazo de hardware documentados.

## 12) Consideraciones de seguridad (air-gapped)

- Segmentacion de red por zonas (ingesta, inferencia, gestion).
- Inventario y control de medios extraibles.
- Repositorios internos firmados y versionados.
- Politica de parches offline con ventanas de mantenimiento.
- Logs y auditoria centralizados en infraestructura interna.

