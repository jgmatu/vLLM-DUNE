# Agentes sobre vLLM (OpenAI-compatible, Air-Gapped)

## 1) Alcance

Esta nota tecnica describe como integrar agentes de IA y asistentes de codigo contra un endpoint vLLM OpenAI-compatible en entornos air-gapped.

## 2) Proposito real de un agente en ingenieria

Un agente no sustituye al desarrollador; su objetivo real es acelerar el ciclo de trabajo tecnico:

- comprender contexto de codigo y documentacion del proyecto,
- proponer cambios y automatizar tareas repetitivas,
- ayudar en depuracion y validacion rapida,
- reducir tiempo entre idea, implementacion y prueba.

En la practica, el agente funciona como una capa de orquestacion sobre el modelo:

- recibe contexto (archivos, diffs, errores, prompts),
- decide acciones (consultar, editar, ejecutar),
- devuelve resultados trazables para revision humana.

## 3) Compatibilidad base (API OpenAI-compatible)

vLLM expone endpoints compatibles con OpenAI (`/v1/chat/completions`, `/v1/models`, etc.).
Una herramienta de agente puede funcionar sobre vLLM si soporta:

- `base_url` configurable hacia endpoint interno,
- nombre de modelo configurable (debe coincidir con `served_model_name`),
- autenticacion por API key (opcional, segun politica interna).

Flujo minimo recomendado de integracion:

1. `GET /v1/models` para validar descubrimiento del modelo.
2. `POST /v1/chat/completions` para validar respuesta funcional.
3. Ajuste de `max_tokens` y contexto segun limites de `max_model_len`.

## 4) Integracion en IDE (contexto de proyecto)

Para que el agente sea util en un IDE, debe poder trabajar con contexto local de proyecto:

- archivos abiertos y carpetas del repo,
- cambios no comiteados (diff),
- logs de build/test/lint,
- historial de iteraciones en la sesion.

Buenas practicas:

- limitar el contexto a lo relevante (evita ruido y consumo excesivo),
- versionar prompts/sistemas de forma controlada,
- registrar comandos y resultados para auditoria tecnica.

## 5) Continue en VSCode (propuesta Agente IA + IDE)

### Viabilidad tecnica

Si, **es viable** usar Continue con vLLM en air-gapped, siempre que:

1. VSCode y Continue se distribuyan por canal interno/offline.
2. Continue apunte al endpoint interno OpenAI-compatible de vLLM.
3. El modelo configurado en Continue coincida con el nombre servido por vLLM.
4. La conectividad entre workstation y servidor de inferencia este permitida en el segmento air-gapped.

Propuesta de arquitectura en VSCode:

- Continue como cliente de agente dentro del IDE.
- vLLM como motor LLM interno via API OpenAI-compatible.
- Repositorio local como fuente de contexto (codigo, docs, tests).
- Politica de red y claves gestionada por el equipo de plataforma.

### Limitaciones a considerar

- La compatibilidad exacta depende de la version de Continue y sus rutas OpenAI usadas.
- Algunas capacidades "agenticas" avanzadas pueden requerir servicios extra (tool calling, embeddings, rerank, indices o servicios auxiliares) no incluidos en un despliegue minimo.
- En air-gapped, updates de extension y modelos son manuales y deben pasar control de cambios.

## 6) Recomendacion de despliegue

1. Validar primero modo chat simple:
   - `GET /v1/models`
   - `POST /v1/chat/completions`
2. Activar funciones de edicion/agenticas de forma incremental.
3. Mantener fallback operativo a "chat-only" si falla una capacidad avanzada.
4. Registrar telemetria local de latencia/errores para tuning.

## 7) Checklist minimo de integracion

- Endpoint vLLM accesible desde la red de desarrollo.
- `served_model_name` estable y documentado.
- Politica de API key definida (on/off, rotacion, auditoria).
- Validacion funcional desde cliente CLI/Python antes de VSCode.
- Procedimiento de rollback de extension/agente documentado.

## 8) Criterio de exito

La integracion se considera exitosa cuando:

- los desarrolladores pueden consultar y editar codigo con contexto de proyecto,
- el agente responde de forma estable sobre API OpenAI-compatible interna,
- el flujo IDE + agente reduce tiempos de analisis y entrega sin comprometer control tecnico.

