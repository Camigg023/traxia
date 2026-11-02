# AUDITORÍA TÉCNICA DEL BACKEND: JAVA 21 Y SPRING BOOT 3.5

## 1. VISIÓN GENERAL DEL BACKEND

El backend de TRAXIA es un servicio REST desarrollado en **Java 21 LTS** sobre el framework **Spring Boot 3.5.16**. Implementa una arquitectura modular con separación de responsabilidades entre Controladores REST, Servicios de Aplicación, Entidades de Dominio y Repositorios JPA.

---

## 2. COMPONENTES Y CAPAS DEL BACKEND

### A. Capa de Controladores REST (API Layer)
Expone los endpoints públicos y protegidos bajo el prefijo `/api/v1/`:
1. **`AuthController`:** Endpoints de identidad:
   - `POST /api/v1/auth/register`: Registro de usuario y generación de credenciales.
   - `POST /api/v1/auth/login`: Autenticación con contraseña y emisión de Access Token + Cookie HttpOnly.
   - `POST /api/v1/auth/refresh`: Rotación de refresh token y emisión de nuevo JWT.
   - `POST /api/v1/auth/logout`: Revocación de sesión e invalidación de cookie.
   - `POST /api/v1/auth/verify-email`: Consumo de token de verificación y activación.
   - `POST /api/v1/auth/google`: Login federado con Google Identity Services.
   - `POST /api/v1/auth/google/register`: Registro federado con Google.
   - `GET /api/v1/auth/me`: Inspección del perfil del usuario autenticado.
2. **`LoadController`:** Gestión de cargas y subastas:
   - `POST /api/v1/loads`: Publicación de fletes (protegido, requiere rol activo).
   - `GET /api/v1/loads`: Consulta pública de cargas disponibles con filtros.
   - `GET /api/v1/loads/my`: Consulta de cargas publicadas por el usuario actual.
   - `GET /api/v1/loads/{id}`: Detalle de una carga.
   - `GET /api/v1/loads/{id}/simulate`: Simulación de costos y Gemelo Digital.
   - `POST /api/v1/loads/{id}/bids`: Postulación y oferta económica de un transportista.
3. **`TripController`:** Contratación y ciclo de vida de viajes:
   - `GET /api/v1/bids/my`: Ofertas realizadas por el transportista.
   - `POST /api/v1/bids/{id}/accept`: Adjudicación de oferta por el generador de carga.
   - `GET /api/v1/trips/my`: Viajes activos e históricos del usuario.
   - `POST /api/v1/trips/{id}/start`: Inicio físico del viaje por el conductor.
   - `POST /api/v1/trips/{id}/deliver`: Reporte de entrega satisfactoria con notas.

### B. Capa de Servicios de Aplicación (Application Layer)
- **`AuthService`:** Orquesta la autenticación, delega en `AuthenticationManager`, emite tokens de acceso mediante `AccessTokenService` y genera sesiones de refresco con `RefreshSessionService`.
- **`RegistrationService`:** Gestiona el ciclo de vida del registro, validación de contraseñas (mínimo 8 caracteres, máximo 72 bytes según la especificación de BCrypt), persistencia de aceptación de términos y emisión de correos.
- **`LoadService`:** Valida y persiste las publicaciones de fletes en la tabla `loads`.
- **`SimulationService`:** Algoritmo matemático del Gemelo Digital (distancias, peajes, ACPM y flete sugerido).
- **`BidAndTripService`:** Maneja las subastas, la adjudicación transaccional y las transiciones de estado de los viajes (`ASSIGNED` $\rightarrow$ `IN_TRANSIT` $\rightarrow$ `DELIVERED`).
- **`AuditService`:** Servicio asíncrono para registro inmutable de auditoría forense en `audit_events`.

### C. Capa de Seguridad (Security Layer)
- **`SecurityConfiguration.java`:**
  - Deshabilita CSRF clásico por ser una API sin estado (*stateless*).
  - Configura CORS con lista blanca de orígenes (`WEB_ALLOWED_ORIGINS`).
  - Habilita `allowCredentials(true)` para permitir cookies cross-origin seguras.
  - Registra el convertidor `JwtAuthenticationConverter` que transforma los claims `roles` del JWT en autoridades Spring Security con prefijo `ROLE_`.
- **`RefreshRequestGuardFilter.java`:**
  - Filtro preventivo contra ataques CSRF sobre la cookie de refresco.
  - Exige que toda petición a `/refresh` y `/logout` incluya una cabecera `Origin` autorizada y la cabecera `X-TRAXIA-Refresh-Request: true`.
