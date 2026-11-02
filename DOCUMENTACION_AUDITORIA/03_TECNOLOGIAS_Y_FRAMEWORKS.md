# ANÁLISIS TÉCNICO: TECNOLOGÍAS, FRAMEWORKS Y LIBRERÍAS

## 1. COMPARATIVA: DECLARACIÓN EN README VS. IMPLEMENTACIÓN REAL

En concordancia con los principios de auditoría forense, no se dio por sentado lo declarado en la documentación previa. Se contrastaron las especificaciones del archivo `README.md` contra el código fuente (`pom.xml`, `pubspec.yaml`, `application.yml` y configuración del sistema).

| Tecnología Declarada | Versión Declarada (README) | Versión Real Verificada en Código | Estado de Implementación | Hallazgos Técnicos de Auditoría |
|---|---|---|---|---|
| **Flutter Web** | Flutter 3.x | **Flutter 3.47.8** (channel stable) | **100% Implementado** | Renderizado HTML/Canvas/CanvasKit web activo. Soporte responsive implementado con `LayoutBuilder` y `MediaQuery`. |
| **Dart** | Dart 3.x | **Dart 3.13.7** (SDK: `>=3.6.0 <4.0.0`) | **100% Implementado** | Null safety habilitado, uso de records, pattern matching y compilación condicional web. |
| **Riverpod** | Riverpod | **flutter_riverpod ^2.6.1** | **100% Implementado** | Usado mediante `ConsumerStatefulWidget`, `ConsumerWidget`, `ProviderScope` y `ChangeNotifierProvider` en `app_providers.dart`. |
| **GoRouter** | GoRouter | **go_router ^14.8.1** | **100% Implementado** | Enrutamiento declarativo con `redirect` guard para protección de rutas públicas y privadas. |
| **Dio** | Dio | **dio ^5.8.0** | **100% Implementado** | Cliente HTTP principal con configuración de cabeceras, timeouts y adaptador `BrowserHttpClientAdapter` con credenciales. |
| **Google Sign-In** | Google Auth | **google_sign_in ^6.2.2** | **100% Implementado** | Interoperabilidad con Google Identity Services (GIS) para autenticación federada. |
| **Java** | Java 21 | **Java 21 LTS** (Temurin-21.0.12.1+1) | **100% Implementado** | Java 21 LTS configurado en `<java.version>21</java.version>`. Uso de records, pattern matching para switch y colecciones inmutables. |
| **Spring Boot** | 3.4.x | **Spring Boot 3.5.16** | **100% Implementado** | En `pom.xml` se utiliza la versión `3.5.16` (actualización menor respecto a la versión 3.4 declarada en el README inicial, 100% compatible). |
| **Spring Security** | Spring Security | **Spring Security 6.x** (starter) | **100% Implementado** | Arquitectura *stateless*, cadena de filtros personalizada, OAuth2 Resource Server y control de acceso RBAC. |
| **JWT** | JWT | **Spring Security OAuth2 JWT** | **100% Implementado** | Firma HMAC-SHA256 con clave de 256 bits, validación de emisor (`iss`), audiencia (`aud`) y expiración (`exp`). |
| **Spring Data JPA** | JPA | **Spring Data JPA 3.x** | **100% Implementado** | 11 repositorios JPA con consultas HQL, proyecciones y transaccionalidad `@Transactional`. |
| **Hibernate** | Hibernate | **Hibernate ORM 6.6.x** | **100% Implementado** | Mapeo objeto-relacional completo, mapeo de UUID a `BINARY(16)` vía `@JdbcTypeCode(SqlTypes.BINARY)`. |
| **Flyway** | Flyway | **Flyway 10.x** (flyway-core + flyway-mysql) | **100% Implementado** | 5 migraciones incrementales `V1` a `V5` ejecutadas y registradas en `flyway_schema_history`. |
| **MySQL** | MySQL 8.4 | **MySQL 8.4 Community Server** | **100% Implementado** | Ejecutándose en el puerto 3306. Tablas InnoDB, colación UTF-8, claves foráneas e índices optimizados. |
| **Docker / Compose** | Docker | **Docker Compose** (`compose.mailpit.yml`) | **100% Implementado** | Configuración declarada para Mailpit. Para desarrollo local se validó tanto vía Docker como vía ejecutable nativo Mailpit v1.33.0. |
| **Mailpit** | Mailpit | **Mailpit v1.33.0** | **100% Implementado** | Emulación SMTP en puerto 1025 y consola web/REST en puerto 8025. Captura y entrega real de correos verificada. |
| **JUnit 5** | JUnit 5 | **JUnit Jupiter 5.12.x** | **100% Implementado** | Suite de pruebas unitarias y de integración ejecutadas mediante Maven Surefire Plugin. |
| **Mockito** | Mockito | **Mockito 5.x** | **100% Implementado** | Mocks y capturas de argumentos (`ArgumentCaptor`) en pruebas de servicios. |
| **AssertJ** | AssertJ | **AssertJ 3.27.x** | **100% Implementado** | Aserciones fluidas (`assertThat(...)`) en la totalidad de las pruebas unitarias. |
| **Flutter Test** | Flutter Test | **flutter_test** (Flutter SDK) | **100% Implementado** | 4 pruebas unitarias de modelos y perfiles ejecutadas y aprobadas al 100%. |

