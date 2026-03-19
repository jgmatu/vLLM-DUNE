# TEST: vLLM agent outputs (src/test_agent.py)

## Nota tecnica: latencia (tiempo de respuesta)

El tiempo de respuesta observado para vLLM puede ser alto debido a limitaciones de la infraestructura:

- GPU con VRAM limitada (p.ej. 12GB) que obliga a usar perfiles conservadores (`max_model_len`, `max-num-batched-tokens`, `--cpu-offload-gb`) para evitar OOM y fallos en KV cache.
- Operacion con offload de KV/pesos hacia CPU (cuando aplica), lo que incrementa la latencia y reduce el throughput.
- Concurrencia/batch reducidos durante el bootstrap para mejorar estabilidad (`--enforce-eager`, limites de `max-num-seqs`), afectando el rendimiento.
- Inicializacion y/o profiling interno del engine (cambios de cache/compilacion) que puede incrementar el tiempo de primer token.

## Test 1: bucle en funcion con iteraciones

Command:
`python3 src/test_agent.py "Genial ahora pon el bucle en una funcion y pasale por argumento el numero de iteraciones"`

Prompt:
`Genial ahora pon el bucle en una funcion y pasale por argumento el numero de iteraciones`

Model:
`Qwen2.5-7B-Instruct`

Response:

Claro, aquí tienes un ejemplo de cómo puedes crear una función que realice un bucle y acepte el número de iteraciones como argumento:

```python
def bucle_iterativo(numeros_de_iteraciones):
    for i in range(numeros_de_iteraciones):
        print(f"Iteración {i+1}")

# Ejemplo de uso:
bucle_iterativo(5)
```

En este ejemplo, la función `bucle_iterativo` toma un argumento `numeros_de_iteraciones`, que indica cuántas veces se debe ejecutar el bucle. El bucle `for`

## Test 2: pasar a C++

Command:
`python3 src/test_agent.py "Pasalo a C++"`

Prompt:
`Pasalo a C++`

Model:
`Qwen2.5-7B-Instruct`

Response:

Para poder ayudarte, necesito saber qué código o texto específico deseas pasar a C++. Por favor, proporciona el código o texto original que quieres traducir o adaptar a C++.

## Test 3: bucle en C++ con argumento de iteraciones (sin contexto)

Command:
`python3 src/test_agent.py "No tienes contexto de la conversacion... Crea un bucle en C++ en una funcion que se le pase por argumento el numero de iteraciones."`

Prompt:
`No tienes contexto de la conversacion... Crea un bucle en C++ en una funcion que se le pase por argumento el numero de iteraciones.`

Model:
`Qwen2.5-7B-Instruct`

Response:

Claro, aquí tienes un ejemplo de una función en C++ que crea un bucle que se ejecuta el número de veces especificado por el argumento:

```cpp
#include <iostream>

void bucle(int numIteraciones) {
    for (int i = 0; i < numIteraciones; ++i) {
        std::cout << "Iteración número: " << i + 1 << std::endl;
    }
}

int main() {
    int n;
    std::cout << "Ingrese el número de iteraciones: ";
    std::cin >> n;
    
    bucle(n);
```

# TEST: vLLM agent outputs (src/test_agent.py)

## Test 1: bucle en funcion con iteraciones

Command:
`python3 src/test_agent.py "Genial ahora pon el bucle en una funcion y pasale por argumento el numero de iteraciones"`

Prompt:
`Genial ahora pon el bucle en una funcion y pasale por argumento el numero de iteraciones`

Model:
`Qwen2.5-7B-Instruct`

Response:
```text
Claro, aquí tienes un ejemplo de cómo puedes crear una función que realice un bucle y acep
ta el número de iteraciones como argumento:

```python
def bucle_iterativo(numeros_de_iteraciones):
    for i in range(numeros_de_iteraciones):
        print(f"Iteración {i+1}")

# Ejemplo de uso:
bucle_iterativo(5)
```

En este ejemplo, la función `bucle_iterativo` toma un argumento `numeros_de_iteraciones`, que indica cuántas veces se debe ejecutar el bucle. El bucle `for`
```

## Test 2: traduccion a C++

Command:
`python3 src/test_agent.py "Pasalo a C++"`

Prompt:
`Pasalo a C++`

Model:
`Qwen2.5-7B-Instruct`

Response:
```text
Para poder ayudarte, necesito saber qué código o texto específico deseas pasar a C++. Por favor, proporciona el código o texto original que quieres traducir o adaptar a C++.
```

## Test 3: bucle en C++ con argumento de iteraciones (sin contexto)

Command:
`python3 src/test_agent.py "No tienes contexto de la conversacion... Crea un bucle en C++ en una funcion que se le pase por argumento el numero de iteraciones."`

Prompt:
`No tienes contexto de la conversacion... Crea un bucle en C++ en una funcion que se le pase por argumento el numero de iteraciones.`

Model:
`Qwen2.5-7B-Instruct`

Response:
```text
Claro, aquí tienes un ejemplo de una función en C++ que crea un bucle que se ejecuta el número de veces especificado por el argumento:

```cpp
#include <iostream>

void bucle(int numIteraciones) {
    for (int i = 0; i < numIteraciones; ++i) {
        std::cout << "Iteración número: " << i + 1 << std::endl;
    }
}

int main() {
    int n;
    std::cout << "Ingrese el número de iteraciones: ";
    std::cin >> n;
    
    bucle(n);
```

