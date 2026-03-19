# CLOUD: modelos IA y uso diario con Cursor

## 1) Objetivo

Definir una referencia practica para:

- que modelos de IA se usan habitualmente en entornos cloud,
- cual es la carga normal de un desarrollador usando Cursor,
- y como interpretar el "modelo por defecto" en Cursor.

## 2) Modelos de IA habituales en cloud

En cloud, los equipos suelen combinar 3 capas de modelos:

- **Modelos economicos (small/mini)**
  - Uso: autocompletado rapido, tareas simples, clasificacion, transformaciones cortas.
  - Ventaja: coste bajo por token y latencia reducida.

- **Modelos de equilibrio (medium)**
  - Uso: desarrollo diario general, refactor moderado, explicaciones tecnicas.
  - Ventaja: mejor relacion coste/calidad para uso continuo.

- **Modelos de alta capacidad (large/frontier)**
  - Uso: debugging complejo, arquitectura, cambios amplios, razonamiento largo.
  - Ventaja: mayor calidad, pero con mayor coste por token.

Patron recomendado: routing por tarea (small para volumen, large para casos complejos).

## 3) Carga normal de un desarrollador con Cursor (cloud)

Rango orientativo por persona/dia laboral:

- uso bajo: **80k-250k tokens/dia**
- uso medio: **250k-900k tokens/dia**
- uso alto: **0.9M-2.5M tokens/dia**

Distribucion tipica:

- tokens de entrada (prompt + contexto): 55-75%
- tokens de salida (respuesta): 25-45%

Factores que mas aumentan consumo:

- contexto grande (muchos archivos/diffs/logs),
- sesiones multi-turn largas de depuracion,
- respuestas extensas con codigo completo.

## 4) Modelo LLM por defecto en Cursor

Cursor no tiene un unico "modelo universal fijo" para todos los entornos.
En la practica, el modelo por defecto depende de:

- plan/licencia activa,
- configuracion del workspace o del usuario,
- selector de modelo en la sesion,
- politicas de proveedor o de organizacion.

Recomendacion operativa:

- documentar internamente el modelo por defecto efectivo en tu equipo,
- fijar un modelo base para uso diario y otro de alta capacidad para casos complejos,
- revisar cambios de configuracion tras actualizaciones del IDE/servicio.

## 5) Coste cloud por tokens (formula rapida)

`coste_total = (tokens_in / 1_000_000) * precio_in + (tokens_out / 1_000_000) * precio_out`

Donde `precio_in` y `precio_out` son precios por millon de tokens segun proveedor y modelo.

## 6) Estimacion mensual de equipo

`tokens_mes ~= tokens_dia_por_dev * numero_devs * dias_laborables`

Ejemplo (uso medio):

- 20 devs,
- 22 dias laborables,
- 500k tokens/dia por dev

`tokens_mes ~= 500_000 * 20 * 22 = 220_000_000 tokens/mes`

Este volumen sirve como base para negociar presupuesto y definir alertas de coste.
