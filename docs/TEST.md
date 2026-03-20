# TEST: PoC vLLM (generacion de codigo)

## Nota tecnica: latencia (tiempo de respuesta)

El tiempo de respuesta observado para vLLM puede ser alto debido a limitaciones de la infraestructura:

- GPU con VRAM limitada (p.ej. 12GB) que obliga a usar perfiles conservadores (`max_model_len`, `max-num-batched-tokens`, `--cpu-offload-gb`) para evitar OOM y fallos en KV cache.
- Operacion con offload de KV/pesos hacia CPU (cuando aplica), lo que incrementa la latencia y reduce el throughput.
- Concurrencia/batch reducidos durante el bootstrap para mejorar estabilidad (`--enforce-eager`, limites de `max-num-seqs`), afectando el rendimiento.
- Inicializacion y/o profiling interno del engine (cambios de cache/compilacion) que puede incrementar el tiempo de primer token.

## Objetivo de la PoC

- Validar que vLLM responde via API OpenAI-compatible.
- Demostrar una tarea util: generacion de codigo (ejemplo C++).

## Precondiciones

- Contenedor vLLM arrancado.
- Endpoint accesible: `http://localhost:8000/v1/models`.
- Script cliente disponible: `src/test_agent.py`.

## Ejecucion de prueba (codigo)

Comando usado:

`MAX_TOKENS=96 python3 src/test_agent.py "Crea un bucle en C++"`

Modelo servido:

`Qwen2.5-7B-Instruct`

Salida esperada (ejemplo valido):

```cpp
#include <iostream>

int main() {
    for (int i = 0; i < 5; ++i) {
        std::cout << "Iteracion numero: " << i << std::endl;
    }
    return 0;
}
```

## Criterios de aceptacion de la PoC

- El endpoint `/v1/models` responde correctamente.
- El modelo genera una respuesta coherente de codigo fuente.
- El flujo prompt -> inferencia -> salida funciona sin errores de API.

Nota sobre ahorro de horas en codificacion con IA, riesgo tecnico y diseno/arquitectura: ver `docs/EFFICIENCY.md`.