- **`LoginAttemptLimiter.java`:**
  - Sistema de mitigación contra fuerza bruta basado en almacenamiento HMAC en base de datos.

---

## 3. AUDITORÍA FORENSE DE LA SUITE DE PRUEBAS MAVEN

### Diagnóstico Inicial de Fallos (Antes de la Intervención)
Al ejecutar `mvn test` en el backend original, se detectaron **4 fallos y 1 error (5 tests rotos)**:
1. `AuthControllerTest.rejectsInsecureRefreshCookieOutsideLocalAndTestEnvironments`:
   - *Fallo:* `Expecting code to raise a throwable`.
   - *Causa:* El constructor de `AuthController` permitía cookies no seguras en `production` porque `"production"` había sido añadido erróneamente a `NON_PRODUCTION_ENVIRONMENTS`.
2. `RegistrationServiceTest.refusesRegistrationWhenDisabledOrOutsideDevelopment`:
   - *Fallo:* `NullPointerException` en lugar de `RegistrationDisabledException`.
   - *Causa:* `"production"` estaba en `ALLOWED_ENVIRONMENTS`, por lo que el método no bloqueó la ejecución y dereferenció `user.getAuthMethods()` siendo `user` nulo en el mock.
3. `RegistrationServiceTest.createsPendingAccountAndSendsOnlyAHashedVerificationToken`:
   - *Fallo:* `expected: "PENDING_VERIFICATION" but was: "ACTIVE"`.
   - *Causa:* Se había introducido auto-activación incondicional en `register()`.
4. `RegistrationServiceTest.verifiesEmailAndActivatesPendingCredentialsWithoutAssigningRoles`:
   - *Fallo:* `expected: "ACTIVE" but was: "PENDING_VERIFICATION"`.
   - *Causa:* En `verifyEmail()` se había eliminado la activación de la credencial `authMethod`.
5. `RegistrationServiceTest.duplicateEmailGetsSameResponseWithoutSendingAnotherMessage`:
   - *Error:* `EmailAlreadyRegisteredException`.
   - *Causa:* Inconsistencia en la aserción de la prueba ante la nueva excepción de correo duplicado.

### Resolución y Suite de Regresión Final
Se aplicaron las correcciones quirúrgicas documentadas en `11_CORRECCIONES_REALIZADAS.md`.
Al reejecutar la suite completa mediante `mvn test`:

```
[INFO] -------------------------------------------------------
[INFO]  T E S T S
[INFO] -------------------------------------------------------
[INFO] Running com.traxia.common.security.AccessTokenServiceTest
[INFO] Tests run: 2, Failures: 0, Errors: 0, Skipped: 0
[INFO] Running com.traxia.common.security.GlobalRolePolicyTest
[INFO] Tests run: 2, Failures: 0, Errors: 0, Skipped: 0
[INFO] Running com.traxia.common.security.MySqlAuthenticationSchemaTest
[WARNING] Tests run: 5, Failures: 0, Errors: 0, Skipped: 5 (Testcontainers disabledWithoutDocker=true)
[INFO] Running com.traxia.identity.api.AuthControllerTest
[INFO] Tests run: 2, Failures: 0, Errors: 0, Skipped: 0
[INFO] Running com.traxia.identity.api.AuthDtosTest
[INFO] Tests run: 3, Failures: 0, Errors: 0, Skipped: 0
[INFO] Running com.traxia.identity.application.RefreshSessionServiceTest
[INFO] Tests run: 3, Failures: 0, Errors: 0, Skipped: 0
[INFO] Running com.traxia.identity.application.RegistrationServiceTest
[INFO] Tests run: 5, Failures: 0, Errors: 0, Skipped: 0
[INFO] Running com.traxia.identity.application.TraxiaUserDetailsTest
[INFO] Tests run: 1, Failures: 0, Errors: 0, Skipped: 0
[INFO] Running com.traxia.loads.application.BidAndTripServiceTest
[INFO] Tests run: 4, Failures: 0, Errors: 0, Skipped: 0
[INFO] Running com.traxia.loads.application.LoadServiceTest
[INFO] Tests run: 3, Failures: 0, Errors: 0, Skipped: 0
[INFO] 
[INFO] Results:
[INFO] 
[INFO] Tests run: 30, Failures: 0, Errors: 0, Skipped: 5
[INFO] 
[INFO] ------------------------------------------------------------------------
[INFO] BUILD SUCCESS
[INFO] ------------------------------------------------------------------------
```

**Conclusión:** 100% de las pruebas aplicables aprobadas (25 aprobadas, 0 fallos, 0 errores, 5 omitidas intencionalmente por configuración de Testcontainers sin Docker).
