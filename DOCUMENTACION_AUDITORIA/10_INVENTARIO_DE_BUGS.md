# INVENTARIO DETALLADO DE BUGS Y ANOMALÍAS

## 1. CLASIFICACIÓN DE SEVERIDAD

Los defectos detectados durante la auditoría forense del código fuente de TRAXIA se clasifican según los estándares de la industria (IEEE 1044 / OWASP):
- **CRÍTICO:** Vulnerabilidades de ciberseguridad que exponen credenciales o sesiones, o errores que rompen la compilación y ejecución del sistema en producción.
- **ALTO:** Inconsistencias funcionales en las reglas de negocio o transacciones incompletas que degradan la integridad del sistema.
- **MEDIO:** Errores de configuración de frameworks, inyección de dependencias o ambigüedades en constructores que pueden provocar caídas en el arranque de servicios.
- **BAJO:** Violaciones de estándares de estilo, advertencias de linter o variables no utilizadas que no interrumpen el flujo principal pero degradan la calidad del código.

---

## 2. TABLA CONSOLIDADAS DE BUGS ENCONTRADOS

| ID Bug | Severidad | Módulo Afectado | Archivo Involucrado | Línea(s) | Resumen del Defecto | Estado |
|---|---|---|---|---|---|---|
| **BUG-001** | **CRÍTICO** | Ciberseguridad / Sesiones | `backend/src/main/java/com/traxia/identity/api/AuthController.java` | 42-43 | Exclusión indebida de la directiva `Secure` en cookies de refresco para entornos productivos. | **CORREGIDO Y VERIFICADO** |
| **BUG-002** | **CRÍTICO** | Identidad / Pruebas | `backend/src/main/java/com/traxia/identity/application/RegistrationService.java` | 31-32, 95 | Inclusión de `"production"` en entornos permitidos para autoregistro, causando `NullPointerException` en pruebas unitarias. | **CORREGIDO Y VERIFICADO** |
| **BUG-003** | **ALTO** | Identidad / Activación | `backend/src/main/java/com/traxia/identity/application/RegistrationService.java` | 134-138 | Omitida la activación de la credencial (`authMethod.verify`) al verificar el correo mediante token. | **CORREGIDO Y VERIFICADO** |
| **BUG-004** | **MEDIO** | Inyección de Dependencias | `backend/src/main/java/com/traxia/identity/application/RegistrationService.java` | 60-70 | Ausencia de `@Autowired` ante constructores sobrecargados en Spring Boot, impidiendo el arranque del servicio. | **CORREGIDO Y VERIFICADO** |
| **BUG-005** | **BAJO** | Calidad Frontend / Linter | `web/lib/screens/create_account_screen.dart` | 107 | Variable local `user` declarada y nunca utilizada, provocando fallo en `flutter analyze`. | **CORREGIDO Y VERIFICADO** |

---

## 3. FICHA TÉCNICA DE CADA DEFECTO

---

### BUG-001: Vulnerabilidad de Exposición de Cookie de Sesión No Segura en Producción
- **Severidad:** **CRÍTICO** (CWE-614: *Sensitive Cookie in HTTPS Session Without 'Secure' Attribute*).
- **Archivo:** `backend/src/main/java/com/traxia/identity/api/AuthController.java`.
- **Descripción:** En la definición del conjunto de entornos no productivos:
  ```java
  private static final Set<String> NON_PRODUCTION_ENVIRONMENTS =
          Set.of("local", "development", "dev", "test", "production");
  ```
  Se había incorporado el valor `"production"`.
- **Causa Raíz:** Se relajó la validación para facilitar un despliegue temporal en la nube (Render) sin configurar certificados SSL/TLS.
- **Impacto de Seguridad:** Al considerar a `production` como entorno no productivo, el servidor permitía emitir cookies de sesión `TRAXIA_REFRESH` sobre HTTP sin el atributo `Secure`. Un atacante en la misma red podía interceptar la cookie de refresco mediante un ataque *Man-in-the-Middle* (MITM) y secuestrar la sesión del usuario indefinidamente. Asimismo, provocaba el fallo de la prueba `AuthControllerTest.rejectsInsecureRefreshCookieOutsideLocalAndTestEnvironments`.
- **Acción Correctiva:** Eliminación de `"production"` de la lista `NON_PRODUCTION_ENVIRONMENTS`.

---

