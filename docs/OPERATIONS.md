# OPERATIONS: marco teorico de operacion para infraestructura IA

## 1) Objetivo

Definir un marco teorico de operacion para plataformas de IA en entornos empresariales y/o air-gapped, independiente de una tecnologia concreta.

## 2) Alcance

Este documento cubre principios de operacion para:

- disponibilidad del servicio,
- gestion de capacidad y rendimiento,
- seguridad operativa,
- continuidad del negocio,
- gobierno de cambios.

No describe implementaciones especificas de un motor concreto; la PoC actual es solo una referencia tecnica de bajo alcance.

## 3) Principios de operacion

- **Estandarizacion**: procesos repetibles y auditables.
- **Observabilidad**: metricas, logs y trazas suficientes para diagnostico.
- **Minimo privilegio**: acceso por rol y necesidad operativa.
- **Resiliencia**: capacidad de recuperacion ante fallos.
- **Trazabilidad**: toda decision tecnica debe poder reconstruirse.

## 4) Modelo operativo (personas y responsabilidades)

Roles minimos:

- Plataforma/SRE: infraestructura, runtime, red, disponibilidad.
- MLOps/IA: modelos, serving, calibracion y calidad tecnica.
- Seguridad: control de acceso, cumplimiento, auditoria y gestion de riesgo.
- Desarrollo/Producto: validacion funcional y feedback de negocio.

Recomendacion: formalizar un RACI para incidentes, cambios y despliegues.

## 5) Ciclo operativo de un servicio IA

1. Planificacion de capacidad y riesgos.
2. Despliegue controlado con validacion inicial.
3. Operacion continua con SLO definidos.
4. Gestion de incidencias y problemas recurrentes.
5. Mejora continua basada en telemetria real.

## 6) SLO/SLI teoricos recomendados

SLI tipicos:

- disponibilidad del endpoint,
- latencia p50/p95,
- tasa de error funcional y tecnico,
- throughput agregado en ventanas de carga,
- tiempo medio de recuperacion (MTTR).

SLO ejemplo (adaptable):

- disponibilidad >= 99.5%,
- error rate < 1%,
- p95 de respuesta dentro de objetivo de negocio.

## 7) Gestion de incidentes (teoria)

Clasificacion recomendada:

- Sev1: servicio caido o impacto mayor a negocio,
- Sev2: degradacion severa con workaround parcial,
- Sev3: degradacion moderada o impacto acotado.

Flujo minimo:

1. deteccion,
2. contencion,
3. mitigacion,
4. recuperacion,
5. postmortem con acciones preventivas.

## 8) Gestion de cambios (change management)

Todo cambio en produccion debe incluir:

- motivo tecnico y alcance,
- plan de despliegue,
- validaciones previas,
- plan de rollback,
- responsable y ventana de ejecucion.

Evitar cambios simultaneos no relacionados durante periodos criticos.

## 9) Continuidad y recuperacion

Elementos minimos:

- estrategia de backup/restore de configuraciones y artefactos,
- objetivos RTO/RPO definidos,
- pruebas periodicas de recuperacion,
- inventario de dependencias criticas.

## 10) Seguridad operativa

Controles recomendados:

- autenticacion y autorizacion por rol,
- gestion de secretos y rotacion,
- segmentacion de red,
- registro y retencion de auditoria,
- revision periodica de vulnerabilidades.

## 11) Capacidad y coste (FinOps tecnico)

Practicas clave:

- medir demanda real por tipo de carga,
- estimar coste unitario por peticion/token/usuario,
- definir umbrales de saturacion y alertas,
- revisar mensualmente eficiencia coste-rendimiento.

## 12) Evidencias y documentacion viva

Mantener actualizado:

- runbooks de operacion,
- historial de incidentes y lecciones aprendidas,
- catalogo de cambios,
- estado de cumplimiento de SLO.

Un sistema IA es operable cuando su comportamiento es predecible, medible y recuperable.
# OPERATIONS: runbook de operacion vLLM (air-gapped)

## 1) Objetivo

Definir procedimientos operativos claros para ejecutar, supervisar y recuperar el servicio vLLM en entorno air-gapped.

## 2) Alcance

Este runbook cubre:

- arranque y parada del servicio,
- verificaciones de salud,
- gestion de incidentes frecuentes,
- rollback operativo,
- rutina de operacion diaria/semanal.

## 3) Roles operativos (minimo)

