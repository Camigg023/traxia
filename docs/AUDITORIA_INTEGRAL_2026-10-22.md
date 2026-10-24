# Auditoría integral de TRAXIA — 2026-10-22

## Alcance y método

Se revisaron los archivos de aplicación, configuración y documentación disponibles en el repositorio sin ejecutar la aplicación ni conectarse a una base de datos real. El [Documento Maestro vigente](TRAXIA_DOCUMENTO_MAESTRO.md) y el [histórico](historico/TRAXIA_DOCUMENTO_MAESTRO_ANTERIOR.md) se conservaron sin modificaciones. La aclaración aprobada de plataforma web sigue prevaleciendo sobre las menciones móviles del Maestro vigente.

El inventario incluyó:

- Raíz: `README.md`, `.gitignore`, `.env.example`, `.env.local` (solo nombres de claves y comprobación de marcadores, sin imprimir valores), `LICENSE` y estado Git.
- Fase 1: `fase1/00-aclaracion-y-control.md`, `01-requisitos.md`, `02-alcance-mvp.md`, `03-historias-y-casos-de-uso.md`, `04-errores-pruebas-y-riesgos.md`, `05-dependencias-externas.md` y `06-diferencias-documentales.md`.
- Fase 2: `fase2/01-modelo-relacional.md`, `02-restricciones-e-indices.md`, `03-migraciones-y-trazabilidad.md`; diagramas `01-arquitectura-general.md`, `02-secuencias.md`, `03-estados.md`, `04-dominio-y-er.md` y `05-modelo-relacional.md`.
- Documento Maestro vigente e histórico: estructura completa, encabezados y secciones relevantes de plataforma, autenticación, seguridad, fases y datos; además, la matriz de diferencias.
- Backend: `pom.xml`, `application.yml`, migración Flyway V1, clases Java en `common/audit`, `common/security` e `identity/{api,application,domain,persistence}`, y las cinco clases de pruebas.
- Las cinco clases de pruebas unitarias; directorios `web/`, `database/`, `infra/` y `.github/workflows/` para confirmar su contenido vacío.

## Inventario y estado funcional

| Componente | Estado real |
|---|---|
| Documento Maestro vigente e histórico | Preservados; la plataforma web está documentada como excepción aprobada. El SHA-256 del histórico coincide con el registro previo: `870D7195B769D6309EC184F335F0D4D8644B6D88813BF5D4B68A3DAAEECCC64A`. |
| Requisitos, decisiones, pendientes, glosario, diagramas y diseño Fase 2 | Presentes. El modelo Fase 2 es una propuesta documental y aún tiene decisiones abiertas; no equivale a un esquema aprobado. |
| Backend Java/Spring | Esqueleto ejecutable a nivel de compilación con autenticación inicial: login, refresh, logout y `/me`; no es la plataforma TRAXIA completa. |
| Sesiones/JWT | Refresh opaco almacenado como hash, rotación, bloqueo pesimista por token y revocación de familia ante reutilización. Access JWT limitado a 10 minutos y refresh cookie HTTP-only. |
| Base de datos | Existe una migración Flyway inicial de identidad/sesiones. No se aplicó a una base en esta auditoría. La validación de esquema JPA/MySQL sigue pendiente. |
| Flutter Web | No implementado: `web/` no contiene archivos. No hay pantallas, navegación, formularios ni cliente API que validar. |
| Pruebas | Nueve pruebas unitarias pasan. No hay pruebas de controlador vía HTTP, de integración con MySQL, de contrato OpenAPI, frontend ni cobertura calculada. |
| Entorno/repositorio | `.env.local` está ignorado y no rastreado; los campos de credenciales examinados contienen marcadores. Los archivos de backend y documentación creados siguen sin seguimiento Git y no están committeados. |

## Hallazgos clasificados

“Abierto” significa que requiere diseño, aprobación o una capacidad que no existe; no implica que se haya intentado una corrección insegura.