### BUG-002: Inconsistencia en Entornos de Autoregistro y NullPointerException
- **Severidad:** **CRÍTICO**.
- **Archivo:** `backend/src/main/java/com/traxia/identity/application/RegistrationService.java`.
- **Descripción:** La constante `ALLOWED_ENVIRONMENTS` contenía `"production"`. Cuando se probaba el caso de prueba unitario `refusesRegistrationWhenDisabledOrOutsideDevelopment`, el servicio no rechazaba la solicitud con `RegistrationDisabledException`, sino que continuaba hasta ejecutar `user.getAuthMethods().add(authMethod)`. Como `user` era un mock no configurado que devolvía `null`, el código arrojaba un `NullPointerException` no controlado.
- **Causa Raíz:** Mezcla de requerimientos de despliegue en Vercel/Render con las invariantes de diseño arquitectónico de Fase 2.
- **Impacto:** Falla de construcción del proyecto (`BUILD FAILURE` en Maven) y exposición de endpoints de registro en entornos donde debían estar deshabilitados.
- **Acción Correctiva:** Se restringió `ALLOWED_ENVIRONMENTS` exclusivamente a `"local", "development", "dev", "test"`, y se agregó protección contra nulos en `user.getAuthMethods()`.

---

### BUG-003: Inconsistencia de Activación de Credenciales en Verificación de Correo
- **Severidad:** **ALTO**.
- **Archivo:** `backend/src/main/java/com/traxia/identity/application/RegistrationService.java`.
- **Descripción:** Al invocar el método `verifyEmail(rawToken)`, el método marcaba el usuario como `ACTIVE` (`user.verifyEmail(now)`), pero omitía invocar la verificación sobre los métodos de autenticación asociados (`authMethod.verify(now)`).
- **Causa Raíz:** En una edición previa se eliminó la línea que iteraba y activaba los métodos de autenticación, asumiendo erróneamente que bastaba con activar la entidad `UserEntity`.
- **Impacto:** Si un usuario verificaba su correo a través del flujo formal de enlace SMTP, su `AuthMethod` permanecía en estado `PENDING_VERIFICATION`. Por ende, al intentar iniciar sesión, `TraxiaUserDetailsService` filtraba los métodos no activos y consideraba que la cuenta no tenía credenciales válidas (`passwordHash` vacío), bloqueando el acceso al usuario recién verificado.
- **Acción Correctiva:** Se restauró la activación de todas las credenciales asociadas al usuario dentro del método transaccional `verifyEmail`:
  ```java
  if (user.getAuthMethods() != null) {
      user.getAuthMethods().stream()
              .filter(method -> "EMAIL".equals(method.getProviderCode()) || "PASSWORD".equals(method.getProviderCode()))
              .forEach(method -> method.verify(now));
  }
  ```

---

### BUG-004: Inyección Ambigua de Constructores sin `@Autowired` en `RegistrationService`
- **Severidad:** **MEDIO**.
- **Archivo:** `backend/src/main/java/com/traxia/identity/application/RegistrationService.java`.
- **Descripción:** Al sobrecargar constructores para permitir pruebas unitarias con y sin el parámetro `autoActivate`, Spring Framework no podía inferir cuál de los dos constructores debía ser utilizado por el contenedor IoC (*Inversion of Control*), lanzando un `BeanInstantiationException: No default constructor found`.
- **Causa Raíz:** Regla de Spring Boot: si una clase `@Service` o `@Component` declara más de un constructor público, exactamente uno debe estar marcado con `@Autowired`.
- **Impacto:** Falla total en el arranque del servidor Tomcat al iniciar Spring Boot.
- **Acción Correctiva:** Se decoró el constructor principal de producción con `@org.springframework.beans.factory.annotation.Autowired`.

---

### BUG-005: Variable Local No Utilizada en Flutter (`create_account_screen.dart`)
- **Severidad:** **BAJO**.
- **Archivo:** `web/lib/screens/create_account_screen.dart` (Línea 107).
- **Descripción:** La sentencia `final user = ref.read(authControllerProvider).user;` definía una variable local `user` que no se referenciaba posteriormente en el bloque de código del diálogo de bienvenida.
- **Causa Raíz:** Fragmento de código residual de una refactorización de la pantalla de bienvenida.
- **Impacto:** `flutter analyze` reportaba una advertencia de linter (`unused_local_variable`), terminando el análisis estático con código de salida 1 (fallo de pipeline).
- **Acción Correctiva:** Eliminación de la línea huérfana. El análisis estático ahora reporta `No issues found!`.
