# Efficiency note (PoC vs traditional development)

Nota complementaria a la PoC vLLM-DUNE: indicadores de repositorio, **comparativa orientativa** codificacion tradicional vs desarrollo asistido por IA (rangos de esfuerzo y calendario), y lectura frente al historial del proyecto.

## 1) Repository indicators (update periodically)

Valores de referencia; no son KPI contractuales. Para refrescarlos:

```bash
git rev-list --count HEAD
ls docs/*.md | wc -l
```

| Indicator | Orientative value (snapshot) |
|-----------|------------------------------|
| Total commits (`git rev-list --count HEAD`) | 40 |
| Technical docs in `docs/` (`*.md`) | 10 (incluye este fichero) |
| Git history window (first → last commit date) | orden de dias en el calendario del proyecto |

## 2) Documentation surface covered in `docs/`

`AGENTES`, `CALIBRATION`, `CLOUD`, `EFFICIENCY`, `EXECUTIVE_SUMMARY`, `HARDWARE`, `OPERATIONS`, `RHEL10`, `SECURITY`, `TEST`.

## 3) Comparativa aproximada: codificacion tradicional vs uso de IA

**Alcance de comparacion** (entregable equivalente a esta PoC): contenedor vLLM operativo, scripts cliente, calibracion GPU/VRAM documentada, y paquete de documentos tecnicos en `docs/` (hardware, cloud, operaciones, seguridad, resumen ejecutivo, prueba funcional). **Un desarrollador** con stack Linux/containers conocido pero sin experiencia previa profunda en vLLM.

**Metodologia (honesta)**: no hay medición A/B en este repositorio. Los rangos son **estimaciones de orden de magnitud** coherentes con (a) complejidad observada en la PoC, (b) fricción inevitable (OOM, flags, drivers, red), y (c) literatura gris / encuestas a desarrolladores sobre ahorro de tiempo en tareas de codificacion y documentacion con asistentes (ordenes del 20-55% en subconjuntos de tareas, con alta varianza). Sirven para **planificar expectativas**, no para contratos ni SLAs.

### 3.1 Esfuerzo por fase (horas de trabajo efectivo, aprox.)

| Fase | Codificacion tradicional (rango) | Con IA asistida (rango) | Que cambia con IA |
|------|----------------------------------|-------------------------|-------------------|
| Descubrimiento: docs upstream vLLM, Docker, flags criticos | 12-28 h | 6-14 h | Menos búsqueda manual; mas riesgo de **configuraciones plausibles pero incorrectas** → revision obligatoria. |
| Implementacion: Dockerfile, compose, scripts, cliente API | 10-24 h | 5-14 h | Boilerplate y plantillas mas rapidos; la integracion real (puertos, modelos, env) sigue siendo humana. |
| Calibracion / estabilidad (OOM, `max_model_len`, offload, eager) | 16-40 h | 10-26 h | Sugerencias aceleran hipotesis; **el bucle medir-en-GPU** no desaparece. |
| Documentacion tecnica (~10 ficheros, varios dominios) | 28-72 h | 10-28 h | Redaccion y estructura en paralelo; el **contenido debe validarse** contra el sistema real. |
| Revision, seguridad basica, coherencia entre docs | 8-20 h | 10-24 h | Con IA suele subir el coste de **verificacion** (versiones, flags, no inventar parametros). |
| **Total orientativo** | **74-184 h** | **41-106 h** | Ahorro bruto tipico **~35-45%** del tiempo de enfoque en este tipo de PoC (rango amplio). |

Equivalencia en **calendario** (mismo perfil, interrupciones normales): tradicional **~3-6 semanas**; con IA **~1,5-3 semanas** para un resultado comparable en alcance, siempre que exista hardware disponible sin colas largas.

### 3.2 Comparativa por dimensiones (cualitativa pero operativa)

| Dimension | Tradicional | Con IA |
|-----------|-------------|--------|
| **Velocidad inicial** | Mas lenta (mas lectura lineal). | Mas rapida (borradores, esqueletos). |
| **Calidad del primer borrador** | Suele ser consistente pero incompleto. | Puede ser **muy util o engañoso**; depende del prompt y del modelo. |
| **Riesgo tecnico** | Errores por desconocimiento del dominio. | Errores por **alucinacion** o APIs desactualizadas; mitigacion: pruebas y difs pequeños. |
| **Coste de revision** | Concentrado en pares/revision funcional. | Concentrado en **fact-check** (documentacion vs comportamiento real). |
| **Transferencia al equipo** | Documentacion a menudo llega tarde. | Documentacion puede generarse **en paralelo** al codigo (como en este repo). |
| **Curva de aprendizaje vLLM/GPU** | Empinada, mucha lectura. | Empinada en **validacion**; la teoria llega filtrada por el asistente. |

### 3.3 Lectura frente a los indicadores del repositorio

- Un volumen similar de **commits** y de **superficie documental** en flujo tradicional suele estirar el **calendario** y los **handoffs** entre roles (infra, seguridad, operacion).
- Con IA, la **densidad de commits** refleja ciclos cortos de ajuste (scripts, contenedores, calibracion) y la documentacion **acompaña** el codigo, lo que reduce silos de conocimiento.
- El valor agregado no es solo LOC: es alinear PoC tecnica con hardware, cloud, operacion, seguridad y resumen ejecutivo **en el mismo ciclo de vida**; la IA acelera sobre todo las tareas **texto + estructura + variantes**, no la disponibilidad de GPU ni la latencia real del servicio.

## 4) Limitations

- Las cifras de la seccion 3 son **aproximadas**; dependen de experiencia previa, calidad del modelo de IA, y acceso a GPU.
- El numero de commits depende del estilo de trabajo (commits pequenos vs grandes).
- La documentacion no sustituye pruebas formales ni auditoria.
- Este documento es un **anexo cualitativo** a la PoC.

## 5) Related

- Prueba funcional de generacion de codigo: `docs/TEST.md`.