| ID | Gravedad | Estado | Hallazgo |
|---|---|---|---|
| H-01 | ALTO | Abierto | Login y refresh no tienen limitación persistente/distribuida de intentos. El login es público y puede ser objeto de fuerza bruta; no exponer a Internet hasta definir y probar límites, manejo de IP/proxy y respuesta. Registrado como [PD-016](PENDIENTES.md). |
| H-02 | ALTO | Abierto | No existe Flutter Web ni flujo de producto; el backend solo cubre autenticación básica. El requisito de plataforma web se mantiene, pero aún no hay interfaz funcional que validar. No se construyó ahora porque el alcance solicitado es cerrar la auditoría de Fase 3, no comenzar la fase de frontend. |
| M-01 | MEDIO | Abierto | No hay aprovisionamiento inicial de usuarios/administrador. V1 no siembra identidades (correctamente evita credenciales predeterminadas), pero tampoco existe un procedimiento seguro para crear la primera cuenta. Ver [PD-017](PENDIENTES.md). |
| M-02 | MEDIO | Abierto | El modelo Fase 2 propone `company_id` para roles por organización, mientras V1 implementa roles globales. Además, `UNIQUE(user_id, role_id)` impide asignar de nuevo un rol revocado conservando la fila histórica. No se cambió el modelo sin aprobación; ver [PD-014](PENDIENTES.md) y [PD-015](PENDIENTES.md). |
| M-03 | MEDIO | Abierto | El objetivo de cobertura de 70 %, las pruebas MySQL/Testcontainers y la documentación OpenAPI no están configurados ni demostrados. Hay pruebas de lógica, pero no cobertura real ni pruebas HTTP/integración; tampoco hay workflow CI o análisis CVE automatizado. Ver [PD-018](PENDIENTES.md). |
| M-04 | MEDIO | Abierto | No se pudo comprobar la migración ni el mapeo completo JPA contra MySQL: Docker y cliente MySQL no están disponibles. En particular, se debe validar el tipo SQL de `refresh_sessions.token_hash` y los tipos `BINARY(16)`/`DATETIME(6)` con la versión objetivo. Ver [PD-013](PENDIENTES.md). |
| M-05 | MEDIO | Abierto/documentado | Cerrar sesión revoca la familia de refresh, pero no invalida JWT de acceso ya emitidos; estos pueden seguir vigentes hasta 10 minutos. Es la limitación expresamente documentada en DEC-013, no una revocación inmediata. |
| L-01 | BAJO | Abierto | Mockito emite una advertencia de auto-adjuntar el agente en Java 21. No impidió las pruebas; conviene ajustar el modo de agente antes de actualizar el JDK/runtime. |
| L-02 | BAJO | Corregido | README afirmaba que no había componentes de aplicación aunque ya existía backend. Ahora distingue entre backend inicial y frontend aún inexistente. |

No se identificaron credenciales reales en los archivos de entorno examinados. No se hizo un escaneo especializado de secretos o vulnerabilidades de dependencias; la comprobación de dependencias realizada no sustituye esos análisis.

## Correcciones aplicadas

