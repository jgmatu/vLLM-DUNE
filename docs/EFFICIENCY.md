# Efficiency note — IA, codificacion y diseno (nota tecnica)

Nota tecnica para la PoC vLLM-DUNE: **donde la IA suele ahorrar horas** (generacion y mecanizado de codigo), **donde no sustituye al ingeniero** (diseno y arquitectura), y **riesgo tecnico** si falta criterio de dominio.

## 1) Ahorro orientativo en horas de generacion de codigo

La IA asistente actua con mas impacto en tareas donde el trabajo es **producir texto ejecutable o repetible**: plantillas, scripts, Dockerfiles, clientes API minimos, refactors mecanicos, pruebas esqueleto, documentacion de primera pasada. En esas tareas es razonable esperar **ordenes de magnitud del 25-50% menos tiempo de tecleo y busqueda** frente a hacerlo solo a mano (la varianza es alta segun modelo, prompt y familiaridad con el stack).

**Queda fuera de ese “ahorro de codificacion”** (o se diluye mucho) todo lo que exige **entender limites fisicos y de producto**: memoria GPU, concurrencia real, contratos de seguridad, SLAs, compatibilidad de versiones en produccion. Ahi el tiempo se va en **medir, depurar y decidir**, no en generar lineas.

| Tipo de trabajo | Suele ahorrar horas con IA | Comentario |
|-----------------|----------------------------|------------|
| Boilerplate (estructura de proyecto, scripts, YAML/Docker) | Si, en grado alto | Revisar linea a linea; riesgo de flags o APIs desactualizadas. |
| Implementacion repetitiva (wrappers, parsing, logging basico) | Si | El patron es claro; la IA acelera el mecanizado. |
| Calibracion en hardware real (OOM, latencia, batch) | Parcial | Puede sugerir hipotesis; **el bucle medir-en-GPU** sigue siendo humano. |
| Redaccion tecnica (borradores, listas, checklists) | Si, en borrador | El **contenido factual** debe validarlo quien opera el sistema. |

Los porcentajes anteriores son **orientativos**, no mediciones de laboratorio; sirven para fijar expectativas con sponsors, no como KPI contractual.

## 2) Diseno y arquitectura: no es el foco de la IA

**Diseno** (que componentes existen, como fallan, que se prioriza cuando hay tension VRAM/latencia/coste) y **arquitectura** (fronteras entre servicios, modelo de amenazas, observabilidad, despliegue) son juicios de ingenieria. La IA puede **proponer** diagramas o textos, pero **no asume responsabilidad** sobre:

- Trade-offs correctos para tu entorno (red, GPU, politica de datos).
- Evolucion del sistema cuando cambia el modelo o la carga.
- Coherencia entre seguridad, operaciones y negocio.

En la practica: **la IA acelera la codificacion; no reemplaza el diseno**. Confiar en “lo que salio del modelo” como diseno final es una fuente habitual de **deuda tecnica y retrabajo**.

## 3) Riesgo tecnico y necesidad de ingenieria con conocimiento de la materia

Sin un ingeniero (o perfil equivalente) que **domine el dominio** —en esta PoC: inferencia en GPU, vLLM/containers, redes y buenas practicas de seguridad minima— aparecen riesgos como:

- **Configuraciones plausibles pero incorrectas** (parametros que compilan o arrancan en un entorno y fallan en otro).
- **Fallo de diseno**: por ejemplo asumir capacidad o latencia que el hardware no da; o un modelo de despliegue que no escala ni se opera.
- **Alucinaciones tecnicas**: APIs, flags o versiones inventadas o obsoletas; solo la revision humana con conocimiento de la materia lo detecta de forma fiable.

**Mitigacion minima**: quien define arquitectura y criterios de aceptacion debe tener **criterio tecnico en la materia**; la IA es herramienta de apoyo en la **fase de implementacion y documentacion**, no sustituto de esa figura.

## 4) Sintesis: foco de la IA vs rol del ingeniero

| Aspecto | IA (asistente de codigo / texto) | Ingeniero con conocimiento de la materia |
|---------|----------------------------------|------------------------------------------|
| **Objetivo principal** | Reducir horas de **generacion y mecanizado** de codigo y borradores. | **Diseno, arquitectura, validacion** y decisiones bajo incertidumbre. |
| **Salida confiable sin revision** | No; siempre revisar lo critico. | Es la referencia para lo que es critico. |
| **Riesgo si falta** | Tiempo perdido en correcciones. | **Fallo de diseno**, incidentes, retrabajo mayor. |

## 5) Limitaciones

- Los rangos de ahorro de tiempo son **cualitativos** y dependen del equipo, del modelo de IA y del acceso a hardware.
- La documentacion no sustituye pruebas formales ni auditoria.
- Este documento es **anexo a la PoC**, no especificacion de producto.

## 6) Related

- Prueba funcional de generacion de codigo: `docs/TEST.md`.
