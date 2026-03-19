# Agentes sobre vLLM (OpenAI-compatible, Air-Gapped)

## 1) Alcance

Esta nota tecnica describe como integrar agentes de IA y asistentes de codigo contra un endpoint vLLM OpenAI-compatible en entornos air-gapped.

## 2) Compatibilidad base

vLLM expone endpoints compatibles con OpenAI (`/v1/chat/completions`, `/v1/models`, etc.).  
Una herramienta de agente puede funcionar sobre vLLM si soporta:

- `base_url` configurable hacia endpoint interno,
- nombre de modelo configurable (debe coincidir con `served_model_name`),
- autenticacion por API key (opcional, segun politica interna).

## 3) Continue (extension de VSCode)

### Viabilidad tecnica

Si, **es viable** usar Continue con vLLM en air-gapped, siempre que:

1. VSCode y Continue se distribuyan por canal interno/offline.
2. Continue apunte al endpoint interno OpenAI-compatible de vLLM.
3. El modelo configurado en Continue coincida con el nombre servido por vLLM.
4. La conectividad entre workstation y servidor de inferencia este permitida en el segmento air-gapped.

### Limitaciones a considerar

- La compatibilidad exacta depende de la version de Continue y sus rutas OpenAI usadas.
- Algunas capacidades "agenticas" avanzadas pueden requerir servicios extra (tool calling, embeddings, rerank, indices o servicios auxiliares) no incluidos en un despliegue minimo.
- En air-gapped, updates de extension y modelos son manuales y deben pasar control de cambios.

## 4) Recomendacion de despliegue

1. Validar primero modo chat simple:
   - `GET /v1/models`
   - `POST /v1/chat/completions`
2. Activar funciones de edicion/agenticas de forma incremental.
3. Mantener fallback operativo a "chat-only" si falla una capacidad avanzada.
4. Registrar telemetria local de latencia/errores para tuning.

## 5) Checklist minimo de integracion

- Endpoint vLLM accesible desde la red de desarrollo.
- `served_model_name` estable y documentado.
- Politica de API key definida (on/off, rotacion, auditoria).
- Validacion funcional desde cliente CLI/Python antes de VSCode.
- Procedimiento de rollback de extension/agente documentado.