| Archivo | Cambio |
|---|---|
| `backend/src/main/java/com/traxia/identity/domain/UserEntity.java` | Cambié asociaciones de varias listas/bags a conjuntos; el `EntityGraph` que carga métodos de acceso y roles a la vez podía provocar `MultipleBagFetchException` en Hibernate. |
| `backend/src/main/java/com/traxia/common/security/AccessTokenService.java` | Alineé el máximo de duración del access token a 600 segundos, consistente con DEC-013. |
| `backend/src/main/java/com/traxia/identity/api/AuthController.java` | El backend falla al iniciar si se configura una cookie de refresh no `Secure` fuera de entornos `local`, `development`, `dev` o `test`. |
| `backend/src/main/java/com/traxia/identity/api/AuthDtos.java` | Validé el límite BCrypt por bytes UTF-8, no solo por caracteres, para evitar una excepción de hashing con entradas multibyte largas. |
| `backend/src/main/java/com/traxia/identity/api/AuthExceptionHandler.java` | Añadí respuesta en español para JSON inválido y títulos localizados para errores de autenticación/validación. |
| `backend/src/main/java/com/traxia/common/security/SecurityConfiguration.java` | Eliminé un import no usado y dejé de exponer `Set-Cookie` a JavaScript; el navegador gestiona esa cabecera sin exponer el refresh token al cliente. |
| `.env.example`, `.env.local` | Retiré los marcadores obsoletos `JWT_ACCESS_SECRET` y `JWT_REFRESH_SECRET`; el backend usa `JWT_SIGNING_SECRET_BASE64`. `.env.local` sigue ignorado. |
| `README.md` | Corregí el estado real del frontend/backend y advertí que Flyway aplica V1 al arrancar contra la base configurada. |
| `docs/DECISIONES.md`, `docs/PENDIENTES.md` | Aclaré el estado de decisiones y registré los desacuerdos/pendientes de autorización, limitación de intentos, aprovisionamiento y OpenAPI. |

No se modificó la migración V1 ni se ejecutó contra una base de datos.

## Verificaciones ejecutadas

- `mvn verify` con Java 21.0.11 y Apache Maven 3.9.9 descargado temporalmente con verificación SHA-512: **correcto; 9 pruebas, 0 fallos, 0 errores**.
- `mvn dependency:analyze`: **terminó correctamente**. No es un análisis CVE ni una auditoría de seguridad de dependencias.
- `git diff --check`: **correcto**.
- Enlaces locales Markdown y balance de bloques cercados Mermaid: **sin enlaces rotos ni fences desbalanceados**. No se dispuso de un renderizador Mermaid para validar semántica/renderizado.
- `.env.local`: **ignorado por `.gitignore`, no rastreado y con marcadores en campos sensibles examinados**.
- Historial documental: hash SHA-256 del archivo histórico **coincide** con el registro previo.
- No se ejecutaron migraciones, no se inició el backend y no se alteró ninguna base de datos.

## Límites de esta auditoría

- No había Flutter/Dart, Docker ni MySQL disponibles; no se validaron UI responsive, navegador, CORS real, cookie end-to-end, Flyway, constraints ni `ddl-auto: validate` contra MySQL.
- No existe pipeline de CI dentro de `.github/workflows/`.
- La verificación Maven mostró avisos de Mockito sobre carga dinámica del agente, aunque el proceso terminó correctamente.
- No se midió cobertura porque no hay configuración JaCoCo.

## Decisiones que requieren aprobación antes de cerrar Fase 3 o desplegar

1. Confirmar si los roles son globales o dependen de empresa/sede y cómo se conserva/reasigna su historial.
2. Aprobar política de rate limiting/lockout para login y refresh, con proxy de confianza y observabilidad.
3. Aprobar procedimiento seguro para aprovisionar el administrador inicial, sin contraseña predeterminada.
4. Confirmar versión mínima de MySQL y validar V1/JPA contra ella antes de aplicar la migración.
5. Revisar DEC-013 en integración real: dominios web/API, `SameSite`, HTTPS, CORS y expiración/revocación.
6. Aprobar el alcance MoSCoW pendiente antes de comprometer funcionalidades del MVP.

## Pasos recomendados para completar Fase 3

1. Resolver los puntos de rol/contexto y versión MySQL que afectan a V1; hacer una revisión de migración sin ejecutarla en datos reales.
2. Añadir MySQL Testcontainers y pruebas HTTP para login, refresh, replay, logout, expiración, cookies, CORS/CSRF y permisos; ejecutar el esquema desde cero en una base de prueba.
3. Incorporar OpenAPI/Swagger y contrato de errores; medir cobertura backend frente al objetivo documentado.
4. Diseñar e implementar rate limiting distribuido y aprovisionamiento inicial de administrador, sin defaults compartidos.
5. Probar el arranque local con base efímera y revisar `.env.example`/`.env.local`; no conectar a datos reales.
6. Presentar resultados y solicitar aprobación explícita de cierre antes de pasar a otra fase.

