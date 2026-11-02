# MATRIZ DE PRUEBAS Y CONTROL DE CALIDAD (QA)

## 1. RESUMEN DE EJECUCIÓN DE PRUEBAS

| Categoría de Pruebas | Herramienta / Runner | Pruebas Ejecutadas | Aprobadas | Fallidas | Omitidas | Tasa de Éxito |
|---|---|---|---|---|---|---|
| **Pruebas Unitarias Backend** | JUnit 5 + Mockito + AssertJ | 25 | 25 | 0 | 0 | **100%** |
| **Pruebas Contenedor BD** | Testcontainers MySQL 8.4 | 5 | 0 | 0 | 5* | **Omitidas por diseño** |
| **Pruebas Unitarias Frontend** | Flutter Test | 4 | 4 | 0 | 0 | **100%** |
| **Análisis Estático Frontend** | `flutter analyze` | 1 | 1 | 0 | 0 | **100% (0 issues)** |
| **Pruebas E2E / Funcionales API** | PowerShell REST Harness | 18 | 18 | 0 | 0 | **100%** |
| **Total Global** | — | **53** | **48** | **0** | **5** | **100% de aplicables** |

*\*Nota técnica:* Las 5 pruebas de `MySqlAuthenticationSchemaTest` están anotadas con `@Testcontainers(disabledWithoutDocker = true)`. Se omiten de forma estándar y esperada cuando el daemon de Docker no está activo en el entorno local de ejecución, garantizando que el pipeline de construcción continúe exitoso.

---

## 2. MATRIZ DETALLADA DE PRUEBAS DE LABORATORIO

