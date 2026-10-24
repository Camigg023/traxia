# Decisiones del proyecto TRAXIA

Registro vivo de decisiones y propuestas técnicas con estado explícito. Las decisiones de alcance no se cambian sin aprobación expresa; las decisiones técnicas menores deben conservar la trazabilidad y no contradecir el Documento Maestro ni la aclaración de plataforma vigente.

## DEC-001 — Plataforma web adaptable

- **Estado:** Aprobada por la propietaria del proyecto el 2026-10-22.
- **Decisión:** TRAXIA se desarrolla como plataforma web adaptable con Flutter Web para los tres perfiles principales y el panel administrativo. Backend Java + Spring Boot; MySQL.
- **Prioridad:** Esta aclaración aprobada prevalece sobre toda mención a app móvil en el Documento Maestro adjunto y en documentos históricos.
- **Justificación:** No se exigirá instalación de aplicación; la misma experiencia web debe adaptarse a computador, tableta y celular.
- **Consecuencia:** No se crean proyectos Flutter Mobile, Android o iOS. Mapas, geolocalización, seguimiento, notificaciones y verificación deben considerar permisos y capacidades del navegador. El acceso administrativo es web y está protegido por rol.
- **Alternativas descartadas:** Aplicación Flutter móvil para los tres perfiles; aplicación móvil más panel web.
- **Registro:** Ver [Aclaración y control de alcance](fase1/00-aclaracion-y-control.md) y [Diferencias documentales](fase1/06-diferencias-documentales.md).

## DEC-002 — Conservar documentos fuente e histórico

- **Estado:** Aprobada por la propietaria del proyecto el 2026-10-22.
- **Decisión:** Conservar literalmente el Documento Maestro incluido en el prompt final como `docs/TRAXIA_DOCUMENTO_MAESTRO.md`. Conservar el maestro previo del repositorio, sin sobrescribir ni perder contenido, en `docs/historico/TRAXIA_DOCUMENTO_MAESTRO_ANTERIOR.md`.
- **Justificación:** Mantener la integridad de la fuente aprobada y la trazabilidad de diferencias históricas.
- **Consecuencia:** El contenido discordante de los textos anteriores se documenta; no se reescribe silenciosamente.

## DEC-003 — Herramientas de estado y base de datos local

- **Estado:** Aprobada en el prompt final.
- **Decisión:** Riverpod para estado; `go_router` para navegación; `dio` para HTTP; `drift` para persistencia local/offline en navegador, sujeto a comprobar compatibilidad web antes de fijar versiones.
- **Justificación:** Alinear frontend, navegación, acceso HTTP y operaciones offline con las decisiones explícitas del proyecto.
- **Alternativas descartadas:** Bloc como alternativa de estado; `sqflite` como alternativa de persistencia local.
- **Riesgo/validación:** Confirmar soporte de Flutter Web, IndexedDB/WASM, navegadores objetivo y estrategia de sincronización durante las fases de diseño técnico.

## DEC-004 — Arquitectura backend

- **Estado:** Aprobada en el prompt final.
- **Decisión:** Java LTS vigente (21 o superior) y Spring Boot 3.x en monolito modular por dominios, con paquete raíz `com.traxia`, arquitectura `controller → service → repository`, DTOs y mapeadores.
- **Justificación:** Facilitar la implementación y sustentación académica sin la complejidad operacional de microservicios.
- **Alternativas descartadas:** Microservicios para el MVP.
- **Riesgo/validación:** La versión exacta del JDK y Spring Boot se fija al preparar el scaffolding, verificando compatibilidad y soporte oficiales; no se inventa un número de versión.

## DEC-005 — Persistencia y datos

- **Estado:** Aprobada en el prompt final.
- **Decisión:** MySQL 8.x, `utf8mb4`, Flyway, IDs internos `BIGINT`, identificadores públicos UUID, fechas almacenadas en UTC y auditoría de acciones sensibles.
- **Justificación:** Consistencia transaccional y trazabilidad en operaciones de contratación, asignación y liquidación.
- **Consecuencia:** Restricciones y mecanismos de concurrencia deben prevenir duplicados, asignaciones incompatibles y doble aceptación.

## DEC-006 — Proveedores externos con puertos y mocks

- **Estado:** Aprobada en el prompt final.
- **Decisión:** Comenzar con presupuesto cero; aislar cada proveedor tras una interfaz y usar mocks identificados. Activar implementaciones externas únicamente mediante configuración y tras verificar costo, condiciones, cobertura y consentimiento.
- **Justificación:** Poder probar los flujos centrales sin asumir costos ni presentar simulaciones como datos oficiales.
- **Consecuencia:** Un fallo externo no produce datos ficticios ni una respuesta con apariencia de confirmación.

## DEC-007 — Autenticación, archivos y protección de datos