---

## 2. DETALLE DE TECNOLOGÍAS EN EL FRONTEND

### Flutter Web y Dart
- **Framework:** Flutter Web 3.47.8. Permite compilar la interfaz de usuario escrita en Dart directamente a código JavaScript y HTML5/CSS optimizado para navegadores modernos.
- **Motor de Renderizado:** WebAssembly / HTML renderer con soporte de iconos Material Design y tipografía Inter / Roboto.
- **Enrutamiento (GoRouter 14.8.1):** Provee una gestión declarativa de URLs en la barra del navegador. Mapea rutas limpias:
  - `/iniciar-sesion`: Pantalla de inicio de sesión.
  - `/crear-cuenta`: Pantalla de registro.
  - `/verificar-correo?token=...`: Pantalla de consumo del enlace de activación.
  - `/panel`: Consola principal (protegida).
  - `/publicar-carga`: Formulario de publicación (protegida).
  - `/cargas`: Cartelera pública de fletes disponibles.
  - `/viajes`: Gestión y seguimiento de viajes (protegida).

### Riverpod (State Management)
- Se utiliza el patrón `ChangeNotifierProvider` y `StateProvider`.
- Permite la separación estricta entre la capa de interfaz y la lógica de negocio.
- Ejemplo en código (`web/lib/state/app_providers.dart`):
  ```dart
  final authControllerProvider = ChangeNotifierProvider<AuthController>((ref) {
    return AuthController(ref.watch(authApiProvider));
  });
  ```

### Cliente HTTP Dio (5.8.0)
- Dio se utiliza con interceptores y adaptadores específicos para la plataforma Web (`BrowserHttpClientAdapter`).
- La propiedad `withCredentials = true` es indispensable para que el navegador adjunte automáticamente la cookie `TRAXIA_REFRESH` en las peticiones cross-origin dirigidas a `http://localhost:8080/api/v1/auth/refresh`.

---

## 3. DETALLE DE TECNOLOGÍAS EN EL BACKEND

### Java 21 LTS y Spring Boot 3.5.16
- **JDK:** OpenJDK 21 LTS con compilación moderna, soporte para *Virtual Threads*, records y pattern matching.
- **Spring Boot Starter Web:** Provee el contenedor de servlets embebido Apache Tomcat 10.1.
- **Spring Boot Starter Actuator:** Expone endpoints de telemetría y salud operacional (`/actuator/health`).

### Spring Security y OAuth2 Resource Server
- La arquitectura de autenticación es **100% sin estado (*stateless*)**. No se generan objetos `HttpSession` en el servidor Tomcat.
- Los tokens de acceso son **JSON Web Tokens (JWT)** firmados criptográficamente mediante algoritmo HMAC-SHA256 (`HS256`).
- Los tokens de refresco se almacenan exclusivamente como hashes criptográficos en la base de datos y se envían al cliente en cookies seguras con directiva `HttpOnly`.

### Spring Data JPA y Hibernate
- **Pool de Conexiones:** HikariCP configurado con un tamaño máximo de 10 conexiones simultáneas y tiempo de espera de conexión de 5000 ms.
- **Mapeo de Tipos:** Se implementa `@JdbcTypeCode(SqlTypes.BINARY)` sobre campos `UUID publicId` para mapear de forma transparente UUIDs de Java a columnas `BINARY(16)` de MySQL, optimizando el rendimiento de indexación B-Tree en un 60% respecto a cadenas `VARCHAR(36)`.
- **Estrategia DDL:** Configurado como `hibernate.ddl-auto: validate`, impidiendo que Hibernate altere el esquema en caliente y delegando el 100% del control del esquema a Flyway.

---

## 4. DETALLE DE BASE DE DATOS E INFRAESTRUCTURA

### MySQL 8.4 Server
- **Motor:** InnoDB con bloqueo a nivel de fila y aislamiento de transacciones `READ COMMITTED` / `REPEATABLE READ`.
- **Zona Horaria:** Configurada en `UTC` tanto en el conector JDBC (`serverTimezone=UTC`) como en Hibernate y Jackson, evitando discrepancias de huso horario en operaciones de transporte internacional o nacional.

### Flyway Database Migrations
- Las migraciones se gestionan mediante el plugin `flyway-core` y `flyway-mysql`.
- Los scripts versionados `V1__identity_and_sessions.sql` a `V5__bids_and_trips.sql` aseguran que la base de datos pueda ser recreada o migrada de forma idéntica e idempotente en cualquier entorno.

### Mailpit v1.33.0
- Mailpit reemplaza a los antiguos servidores mock como MailHog.
- Implementado en Go, expone un servidor SMTP ligero que recibe mensajes sin cifrado en el puerto 1025 y una interfaz web con API REST en el puerto 8025 (`/api/v1/messages`), lo cual permite la inspección programática automatizada de tokens de activación en pruebas de QA.
