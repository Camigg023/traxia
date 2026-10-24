# TRAXIA

TRAXIA es una plataforma web responsive para conectar empresas que necesitan transportar mercancías, conductores y empresas transportadoras/legalizadoras en Colombia.

## Plataforma

- **Frontend:** Flutter Web para los tres perfiles y el panel administrativo; acceso desde computador, tableta y celular mediante navegador.
- **Backend:** Java + Spring Boot, organizado como monolito modular.
- **Base de datos:** MySQL.
- **Sin aplicación móvil:** no se crearán proyectos Flutter Mobile, Android o iOS.

La aclaración web aprobada prevalece sobre menciones anteriores a una aplicación móvil. El documento maestro se conserva literalmente; la excepción de plataforma y las diferencias están documentadas en [DECISIONES](docs/DECISIONES.md) y [Fase 1](docs/fase1/00-aclaracion-y-control.md).

## Documentación

- [Documento Maestro vigente](docs/TRAXIA_DOCUMENTO_MAESTRO.md)
- [Documento Maestro anterior (histórico)](docs/historico/TRAXIA_DOCUMENTO_MAESTRO_ANTERIOR.md)
- [Entregables de análisis de Fase 1](docs/fase1/)
- [Diseño de base de datos de Fase 2](docs/fase2/)
- [Diagramas Mermaid](docs/diagramas/)
- [Decisiones](docs/DECISIONES.md)
- [Pendientes y dependencias](docs/PENDIENTES.md)
- [Glosario](docs/GLOSARIO.md)
- [Auditoría integral (2026-10-22)](docs/AUDITORIA_INTEGRAL_2026-10-22.md)

La interfaz Flutter Web está en `web/`. Incluye inicio de sesión, registro local con verificación de correo y navegación inicial; las membresías empresariales operativas aún no están implementadas. Consulta [web/README.md](web/README.md) para instalar Flutter y ejecutar la interfaz. La priorización del MVP guía la implementación incremental sin sustituir los requisitos del Documento Maestro.

## Backend

El backend se desarrolla en `backend/`. El diseño de la sesión web mantiene el JWT de acceso en memoria del cliente y el refresh token en cookie `HttpOnly`, rotatoria y restringida; no guardar tokens en `localStorage`. Las operaciones que usan el refresh cookie verifican origen y encabezado de solicitud.

Para iniciar en local, instala Java 25 (LTS) y Maven, configura una base MySQL local y genera secretos locales; los marcadores de `.env.local` no son utilizables. Desde `backend/`, ejecuta `mvn test` y `mvn spring-boot:run`. Flyway ejecuta las migraciones pendientes al arrancar: no apuntes esta configuración a una base con datos reales sin autorización y respaldo. `mvn verify` incluye una prueba de integración con Testcontainers y MySQL 8.4; necesita Docker.

El registro de autoservicio se habilita únicamente en `local`, `development`, `dev` o `test`, y además requiere `TRAXIA_REGISTRATION_ENABLED=true`. En local, inicia Mailpit con `docker compose -f compose.mailpit.yml up -d`; la bandeja de pruebas queda en `http://localhost:8025`. El enlace de verificación llega allí y caduca en 30 minutos. La pantalla solicita confirmación manual para activar la cuenta. El aviso mostrado es provisional y exclusivo para pruebas: no son términos ni aviso de privacidad legal. No actives el registro de demostración en producción.

La limitación inicial del login es de 5 fallos por correo o 30 por dirección en 15 minutos, con bloqueo por 15 minutos y respuesta HTTP 429. Configura una clave aleatoria independiente `AUTH_RATE_LIMIT_HMAC_SECRET_BASE64` de al menos 32 bytes; no reutilices la clave JWT. Mientras no haya una política de proxy confiable configurada, el backend no confía en `X-Forwarded-For`; un despliegue detrás de proxy debe fijar el `remoteAddr` real y retirar cabeceras reenviadas entrantes no confiables.

El primer administrador se crea solo mediante ejecución puntual del perfil `admin-bootstrap`, sin endpoint HTTP ni credenciales predeterminadas. Con la base de datos autorizada y las variables secretas inyectadas de forma segura, inicia desde `backend/` con `mvn spring-boot:run -Dspring-boot.run.profiles=admin-bootstrap`; el perfil deshabilita el servidor web. Configura `TRAXIA_BOOTSTRAP_ADMIN_EMAIL` y `TRAXIA_BOOTSTRAP_ADMIN_PASSWORD` fuera de Git, usa una contraseña única de 16 a 72 bytes UTF-8 y retira ambas variables después. El comando falla si ya existe un administrador activo.

La autenticación inicial expone `POST /api/v1/auth/login`, `POST /api/v1/auth/refresh`, `POST /api/v1/auth/logout` y `GET /api/v1/auth/me`; el registro/verificación local usa `POST /api/v1/auth/register` y `POST /api/v1/auth/verify-email`. Refresh y logout requieren el origen permitido y `X-TRAXIA-Refresh-Request: true`; el cliente web debe enviar credenciales (`credentials: include`) al iniciar, renovar y cerrar sesión para recibir o enviar la cookie. En producción configura `REFRESH_COOKIE_SECURE=true`. La recuperación de contraseña y las membresías empresariales aún no están implementadas. El perfil elegido durante el registro se almacena solo como intención y no asigna roles de negocio.

Para iniciar Flutter Web, instala Flutter con soporte Web y sigue las instrucciones de [web/README.md](web/README.md). En local, el puerto web predeterminado `5000` coincide con el origen permitido por el backend. La dirección del API se entrega como `--dart-define=TRAXIA_API_BASE_URL=...`; nunca incluyas credenciales en el frontend.

## Variables de entorno

- `.env.example` contiene nombres de variables y marcadores sin credenciales reales.
- `.env.local` es local e ignorado por Git. Puede contener secretos reales para servicios locales: no lo compartas ni lo subas al repositorio. En `.env.example` hay marcadores que deben reemplazarse.
- El backend actual consume `MYSQL_*`, `MAIL_*`, `TRAXIA_REGISTRATION_ENABLED`, `TRAXIA_TEST_NOTICE_VERSION`, `TRAXIA_WEB_BASE_URL`, `JWT_SIGNING_SECRET_BASE64`, `AUTH_RATE_LIMIT_HMAC_SECRET_BASE64`, `LOGIN_LIMIT_*`, `TRAXIA_BOOTSTRAP_ADMIN_*` (solo para el perfil de bootstrap), `JWT_ISSUER`, `JWT_AUDIENCE`, `JWT_ACCESS_TTL_SECONDS`, `JWT_REFRESH_TTL_SECONDS`, `REFRESH_COOKIE_SECURE`, `BCRYPT_STRENGTH`, `WEB_ALLOWED_ORIGINS`, `APP_ENV` y `APP_PORT`. Las variables de proveedores y almacenamiento son futuras y todavía no las usa la aplicación.
- No agregues claves reales al repositorio. Las integraciones externas se mantienen como mocks y desactivadas hasta revisar costos, privacidad y autorización.