- **Estado:** Aprobada en el prompt final.
- **Decisión:** Spring Security y JWT con access token de vida corta y refresh token rotatorio/revocable; OAuth 2.0/OIDC para Google; contraseña con Argon2 o BCrypt. Almacenamiento de objetos compatible con S3, MinIO local, URLs firmadas de corta duración y separación de documentos y biometría.
- **Justificación:** Separar credenciales y archivos sensibles del cliente web y limitar exposición.
- **Riesgo/validación:** Diseñar el almacenamiento de tokens seguro para navegador; no asumir que `flutter_secure_storage` elimina riesgos propios del entorno web. Datos biométricos requieren alternativa no biométrica, consentimiento explícito, acceso restringido y retención por definir.

## DEC-008 — Calidad y seguridad por fase

- **Estado:** Aprobada en el prompt final.
- **Decisión:** JUnit 5, Mockito, Testcontainers con MySQL, pruebas de widgets, `integration_test`, golden tests claro/oscuro, Postman, GitHub Actions, análisis de dependencias y Dependabot. Objetivo de cobertura: 70 % en servicios backend. Pruebas de rendimiento (k6 o JMeter) y OWASP ZAP en la fase 16.
- **Justificación:** Vincular las verificaciones a la madurez y los riesgos de cada fase.
- **Consecuencia:** La cobertura es un objetivo medido en la capa de servicio, no una garantía de ausencia de defectos.

## DEC-009 — Idioma, nombres y formato regional

- **Estado:** Aprobada en el prompt final.
- **Decisión:** Interfaz, documentación, comentarios y mensajes de commit en español; identificadores de código, tablas y rutas API en inglés; glosario bilingüe en `docs/GLOSARIO.md`. Moneda COP y zona horaria `America/Bogota` en interfaz.
- **Justificación:** Mantener comprensión para usuarios y jurado, con convenciones técnicas consistentes.

## DEC-010 — Sin pagos en custodia

- **Estado:** Aprobada en el prompt final.
- **Decisión:** El alcance inicial registra información económica y liquidaciones; no custodia fondos ni administra saldos de terceros. Pasarela y facturación electrónica DIAN quedan fuera del alcance inicial y requieren evaluación legal.
- **Justificación:** No añadir riesgos regulatorios y financieros no validados.

## DEC-011 — Reglas comerciales configurables, no inventadas

- **Estado:** Provisional, indicación explícita de la propietaria del proyecto.
- **Decisión:** Comisión, cancelaciones y penalidades se modelan como parámetros administrables, sin fijar cifras reales; quién paga el servicio se indica en las condiciones de cada carga. TRAXIA se plantea provisionalmente como intermediario tecnológico.
- **Justificación:** El Documento Maestro no determina importes, política ni obligaciones legales.
- **Pendiente:** La responsabilidad legal, seguros y parámetros de negocio requieren decisión del dueño y/o revisión legal. Ver [Pendientes](PENDIENTES.md).

## DEC-012 — Nombres exactos de archivos de ambiente

- **Estado:** Aprobada por la propietaria del proyecto el 2026-10-22.
- **Decisión:** Mantener `.env.local` ignorado por Git y proporcionar `.env.example` sin credenciales reales. Los valores locales iniciales son marcadores y no habilitan servicios.
- **Justificación:** Facilitar configuración posterior sin filtrar secretos ni inferir credenciales.

## DEC-013 — Transporte de sesión para Flutter Web

