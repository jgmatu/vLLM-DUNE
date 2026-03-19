# Hardware Design Guide vLLM Air-Gapped (20-40 devs)

## 1) Contexto y objetivo

Este documento define el diseno de hardware para una plataforma vLLM en entorno air-gapped, orientada a un uso diario de ingenieria con agente IA + IDE (patron similar a Cursor) para un equipo de hasta 40 desarrolladores.

Objetivos principales:

- experiencia interactiva estable para tareas de codigo,
- capacidad para picos de concurrencia en horario laboral,
- operacion segura en entorno aislado,
- coste total controlado (CAPEX + OPEX).

## 2) Perfil de uso de ingenieria (dimensionamiento humano)

Supuestos de capacidad por equipo:

- tamano de equipo: 20-40 desarrolladores,
- concurrencia real simultanea: 25-45%,
- sesiones activas pico: 5-18,
- mezcla de carga: chat tecnico, depuracion, refactor y generacion de codigo,
- modelo de referencia de calidad: 70B instruct distribuido,
- contexto habitual: 2k-8k tokens.

Implicacion de diseno:

- no dimensionar por total de usuarios, sino por concurrencia real y p95,
- reservar margen de 30-80% sobre throughput medio para picos.

## 3) SLO tecnicos objetivo

Para considerar el servicio apto para ingenieria:

- p50 tiempo a primer token: <= 1.5-2.5 s,
- p95 tiempo a primer token: <= 4-6 s,
- tasa de error de inferencia: < 1%,
- utilizacion GPU sostenida en pico: 65-85%.

## 4) Matriz de decision (capacidad y presupuesto)

Rangos orientativos 2026, sin IVA ni obra de CPD.

- **Opcion A - PoC base**
  - Infra: 1 nodo, 2x A100 40GB
  - Throughput agregado: 220-550 tok/s
  - Equipo objetivo: laboratorio / preproduccion pequena
  - CAPEX: 45k-90k EUR

- **Opcion B - Produccion inicial 20 dev**
  - Infra: 2 nodos, 4x A100 80GB por nodo
  - Throughput agregado: 700-1500 tok/s
  - Equipo objetivo: hasta 20 dev (o 30 con carga moderada)
  - CAPEX: 320k-700k EUR

- **Opcion C - Produccion recomendada 20-40 dev**
  - Infra: 2 nodos, 4x H100 80GB por nodo
  - Throughput agregado: 1400-3000 tok/s
  - Equipo objetivo: 20-40 dev con picos frecuentes
  - CAPEX: 640k-1.1M EUR

Decision rapida:

- si el objetivo es PoC: Opcion A,
- si el objetivo es servicio usable para 20 dev: Opcion B,
- si el objetivo es 40 dev con UX consistente: Opcion C.

## 5) Especificacion tecnica por nodo (referencia)

### Nodo A100 (produccion inicial)

- CPU: 2x EPYC/Xeon (>=64 cores totales),
- RAM: 1 TB ECC,
- GPU: 4x A100 80GB,
- Storage SO: 2x NVMe 1.92TB RAID1,
- Storage modelos/datos: 8x NVMe 3.84TB+,
- Red: 2x 100GbE o 1x 200GbE,
- PSU: redundante N+1/N+N.

### Nodo H100 (produccion recomendada)

- CPU: 2x EPYC/Xeon (>=96 cores totales),
- RAM: 1-2 TB ECC,
- GPU: 4x H100 80GB,
- Storage SO: 2x NVMe 1.92TB RAID1,
- Storage modelos/datos: 8x NVMe 3.84TB+,
- Red: 2x 200GbE o InfiniBand 200/400Gbps,
- PSU: redundante N+N.

## 6) Costes: CAPEX, OPEX y reserva

Distribucion orientativa de coste:

- GPUs: 55-70%,
- servidor (CPU/RAM/chasis): 20-30%,
- storage y red: 8-15%,
- soporte, garantia y puesta en marcha: 5-12%.

Recomendaciones financieras:

- contingencia de proyecto: +10-15% sobre CAPEX,
- OPEX anual esperado: 12-22% del CAPEX (energia, soporte, operacion).

## 7) Requisitos de plataforma (air-gapped)

- OS base: RHEL-compatible de ciclo largo,
- driver NVIDIA validado para CUDA objetivo,
- NVIDIA Container Toolkit operativo,
- runtime de contenedores (Podman o Docker) con GPU validada,
- BIOS/UEFI: Above 4G decoding habilitado,
- Secure Boot: firma de modulos NVIDIA o deshabilitado en laboratorio.

## 8) Flujo operativo de despliegue

1. Preparar repositorio interno de paquetes y artefactos.
2. Validar `nvidia-smi` en host.
3. Validar GPU en contenedor CUDA.
4. Cargar imagenes OCI offline.
5. Cargar modelos en almacenamiento local.
6. Arrancar vLLM con perfiles de memoria definidos.
7. Verificar API y telemetria (latencia, throughput, errores).

## 9) Plan de validacion previa a compra

Validar con datos reales de desarrollo:

- 1 semana de telemetria anonima de patrones de uso IDE,
- pruebas en 3 perfiles: normal, pico y stress,
- analisis p95 + coste por token interno,
- ajuste final de nodos/GPU antes del pedido.

Criterio de aprobacion:

- cumple SLO tecnicos definidos,
- mantiene coste por token interno en rango objetivo,
- escala a 40 desarrolladores sin rediseno mayor.
