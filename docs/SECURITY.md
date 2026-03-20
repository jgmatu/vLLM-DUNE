# SECURITY: marco de seguridad para infraestructura IA (air-gapped)

## 1) Objetivo

Definir controles de seguridad tecnicos y operativos para una plataforma IA en entorno aislado, minimizando riesgo de fuga de informacion, acceso no autorizado e indisponibilidad.

## 2) Principios de seguridad

- **Minimo privilegio**: cada rol accede solo a lo necesario.
- **Defensa en profundidad**: controles en host, red, runtime y aplicacion.
- **Trazabilidad**: toda accion relevante debe ser auditable.
- **Zero trust interno (adaptado)**: no asumir confianza por pertenecer a la red.
- **Seguridad por defecto**: configuraciones seguras desde el inicio.

## 3) Modelo de amenazas (alto nivel)

Riesgos principales:

- acceso indebido a modelos, prompts o artefactos,
- exfiltracion de datos por canales no controlados,
- manipulacion de configuracion/imagenes/modelos,
- escalada de privilegios en host o contenedor,
- indisponibilidad por error operacional o ataque interno.

## 4) Identidad, acceso y roles (IAM)

Controles recomendados:

- autenticacion centralizada para operadores y usuarios tecnicos,
- RBAC por funcion (plataforma, IA/MLOps, seguridad, desarrollo),
- cuentas nominales (evitar cuentas compartidas),
- MFA para accesos administrativos,
- caducidad y revision periodica de permisos.

## 5) Gestion de secretos y credenciales

- no almacenar secretos en repositorio ni imagenes,
- usar vault interno o mecanismo equivalente,
- rotacion periodica de API keys/tokens,
- revocacion inmediata ante baja de usuario o incidente,
- auditoria de acceso a secretos.

## 6) Seguridad de red (air-gapped)

- segmentacion por zonas: gestion, inferencia, desarrollo, almacenamiento,
- listas de control (allow-list) por origen/destino y puerto,
- bloqueo explicito de salida a internet salvo excepciones autorizadas,
- bastion o salto controlado para administracion,
- registro de flujos de red criticos.

## 7) Hardening de host y runtime

Host:

- baseline CIS/benchmark interno para RHEL-compatible,
- parches en ventana controlada,
- kernel y driver NVIDIA en versiones certificadas,
- servicios no usados deshabilitados.

Contenedores:

- imagenes firmadas y validadas antes de uso,
- ejecucion con privilegios minimos posibles,
- filesystem de solo lectura cuando aplique,
- escaneo de vulnerabilidades de imagen en pipeline interno.

## 8) Seguridad de artefactos IA (modelos, prompts, datasets)

- inventario y versionado de modelos autorizados,
- control de integridad (hash/checksum/firma),
- procedencia validada de artefactos,
- clasificacion de sensibilidad para prompts/datasets,
- retencion y borrado seguro segun politica.

## 9) Logging, auditoria y monitorizacion de seguridad

Registrar como minimo:

- autenticaciones y cambios de permisos,
- despliegues/cambios de configuracion,
- accesos a modelos y endpoints sensibles,
- errores criticos y reinicios de servicio,
- eventos de red relevantes.

Buenas practicas:

- centralizar logs en infraestructura interna,
- definir retencion y cadena de custodia,
- alertas para anomalias (picos de error, accesos inusuales, cambios fuera de ventana).

## 10) Seguridad de agentes e IDE

Para integracion Agente IA + IDE:

- controlar que contexto puede salir del IDE al endpoint,
- limitar acceso del agente a rutas/herramientas segun politica,
- registrar operaciones de alto impacto (edicion masiva, comandos shell),
- mantener fallback a modo consulta cuando falle una politica de seguridad.

## 11) Respuesta a incidentes de seguridad

Flujo minimo:

1. deteccion y clasificacion,
2. contencion (aislar cuenta/host/servicio),
3. erradicacion de causa,
4. recuperacion controlada,
5. postmortem con acciones preventivas.

Preparacion requerida:

- contactos y guardias definidos,
- playbooks por tipo de incidente,
- simulacros periodicos.

## 12) Cumplimiento y gobierno

- politicas escritas de acceso, cambios y retencion,
- evidencia auditable de controles aplicados,
- revisiones periodicas de cumplimiento,
- excepciones formales con fecha de expiracion y responsable.

## 13) Checklist minimo de seguridad (Go/No-Go)

Antes de pasar a operacion estable:

- RBAC activo y revisado,
- secretos fuera de codigo y con rotacion definida,
- segmentacion de red aplicada y probada,
- hardening base de host/imagenes completado,
- logging/auditoria centralizada operativa,
- plan de respuesta a incidentes aprobado.