| ID Prueba | Módulo | Nivel | Descripción del Escenario | Entradas / Acciones | Resultado Esperado | Resultado Real Verificado | Estado |
|---|---|---|---|---|---|---|---|
| **TC-BE-01** | Seguridad | Unitario | Emisión de Access Token JWT | `AccessTokenService.issue(...)` con roles | JWT firmado con claims válidos y TTL 600s | Token emitido y claims comprobados | **APROBADO** |
| **TC-BE-02** | Seguridad | Unitario | Validación de firma y revocación JWT | Decodificación de token expirado o corrupto | `JwtValidationException` | Lanzada adecuadamente | **APROBADO** |
| **TC-BE-03** | Seguridad | Unitario | Filtrado de roles globales | `GlobalRolePolicy.filter(["SHIPPER", "INVALID"])` | Devuelve solo roles válidos del catálogo | Solo `"SHIPPER"` retornado | **APROBADO** |
| **TC-BE-04** | Seguridad | Unitario | Denegación de cookie insegura en producción | Instanciar `AuthController` con `production` y `secure=false` | `IllegalStateException` exigiendo Secure | Excepción lanzada | **APROBADO** |
| **TC-BE-05** | Seguridad | Unitario | Aceptación de cookie en entorno local | Instanciar `AuthController` con `local` y `secure=false` | No lanza excepción | Constructor ejecuta sin error | **APROBADO** |
| **TC-BE-06** | Identidad | Unitario | Validación de DTOs de autenticación | Validar `RegisterRequest` con contraseña < 8 car. | Error de validación en Bean Validation | Violación de restricción detectada | **APROBADO** |
| **TC-BE-07** | Identidad | Unitario | Rotación exitosa de Refresh Token | `RefreshSessionService.rotate(tokenValido)` | Emite nuevo token y revoca el anterior | Nuevo token emitido, anterior revocado | **APROBADO** |
| **TC-BE-08** | Identidad | Unitario | Detección de reuso de token (Family Revocation) | Reutilizar un token de refresco ya rotado | Invalida a toda la familia (`family_id`) | Familia revocada en su totalidad | **APROBADO** |
| **TC-BE-09** | Identidad | Unitario | Registro genera token de verificación | `RegistrationService.register(request)` | Crea usuario `PENDING_VERIFICATION` y envía correo | Cuenta pendiente y token hash guardado | **APROBADO** |
| **TC-BE-10** | Identidad | Unitario | Correo duplicado en registro | Registrar correo previamente existente | Lanza `EmailAlreadyRegisteredException` | Excepción lanzada con HTTP 409 | **APROBADO** |
| **TC-BE-11** | Identidad | Unitario | Verificación de correo y activación | `RegistrationService.verifyEmail(rawToken)` | Activa `UserEntity` y `AuthMethodEntity` a `ACTIVE` | Ambos componentes pasan a `ACTIVE` | **APROBADO** |
| **TC-BE-12** | Identidad | Unitario | Registro denegado fuera de entornos autorizados | `RegistrationService.register` en `production` | Lanza `RegistrationDisabledException` | Bloqueado exitosamente | **APROBADO** |
| **TC-BE-13** | Identidad | Unitario | Carga de `TraxiaUserDetails` | `TraxiaUserDetailsService.loadUserByUsername` | Construye principal con roles y estado `enabled` | Principal generado correctamente | **APROBADO** |
| **TC-BE-14** | Subastas | Unitario | Prohibición de autopostulación | Generador intenta ofertar en su propia carga | Lanza `IllegalArgumentException` | Denegado en servicio | **APROBADO** |
| **TC-BE-15** | Subastas | Unitario | Aceptación de oferta y rechazo de restantes | `BidAndTripService.acceptBid(bidId, pubId)` | Oferta `ACCEPTED`, carga `ASSIGNED`, demás `REJECTED` | Estados actualizados y viaje creado | **APROBADO** |
| **TC-BE-16** | Cargas | Unitario | Creación de flete por empresa activa | `LoadService.createLoad(...)` con cuenta `ACTIVE` | Persiste `LoadEntity` con estado `PUBLISHED` | Carga creada con UUID público | **APROBADO** |
| **TC-FE-01** | Frontend | Unitario | Perfiles aprobados de usuario | `account_profile_test.dart` | Verifica perfiles `SHIPPER`, `DRIVER`, `LEGALIZER` | 3 perfiles validados | **APROBADO** |
| **TC-FE-02** | Frontend | Unitario | Parseo de respuesta de autenticación | `auth_models_test.dart` | Mapea JSON de backend a `AuthResponse` | Modelos creados con éxito | **APROBADO** |
| **TC-FE-03** | Frontend | Unitario | Rechazo de roles mal formados | `auth_models_test.dart` con roles inválidos | No admite roles desconocidos | Excepción de formato capturada | **APROBADO** |
| **TC-FE-04** | Frontend | Unitario | Serialización y deserialización de LoadModel | `loads_models_test.dart` | Comprueba `toJson()` y `fromJson()` | Serialización bidireccional exacta | **APROBADO** |
| **TC-E2E-01** | Actuator | Integración | Verificación de salud del backend | `GET /actuator/health` | `HTTP 200 {"status": "UP"}` | `status: UP` verificado | **APROBADO** |
| **TC-E2E-02** | Login | Integración | Validación de campos en login | `POST /login` con email y clave vacíos | `HTTP 400 Bad Request` | `HTTP 400` retornado | **APROBADO** |
| **TC-E2E-03** | Login | Integración | Credenciales incorrectas | `POST /login` con clave errónea | `HTTP 401 Unauthorized` | `HTTP 401` retornado | **APROBADO** |
| **TC-E2E-04** | Login | Integración | Usuario no verificado | `POST /login` con usuario `PENDING_VERIFICATION` | `HTTP 401 Unauthorized` | Rechazado hasta activación | **APROBADO** |
| **TC-E2E-05** | Seguridad | Integración | Protección contra fuerza bruta (Rate Limit) | 6 intentos fallidos consecutivos | Intento 6 bloqueado con `HTTP 429` | `HTTP 429` verificado | **APROBADO** |
| **TC-E2E-06** | Registro | Integración | Registro de nueva empresa generadora | `POST /register` datos válidos | `HTTP 200 OK` + JWT + Cookie HttpOnly | Credenciales y sesión creadas | **APROBADO** |
| **TC-E2E-07** | Mailpit | Integración | Entrega de correo de activación SMTP | Inspeccionar `http://localhost:8025/api/v1/messages` | Correo capturado con token de verificación | Mensaje e hipervínculo confirmados | **APROBADO** |
| **TC-E2E-08** | Activación | Integración | Consumo de token de verificación | `POST /verify-email` con token extraído | `HTTP 200 "Correo verificado."` | Cuenta activada en MySQL | **APROBADO** |
| **TC-E2E-09** | Activación | Integración | Protección contra reutilización de token | Segundo `POST /verify-email` con mismo token | `HTTP 400 Enlace vencido o utilizado` | Rechazo con `HTTP 400` | **APROBADO** |
| **TC-E2E-10** | Login | Integración | Login exitoso de empresa activada | `POST /login` credenciales válidas | `HTTP 200 OK` + Token + Cookie | Sesión abierta | **APROBADO** |
| **TC-E2E-11** | Sesiones | Integración | Rotación de Refresh Token vía Cookie | `POST /refresh` con Cookie y cabecera CSRF | `HTTP 200 OK` + Nuevo Access Token + Nueva Cookie | Rotación transparente | **APROBADO** |
| **TC-E2E-12** | Sesiones | Integración | Cierre de sesión y revocación | `POST /logout` | `HTTP 204 No Content` + Cookie Max-Age=0 | Sesión invalidada en BD | **APROBADO** |
| **TC-E2E-13** | Seguridad | Integración | Acceso a rutas privadas sin token | `GET /api/v1/loads/my` sin cabecera Bearer | `HTTP 401 Unauthorized` | Acceso denegado | **APROBADO** |
| **TC-E2E-14** | Cargas | Integración | Publicación de flete por empresa | `POST /api/v1/loads` Bogotá -> Medellín | `HTTP 201 Created` con estado `PUBLISHED` | Carga guardada en MySQL | **APROBADO** |
| **TC-E2E-15** | Cartelera | Integración | Búsqueda y filtrado de cargas | `GET /api/v1/loads?originCity=Bogota` | Lista con la carga recién publicada | 1 carga retornada | **APROBADO** |
| **TC-E2E-16** | Simulación | Integración | Cálculo del Gemelo Digital | `GET /api/v1/loads/{id}/simulate` | 420 km, 5 peajes (\$72.500), 35 gal (\$367.500) | Cálculos matemáticos idénticos | **APROBADO** |
| **TC-E2E-17** | Subastas | Integración | Postulación de conductores y adjudicación | Conductor 1 y 2 ofertan; empresa acepta C1 | C1 `ACCEPTED`, C2 `REJECTED`, Viaje `ASSIGNED` | Adjudicación atómica en BD | **APROBADO** |
| **TC-E2E-18** | Viajes | Integración | Ciclo de vida completo del viaje | Conductor inicia y luego entrega viaje | `ASSIGNED` $\rightarrow$ `IN_TRANSIT` $\rightarrow$ `DELIVERED` | Viaje y carga marcados `DELIVERED` | **APROBADO** |