- Plataforma/SRE:
  - disponibilidad del host, runtime y red interna.
- IA/MLOps:
  - modelo servido, parametros de calibracion y tuning.
- Seguridad:
  - control de accesos, auditoria y cumplimiento.
- Desarrollo:
  - validacion funcional y feedback de calidad/latencia.

## 4) Comandos base de operacion

Desde raiz del repo:

- Arranque completo (host + descarga + run):
  - `bash scripts/bootstrap_and_run.sh`
- Arranque solo modelo:
  - `bash scripts/run_model_only.sh`
- Arranque con reintento de perfiles:
  - `bash scripts/start_retry.sh`
- Limpieza controlada:
  - `bash scripts/cleanup.sh`

Checks rapidos:

- API:
  - `curl http://localhost:8000/v1/models`
- Logs:
  - `podman logs -f vllm-dune`
- GPU:
  - `bash stats/gpu_stats_extended.sh`

## 5) Criterios de salud (operativos)

Servicio saludable si:

- `GET /v1/models` responde,
- contenedor estable sin reinicios en bucle,
- no aparecen errores recurrentes `OOM`, `KV cache`, `EngineCore failed`,
- latencia y throughput dentro de objetivo interno.

## 6) Procedimiento de arranque estandar

1. Verificar host:
   - `nvidia-smi` en host OK.
2. Verificar runtime contenedor:
   - prueba GPU en contenedor CUDA (incluida en scripts).
3. Arrancar servicio:
   - `bash scripts/run_model_only.sh` (o `start_retry.sh` si entorno justo).
4. Validar endpoint:
   - `curl http://localhost:8000/v1/models`.
5. Ejecutar prompt de humo:
   - `python3 src/test_agent.py "hola, responde en una frase"`.

## 7) Incidentes frecuentes y respuesta

### A) API no responde

Sintoma:

- `curl .../v1/models` falla.

Acciones:

1. revisar logs del contenedor,
2. confirmar puertos y proceso activo,
3. reiniciar con `scripts/cleanup.sh` + `scripts/run_model_only.sh`.

### B) OOM / KV cache insuficiente

Sintoma:

- `torch.OutOfMemoryError`
- `No available memory for the cache blocks`

Acciones:

1. bajar `MAX_MODEL_LEN`,
2. bajar `max-num-batched-tokens` y `max-num-seqs`,
3. subir `CPU_OFFLOAD_GB`,
4. usar perfil seguro (`--enforce-eager`).

### C) GPU no visible en contenedor

Sintoma:

- fallo en `nvidia-smi` dentro de contenedor.

Acciones:

1. re-ejecutar `scripts/install_offline.sh`,
2. validar toolkit/runtime NVIDIA,
3. repetir prueba CUDA base antes de arrancar vLLM.

### D) Degradacion progresiva de latencia

Sintoma:

- p95 sube sostenidamente bajo carga similar.

Acciones:

1. revisar saturacion GPU/RAM,
2. reducir concurrencia interna (`max-num-seqs`),
3. reinicio controlado fuera de ventana pico,
4. registrar parametros y abrir ajuste de calibracion.

## 8) Rollback operativo

Objetivo: volver rapido a estado estable conocido.

1. mantener al menos un perfil "estable conocido" documentado,
2. ante degradacion, volver al perfil estable,
3. limpiar estado:
   - `bash scripts/cleanup.sh`,
4. re-arrancar con el perfil estable.

Regla: no introducir multiples cambios de parametros a la vez en incidentes.

## 9) Rutina diaria y semanal

### Diaria

- revisar salud endpoint,
- revisar errores criticos en logs,
- revisar uso GPU y tendencias de latencia.

### Semanal

- revisar capacidad vs demanda (concurrencia real),
- validar que SLO internos siguen cumpliendose,
- consolidar ajustes de calibracion en documentacion.

## 10) Evidencias minimas de operacion

Guardar por incidencia/cambio:

- timestamp,
- parametros de arranque usados,
- extracto de logs,
- snapshot de GPU/RAM,
- resultado de `GET /v1/models` y prompt de humo,
- accion correctiva aplicada.

## 11) Criterio de salida a produccion interna

Se considera listo para operacion estable cuando:

- cumple SLO internos en carga normal y pico controlado,
- no presenta fallos criticos recurrentes en 7 dias,
- existe rollback probado y documentado,
- roles y guardias operativas estan definidos.
