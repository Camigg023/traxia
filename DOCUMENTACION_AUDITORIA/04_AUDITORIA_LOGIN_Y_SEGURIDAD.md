# AUDITORÍA COMPLETA DEL LOGIN, AUTENTICACIÓN Y SEGURIDAD

## 1. INTRODUCCIÓN Y ALCANCE

El módulo de autenticación de TRAXIA representa el perímetro de seguridad más crítico del sistema. Esta auditoría inspecciona y comprueba de forma empírica y forense los veinte (20) aspectos exigidos por la rúbrica de evaluación sobre los entornos en ejecución real:
- **Frontend:** Flutter Web en `http://localhost:5000/iniciar-sesion`.
- **Backend:** Spring Security en `http://localhost:8080/api/v1/auth/*`.
- **Servidor SMTP:** Mailpit en `http://localhost:8025`.
- **Base de Datos:** MySQL 8.4 Server en `localhost:3306`.

---

## 2. EVALUACIÓN DETALLADA DE LOS 20 PUNTOS DE AUDITORÍA

### Punto 1: Carga de la Pantalla de Inicio de Sesión
- **Ruta Web:** `http://localhost:5000/iniciar-sesion`.
- **Código Fuente:** [sign_in_screen.dart](file:///C:/Users/marti/Downloads/traxia-main/traxia-main/web/lib/screens/sign_in_screen.dart).
- **Verificación:** Se verificó la respuesta HTTP 200 del servidor web. La pantalla implementa un diseño *split-screen* responsivo con formulario flotante sobre fondo desenfocado (*glassmorphism*), selector de modo oscuro/claro y soporte para pantallas móviles y de escritorio.

### Punto 2: Validación de Campos
- **Frontend:** El formulario utiliza `GlobalKey<FormState>()` y validadores en cada campo:
  - Correo electrónico: Expresión regular que verifica formato RFC 5322 estándar (`_emailRegex`).
  - Contraseña: Longitud mínima validada de 8 caracteres.
- **Backend:** Los DTOs (`LoginRequest`, `RegisterRequest`) aplican anotaciones Bean Validation (`@NotBlank`, `@Email`, `@Size(min = 8, max = 72)`).
- **Evidencia Forense:** Una petición con cuerpo mal formado o campos vacíos (`POST /api/v1/auth/login`) devuelve de forma inmediata `HTTP 400 Bad Request`:
  ```json
  {"type":"about:blank","title":"Bad Request","status":400,"detail":"Invalid request content.","instance":"/api/v1/auth/login"}
  ```

### Punto 3: Inicio de Sesión
- **Flujo:** El cliente envía las credenciales en formato JSON mediante `POST /api/v1/auth/login`.
- **Backend:** `AuthController.java` delega en `AuthService.login(...)`, el cual utiliza `AuthenticationManager` y `TraxiaUserDetailsService` para verificar las credenciales contra la base de datos de manera transaccional.

### Punto 4: Credenciales Incorrectas
- **Comportamiento:** Si el usuario no existe o la contraseña no coincide con el hash almacenado, el sistema rechaza la petición.
- **Evidencia Forense:** Petición con clave errónea para `nonexistent@traxia.local`:
  ```json
  HTTP/1.1 401 Unauthorized
  {"title":"No autorizado","status":401,"detail":"Correo o contraseña incorrectos."}
  ```
- **Auditoría en Base de Datos:** Se comprueba que en la tabla `audit_events` se inserta un registro con `action_code = 'AUTH_LOGIN'` y `outcome = 'FAILURE'`. No se revela si el fallo se debió a correo inexistente o clave errónea (prevención de enumeración de usuarios).

### Punto 5: Credenciales Válidas
- **Comportamiento:** Petición con correo `empresa.colombia@traxia.local` y clave correcta:
  ```json
  HTTP/1.1 200 OK
  {
    "accessToken": "eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJmYzk5ZTE1MC1lY2Ni...",
    "tokenType": "Bearer",
    "expiresInSeconds": 600,
    "user": {
      "id": "fc99e150-eccb-43c2-8ffa-1b8d3fcfeb36",
      "email": "empresa.colombia@traxia.local",
      "roles": []
    }
  }
  ```
- **Cabecera de Respuesta:**
  `Set-Cookie: TRAXIA_REFRESH=...; Path=/api/v1/auth; Max-Age=604800; HttpOnly; SameSite=Strict`

### Punto 6: Usuario No Verificado
- **Comportamiento:** En la base de datos de TRAXIA existe el usuario `id = 1` (`martinmontoya.1247@gmail.com`) con estado `PENDING_VERIFICATION`.
- **Prueba en Vivo:** Al intentar iniciar sesión con este usuario, `TraxiaUserDetailsService.toUserDetails` evalúa la condición:
  ```java
  boolean enabled = "ACTIVE".equals(user.getStatus())
          && user.getEmailVerifiedAtUtc() != null
          && !passwordHash.isBlank();
  ```
  Al ser `enabled = false`, `DaoAuthenticationProvider` lanza `DisabledException`. `AuthService` captura la excepción y retorna `HTTP 401 Unauthorized`. El usuario no verificado tiene vedado el acceso al sistema.

### Punto 7: Usuario Bloqueado
- **Comportamiento:** Si un usuario tiene estado `BLOCKED` en la tabla `users`, el atributo `enabled` se evalúa a `false`, bloqueando de inmediato cualquier autenticación. Adicionalmente, el limitador de tasa bloquea temporalmente al usuario a nivel de IP/cuenta.

### Punto 8: Protección contra Fuerza Bruta (Rate Limiting)
- **Implementación Técnica:** Clase `LoginAttemptLimiter.java` y tabla Flyway `auth_attempt_limits`.
- **Mecanismo:** Para evitar almacenar correos o IPs en texto plano, los identificadores se anonimizan mediante un hash **HMAC-SHA256** utilizando una clave secreta (`AUTH_RATE_LIMIT_HMAC_SECRET_BASE64`).
- **Política:** Máximo 5 fallos por cuenta o 30 por dirección IP en una ventana de 15 minutos (900 s).
- **Evidencia Empírica de Laboratorio:**
  - Intentos 1 a 5: `HTTP 401 Unauthorized`.
  - Intento 6: `HTTP 429 Too Many Requests`:
    ```json
    {"title":"Demasiados intentos","status":429,"detail":"Espera antes de volver a intentar iniciar sesión."}
    ```
  - Registro en MySQL: Columna `failure_count = 5`, `blocked_until_utc = 2026-11-02 20:45:00 UTC`.

### Punto 9: JSON Web Tokens (JWT)
- **Estándar:** RFC 7519.
- **Firma:** Algoritmo simétrico HMAC-SHA256 (`HS256`) con secreto de 256 bits (`JWT_SIGNING_SECRET_BASE64`).
- **Claims Validados:**
  - `sub`: Identificador UUID público del usuario (ej. `fc99e150-eccb-43c2-8ffa-1b8d3fcfeb36`).
  - `iss`: Emisor verificado (`traxia-api`).
  - `aud`: Audiencia esperada (`traxia-web`).
  - `exp`: Tiempo de expiración estricto (600 segundos / 10 minutos).
  - `roles`: Lista de roles del sistema con prefijo `ROLE_` (`SHIPPER`, `DRIVER`, `CARRIER`, `ADMIN`).

### Punto 10: Refresh Tokens
- **Implementación:** Almacenamiento seguro en la tabla `refresh_sessions`.
- **Estructura Criptográfica:** El token en crudo emitido al cliente es una cadena URL-Safe de 32 bytes aleatorios generados con `SecureRandom`.
- **Persistencia:** En la base de datos **NUNCA se almacena el token en texto plano**, sino su resumen criptográfico SHA-256 (`token_hash CHAR(64)`).

### Punto 11: Rotación de Tokens (Token Rotation & Family Revocation)
- **Un solo uso (One-Time Use):** Cada llamada a `POST /api/v1/auth/refresh` invalida el token actual (marca `replaced_by_id = nuevo_id`) y emite uno nuevo.
- **Detección de Robo de Token (Family Invalidation):** Si un atacante intercepta un refresh token y lo utiliza después de que el usuario legítimo ya lo rotó, el servicio `RefreshSessionService.rotate` detecta que el token ya tiene `revoked_at_utc != null` o `replaced_by_id != null`. En ese instante, el sistema **revoca toda la familia de sesiones (`family_id`)**, expulsando tanto al atacante como al usuario y forzando reautenticación completa.

### Punto 12: Cookies HttpOnly
- **Directivas de Emisión:**
  - `HttpOnly`: Impide el acceso a la cookie desde JavaScript (`document.cookie`), neutralizando ataques XSS dirigidos al robo de sesión.
  - `SameSite=Strict`: Impide el envío de la cookie en peticiones cruzadas originadas desde sitios de terceros (defensa nativa CSRF).
  - `Path=/api/v1/auth`: La cookie solo se transmite a los endpoints de autenticación, protegiendo las demás rutas de la API.
  - `Secure`: Exigido obligatoriamente en entornos productivos (subsanado en BUG-001).

### Punto 13: Persistencia de Sesión
- **Mecanismo:** Al recargar la aplicación en el navegador (`F5`), la instancia de Flutter reinicia su memoria y su Access Token se pierde. En `initState()` de `app.dart`, se ejecuta `authController.restoreSession()`, el cual invoca a `POST /api/v1/auth/refresh`. El navegador envía la cookie HttpOnly, el backend valida y entrega un nuevo Access Token de 10 minutos, manteniendo la sesión del usuario de forma transparente.

### Punto 14: Expiración de Sesión
- **Token de Acceso:** 600 segundos (10 minutos).
- **Token de Refresco:** 604800 segundos (7 días).
- **Expiración de Inactividad:** Si transcurren 7 días sin refrescar la sesión, el token de refresco expira en la base de datos (`expires_at_utc < now`), y el backend responde `401 Unauthorized: "La sesión expiró o ya no es válida"`, obligando al usuario a identificarse nuevamente.

### Punto 15: Cierre de Sesión (Logout)
- **Endpoint:** `POST /api/v1/auth/logout`.
- **Efectos:**
  1. Revocación en base de datos: La sesión activa se marca con `revoked_at_utc = now()`.
  2. Borrado de cookie: Se emite cabecera `Set-Cookie: TRAXIA_REFRESH=; Max-Age=0; Path=/api/v1/auth; HttpOnly`.
  3. Código de respuesta: `HTTP 204 No Content`.
  4. Intentos posteriores de refresco devuelven `HTTP 401 Unauthorized`.

### Punto 16: Protección de Rutas (Guards de Navegación)
- **Frontend:** `GoRouter` en `web/lib/app.dart`:
  ```dart
  final authOnlyPaths = ['/panel', '/publicar-carga', '/publish-load', '/viajes', '/trips'];
  final unauthOnlyPaths = ['/iniciar-sesion', '/crear-cuenta'];
  if (path == '/') return isSignedIn ? '/panel' : '/iniciar-sesion';
  if (isSignedIn && unauthOnlyPaths.contains(path)) return '/panel';
  if (!isSignedIn && authOnlyPaths.contains(path)) return '/iniciar-sesion';
  ```

### Punto 17: Acceso Directo a Módulos Privados en el Backend
- **Verificación:** Si un atacante o cliente HTTP intenta acceder directamente a `GET /api/v1/loads/my` o `POST /api/v1/loads` omitiendo la cabecera `Authorization: Bearer <token>`:
- **Resultado:** Spring Security intercepta la petición a través del filtro `BearerTokenAuthenticationFilter` y devuelve `HTTP 401 Unauthorized` de forma inmediata. La seguridad está garantizada en el backend y no depende de la interfaz gráfica.

### Punto 18: Recuperación de Contraseña
- **Diagnóstico:** El sistema no cuenta con endpoint de autoservicio para recuperación de contraseña (*password reset*). En la arquitectura de Fase 1/2 y en el documento de decisiones (`docs/DECISIONES.md`), la recuperación de credenciales está clasificada como requerimiento fuera del alcance del MVP y planificada para la fase de producción con proveedor SMTP transaccional.

### Punto 19: Registro de Usuarios
- **Endpoint:** `POST /api/v1/auth/register`.
- **Perfiles Admitidos:** `SHIPPER` (Empresa generadora), `DRIVER` (Conductor autónomo), `CARRIER` / `LEGALIZER` (Empresa transportadora).
- **Validaciones:** Contraseña mínima de 8 caracteres, nombre no vacío, formato de correo válido y aceptación explícita de términos de prueba (`testNoticeAccepted: true`).

### Punto 20: Activación de Cuenta mediante Correo (Mailpit)
- **Flujo Verificado:**
  1. Registro exitoso genera un token criptográfico de 32 bytes (`createRawToken()`).
  2. El hash SHA-256 del token se inserta en `email_verification_tokens`.
  3. Spring Boot envía un correo mediante `JavaMailSender` al servidor Mailpit en `localhost:1025`.
  4. En Mailpit (`http://localhost:8025`), se inspecciona el mensaje con asunto `"Verifica tu correo de TRAXIA (prueba local)"` y enlace `http://localhost:5000/verificar-correo?token=dmUZxoZHyGI0upbhkLUXkuJnzJhPOREzBCxLt8JtCgA`.
  5. Se ejecuta `POST /api/v1/auth/verify-email` con el token recibido.
  6. El sistema consume el token (`consumed_at_utc = now()`), actualiza el usuario a `ACTIVE` con estampa `email_verified_at_utc` y registra el evento en `audit_events`.
  7. Si se intenta reutilizar el enlace, el sistema rechaza la solicitud con `HTTP 400 Bad Request: "El enlace de verificación venció o ya fue utilizado."`