- **Estado:** Decisión técnica provisional aplicada en Fase 3, pendiente de revisión conjunta al cierre.
- **Decisión:** El JWT de acceso tiene vida corta y solo se conserva en memoria de Flutter Web; el refresh token opaco se guarda en cookie `HttpOnly`, `SameSite=Strict`, con expiración y rotación en servidor. Las llamadas API usan el access token en el encabezado `Authorization`; renovación y cierre exigen origen permitido y encabezado personalizado, además de CORS exacto. En producción la cookie debe ser `Secure`.
- **Justificación:** Evitar persistir access tokens en `localStorage` y reducir exposición a XSS; limitar CSRF en el endpoint que usa cookie mediante SameSite, validación de origen, encabezado no simple y allowlist CORS.
- **Alternativas descartadas:** Guardar refresh/access tokens en `localStorage`; autenticar todas las solicitudes con cookies sin defensa CSRF.
- **Consecuencias:** El frontend debe refrescar la sesión tras recarga y nunca escribir tokens en logs/almacenamiento durable. Se recomienda publicar web y API bajo el mismo sitio. Los orígenes de desarrollo/producción deben configurarse de forma explícita. El backend rechaza cookies no `Secure` fuera de entornos locales/de prueba. El cierre revoca la familia del refresh token; un access token ya emitido puede seguir válido hasta expirar (máximo 10 minutos).
- **Validación pendiente:** Revisión de seguridad del flujo completo, despliegue real con HTTPS, CSRF/CORS, subdominios y pruebas de integración antes de producción.
- **Referencia:** [Spring Security — JWT Resource Server](https://docs.spring.io/spring-security/reference/servlet/oauth2/resource-server/jwt.html); [Spring Security — CSRF](https://docs.spring.io/spring-security/reference/servlet/exploits/csrf.html).

## DEC-014 — Alcance de roles y membresías empresariales

- **Estado:** Decisiones funcionales aprobadas por la propietaria; implementación física pendiente.
- **Decisión:** Una cuenta puede pertenecer a varias empresas y tener roles distintos por empresa. Las membresías requieren invitación y aceptación; se conserva cada periodo histórico y la reincorporación crea uno nuevo. Solo empresas pueden ser legalizadoras; las capacidades de generadora, transportadora y legalizadora se verifican independientemente. Los permisos empresariales abarcan toda la empresa, sin alcance por sede inicialmente. TRAXIA nombra al primer administrador empresarial tras verificar la empresa y controla la recuperación administrativa con auditoría. `ADMIN` es global y no concede permisos empresariales.
- **Separación técnica:** `user_roles` queda reservado a roles globales de TRAXIA. Los permisos empresariales deben derivarse de la membresía y sus roles, consultados en el contexto de la empresa; una invitación pendiente nunca concede acceso. Los códigos heredados `SHIPPER`, `DRIVER` y `CARRIER` de V1 no bastan para autorizar acciones globales ni empresariales.
- **Estado de implementación:** Aún no existen empresas ni membresías en V1/V2. Este cambio filtra las autoridades globales a `ADMIN`, incluso al validar JWT, para evitar que asignaciones empresariales heredadas se interpreten como permisos globales. No modifica datos ni migraciones.

## DEC-015 — Limitación de intentos de inicio de sesión

- **Estado:** Política técnica aplicada al endpoint de login; requiere validación de despliegue detrás de proxy antes de exponerlo a Internet.
- **Política:** Tras 5 fallos por correo normalizado o 30 fallos desde una dirección remota dentro de 15 minutos, bloquear esa categoría durante 15 minutos. Responder HTTP 429 con `Retry-After`; los errores de credenciales siguen siendo genéricos. Un login correcto elimina el contador de correo, no el contador de dirección.
- **Persistencia y datos:** Contadores por bucket HMAC-SHA256 en MySQL; se usa una clave Base64 independiente de la clave JWT, de al menos 32 bytes. No se almacena el correo ni la IP en la tabla. Flyway V2 añade esa tabla sin reescribir V1. Los buckets se eliminan al expirar la ventana y el bloqueo.
- **Concurrencia/operación:** El contador se actualiza con upsert atómico; solicitudes concurrentes ya autenticadas pueden producir una pequeña superación del umbral. No se confía en `Forwarded`/`X-Forwarded-For` por defecto: `remoteAddr` debe ser establecido por el proxy frontal confiable, que debe retirar cabeceras entrantes no confiables y estar documentado antes del despliegue.
- **Ajuste:** Los umbrales se parametrizan por ambiente; los valores iniciales son defensas técnicas, no una regla comercial.

## DEC-016 — Aprovisionamiento del primer administrador

- **Estado:** Proceso inicial implementado, aún requiere prueba con MySQL y revisión operativa antes de despliegue.
- **Decisión:** Una herramienta de una sola ejecución, activada únicamente con el perfil `admin-bootstrap`, crea una cuenta verificada, guarda la contraseña con el `PasswordEncoder` BCrypt configurado y asigna `ADMIN` global. No existe endpoint HTTP ni cuenta/contraseña predeterminada.
- **Protecciones:** Se requiere email válido y contraseña de 16 a 72 bytes UTF-8. La transacción bloquea la fila del rol `ADMIN`; aborta si ya hay un administrador activo o el email ya existe. Un evento de auditoría registra el aprovisionamiento.
- **Operación:** Inyectar `TRAXIA_BOOTSTRAP_ADMIN_EMAIL` y `TRAXIA_BOOTSTRAP_ADMIN_PASSWORD` desde un canal de secretos local/de despliegue; ejecutar una sola vez con el perfil y el servicio web deshabilitado; retirar las variables al finalizar. No pasar la contraseña como argumento de línea de comandos ni registrar valores. Ver instrucciones de Fase 3 en el README.

## DEC-017 — Versión base MySQL para validación

- **Estado:** MySQL 8.4 LTS aprobado por la propietaria el 2026-10-22 como objetivo de pruebas; validación efectiva pendiente de Docker/Testcontainers.
- **Decisión:** Usar la serie MySQL 8.4 LTS (`mysql:8.4`) como base del contrato de migraciones. La aplicación conserva `ddl-auto: validate`; no se permite usar `ddl-auto: update` ni modificar una base real durante estas pruebas.
- **Alcance:** La prueba Testcontainers migra una instancia descartable, comprueba el esquema inicial y permite que Hibernate valide los mappings al iniciar contexto. La falta de Docker significa que la presencia de esta prueba no se reportará como validación ejecutada.
