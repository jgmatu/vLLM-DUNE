# Executive Summary: PoC infraestructura IA air-gapped

## 1) Objetivo de la iniciativa

Validar una plataforma de IA en entorno air-gapped para uso de ingenieria (agente IA + IDE), con control de seguridad, operacion y coste.

La PoC busca responder tres preguntas clave:

- viabilidad tecnica (latencia, estabilidad, throughput),
- viabilidad operativa (runbooks, seguridad, soporte),
- viabilidad economica (CAPEX/OPEX y coste por uso).

## 2) Contexto de negocio

- Equipo objetivo: hasta 40 desarrolladores.
- Necesidad: asistencia de codigo y productividad en entorno aislado.
- Restriccion: cumplimiento y gobierno de infraestructura de alto coste.

## 3) Opciones de infraestructura evaluadas

- **Opcion A (PoC base)**:
  - 1 nodo, 2x A100 40GB
  - 220-550 tok/s
  - 45k-90k EUR CAPEX

- **Opcion B (produccion inicial)**:
  - 2 nodos, 4x A100 80GB por nodo
  - 700-1500 tok/s
  - 320k-700k EUR CAPEX

- **Opcion C (produccion recomendada 20-40 dev)**:
  - 2 nodos, 4x H100 80GB por nodo
  - 1400-3000 tok/s
  - 640k-1.1M EUR CAPEX

## 4) Recomendacion ejecutiva

Para una PoC con valor real y escalabilidad:

- iniciar con **Opcion B** como punto de equilibrio tecnico/economico,
- reservar **+10-15%** de contingencia CAPEX,
- ejecutar validacion operativa de 4-6 semanas con criterios SLO definidos.

Motivo:

- Opcion A valida laboratorio, pero se queda corta para uso sostenido de equipo.
- Opcion C ofrece maxima experiencia, pero eleva inversion inicial.

## 5) Riesgos principales y mitigacion

- Riesgo de infrautilizacion:
  - Mitigacion: adopcion gradual por equipos y metricas de uso reales.
- Riesgo operativo:
  - Mitigacion: runbooks, roles claros, rollback probado.
- Riesgo de seguridad/compliance:
  - Mitigacion: segmentacion, RBAC, auditoria y gestion de secretos.
- Riesgo de rendimiento:
  - Mitigacion: calibracion iterativa 30B-70B y control de p95.

## 6) Criterios de exito de PoC (Go/No-Go)

La PoC se aprueba para siguiente fase si:

- cumple SLO tecnicos internos (latencia p95, tasa de error),
- mantiene operacion estable durante ventana de prueba,
- muestra mejora medible de productividad en desarrollo,
- mantiene coste unitario dentro del umbral definido.

## 7) Plan de ejecucion resumido

1. Preparacion (semana 1): infraestructura base, seguridad y operacion.
2. Calibracion (semanas 2-3): ajuste de parametros y carga 30B-70B.
3. Piloto controlado (semanas 4-5): uso real con grupo de desarrollo.
4. Decision (semana 6): informe final tecnico-economico y recomendacion.

## 8) Decision solicitada

Autorizar presupuesto y recursos para ejecutar PoC controlada con enfoque de:

- gobernanza operativa,
- seguridad desde el diseno,
- medicion objetiva de valor tecnico y economico.