## Seguimiento de los cinco puntos de Fase 3

Se agregó este seguimiento después de la auditoría inicial; los hallazgos anteriores describen el estado en la fecha de corte de esa auditoría.

| Punto | Trabajo posterior | Estado comprobado |
|---|---|---|
| Roles por empresa | La propietaria aprobó el principio de DEC-014: `ADMIN` global y roles operativos por membresía empresarial, con autorización en servidor por empresa. No se añadieron tablas ni se modificó V1. | **Principio aprobado; diseño físico pendiente:** faltan cardinalidad, invitación/asignación, tipo del perfil legalizador e historial de reasignación. |
| Límite de intentos | Login integra buckets persistentes HMAC con clave separada, 5 fallos por correo o 30 por dirección en 15 minutos, bloqueo de 15 minutos y HTTP 429/`Retry-After`. La escritura de fallos usa transacción independiente para sobrevivir al 401. V2 crea la tabla y la limpieza programada elimina buckets expirados. | **Implementado, integración no ejecutada:** los escenarios se incluyeron en pruebas Testcontainers, pero quedaron omitidos por falta de Docker. Debe definirse el proxy de confianza antes del despliegue. |
| Primer administrador | Perfil `admin-bootstrap` sin endpoint web, contraseña por variables inyectadas, validación BCrypt, auditoría y bloqueo transaccional del rol ADMIN para impedir aprovisionamientos simultáneos o repetidos. | **Implementado, no probado contra MySQL:** prueba automatizada preparada pero omitida sin Docker. No se desplegó ni se creó usuario real. |
| Migración MySQL | MySQL `8.4` fue aprobado como objetivo de pruebas. La prueba inicia contexto Spring, ejecuta Flyway V1+V2 y fuerza validación JPA; además inspecciona tipos SQL. V1 no se reescribió; V2 es incremental. | **No validada en ejecución:** no hay Docker/servidor MySQL disponible. No se conectó a base real ni se ejecutaron migraciones fuera del contenedor de prueba. |
| Cookies/autenticación web | Se añadió una prueba MockMvc de login, cookie HTTP-only/SameSite/path y cabeceras CORS, además de un escenario HTTP de 401/429. | **No ejecutada y no equivale a navegador real:** la clase completa de integración quedó omitida sin Docker. Flutter Web no existe todavía, por lo que no se pudo probar una sesión en navegador real. |

### Validación Maven posterior

- Apache Maven 3.9.9 descargado temporalmente y verificado con SHA-512; Java 21.0.11.
- `mvn verify`: **BUILD SUCCESS**, 14 pruebas contabilizadas, 0 fallos, 0 errores; 9 aprobadas y 5 omitidas. Las cinco omitidas pertenecen a la clase MySQL/Testcontainers, porque Docker no está disponible. Por tanto, este resultado **no** valida Flyway ni Hibernate contra MySQL.
- Las pruebas preparadas abarcan V1+V2/tipos, persistencia y bloqueo de rate limit, limpieza de contador de cuenta, 429 HTTP, aprovisionamiento único y cookie/CORS por MockMvc. No se ejecutaron en esta máquina.
- `.env.local` se mantiene ignorado por Git; se añadieron solo nombres/valores marcadores para las variables nuevas. No se imprimieron ni registraron sus valores locales.

### Estado actual y bloqueos restantes

Fase 3 **no debe cerrarse todavía**. Ya se aprobaron el principio de roles por empresa y MySQL 8.4, pero faltan decisiones de detalle para congelar el modelo relacional; la validación MySQL requiere Docker; y la validación de cookies requiere ejecutar la prueba integrada y, para cumplir literalmente el requisito de navegador, construir/servir Flutter Web y probar allí con HTTPS/orígenes reales. También sigue pendiente el contrato OpenAPI registrado como PD-018. No se ejecutó una migración ni se modificó una base de datos real.
