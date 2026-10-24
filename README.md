# TRAXIA - Plataforma Logística Inteligente para Colombia

TRAXIA es una plataforma web responsive diseñada para conectar de forma transparente y eficiente a generadores de carga (empresas e industrias), transportistas independientes (propietarios y conductores) y empresas de transporte en Colombia.

---

## 🛠️ Tecnologías Utilizadas

### Frontend
- **Framework:** [Flutter Web](https://flutter.dev/) (SDK 3.24+).
- **Lenguaje:** Dart.
- **Diseño & UI:** Responsive Web (optimizado para navegación en escritorio, tabletas y móviles sin necesidad de apps nativas).
- **Gestión de Estado:** Riverpod.
- **Enrutamiento:** GoRouter con guardias de navegación y protección de sesión.
- **Cliente HTTP:** Dio (configurado con soporte web para credenciales y cookies `HttpOnly`).

### Backend
- **Framework:** [Java 21 LTS](https://adoptium.net/) + [Spring Boot 3.4.x](https://spring.io/projects/spring-boot).
- **Arquitectura:** Monolito Modular guiado por el dominio (Domain-Driven Design - DDD).
- **Seguridad:** Spring Security con autenticación Stateless mediante JWT (JSON Web Tokens), Refresh Tokens en cookies `HttpOnly` y protección contra ataques de fuerza bruta (Rate Limiting con HMAC y ventanas de bloqueo).
- **Persistencia:** Spring Data JPA + Hibernate ORM.
- **Migraciones de Base de Datos:** Flyway (migraciones versionadas `V1` a `V5`).
- **Pruebas Automatizadas:** JUnit 5, Mockito, AssertJ.

### Base de Datos e Infraestructura Local
- **Base de Datos:** MySQL 8.4 LTS (con soporte nativo para UUID binario `BINARY(16)` y collation UTF-8).
- **Servidor de Correo Local:** [Mailpit](https://github.com/axllent/mailpit) para pruebas de verificación de correo electrónico sin enviar emails reales.
- **Contenedores:** Docker Desktop / Docker Compose para servicios auxiliares.

---

## 🚀 Módulos Funcionales Implementados (MVP)

1. **Autenticación, Seguridad y Registro Local:**
   - Registro de usuarios con aviso de privacidad y flujo de activación por correo electrónico (Mailpit).
   - Manejo de sesiones seguras mediante JWT efímeros en memoria y Refresh Tokens rotatorios en cookies `HttpOnly`.
   - Límite de intentos de inicio de sesión por cuenta (máximo 5) y por dirección IP (máximo 30).
2. **Publicación y Cartelera de Cargas (§10 Documento Maestro):**
   - Asistente de publicación en 5 etapas: Origen, Destino, Características físicas de la mercancía, Requisitos de vehículo/carrocería y Esquema económico acordado.
   - Búsqueda en tiempo real de cargas disponibles con filtros por departamento y municipio.
3. **Gemelo Digital y Simulación de Costos de Ruta (§14 y §16):**
   - Cálculo determinístico de distancias (km) en corredores viales colombianos clave (Bogotá, Medellín, Cali, Barranquilla, Bucaramanga, Buenaventura).
   - Estimación de consumo de combustible diésel ACPM (a tarifa de referencia nacional de $10.500 COP/galón) según tipología de camión (Tractomula, Dobletroque, Sencillo, Turbo).
   - Estimación de costos de peajes de acuerdo a las casetas oficiales de cada corredor vial.
   - Flete sugerido de mercado con margen de contingencia y descargo de responsabilidad legal.
4. **Postulaciones y Ofertas de Flete (Bidding):**
   - Los transportistas pueden realizar contraofertas directas sobre las cargas publicadas indicando valor propuesto y fecha de recogida.
   - La empresa generadora puede revisar y aceptar una oferta, lo que asigna la carga (`ASSIGNED`) y descarta automáticamente las demás ofertas abiertas.
5. **Ejecución y Cierre de Viajes (Trips):**
   - Tablero de seguimiento para conductores y generadores.
   - Transiciones de estado operativas: `ASSIGNED` ➡️ `IN_TRANSIT` (inicio de viaje) ➡️ `DELIVERED` (registro de entrega a satisfacción con observaciones).

> **Nota sobre Pagos:** En esta versión MVP no se incluye pasarela de pagos electrónicos (Wompi, PSE o tarjetas); los acuerdos económicos y condiciones de liquidación se registran entre las partes de forma directa y contractual.

---

## 💻 Guía para Levantar el Proyecto Localmente

### Requisitos Previos
- **Java 21 LTS** (`java -version`).
- **Apache Maven 3.9+** (`mvn -version`).
- **Flutter SDK 3.24+** con soporte web habilitado (`flutter doctor`).
- **Docker Desktop** (para MySQL y Mailpit).
- **Google Chrome** u otro navegador moderno.

---

### Paso 1: Levantar Servicios Auxiliares (Base de Datos y Correo)

Asegúrate de que Docker Desktop esté en ejecución.

1. **Iniciar la base de datos MySQL 8.4:**
   Si tienes tu contenedor o servicio local de MySQL corriendo en el puerto `3306`, asegúrate de que la base de datos `traxia` exista:
   ```sql
   CREATE DATABASE IF NOT EXISTS traxia CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
   ```

2. **Iniciar Mailpit (Servidor de correo local de pruebas):**
   En la raíz del proyecto:
   ```powershell
   docker compose -f compose.mailpit.yml up -d
   ```
   *Bandeja web accesible en:* **`http://localhost:8025`**

---

### Paso 2: Ejecutar el Backend (Spring Boot)

1. En la raíz del repositorio, establece el límite de memoria para Maven y arranca la aplicación:
   ```powershell
   $env:MAVEN_OPTS = "-Xmx512m"
   mvn -f backend/pom.xml spring-boot:run
   ```
2. Flyway ejecutará automáticamente las migraciones `V1` a `V5` creando todas las tablas.
3. El backend quedará escuchando en: **`http://localhost:8080`**.
4. Puedes verificar su estado en: **`http://localhost:8080/actuator/health`** (debe responder `{"status":"UP"}`).

> **Ejecutar Pruebas del Backend:**
> ```powershell
> $env:MAVEN_OPTS = "-Xmx512m"
> mvn -f backend/pom.xml test -Dtest="!MySqlAuthenticationSchemaTest"
> ```

---

### Paso 3: Ejecutar el Frontend (Flutter Web)

1. En una nueva terminal, navega al directorio `web/`:
   ```powershell
   cd web
   ```
2. Descarga dependencias (si es primera vez):
   ```powershell
   flutter pub get
   ```
3. Ejecuta la aplicación en el puerto `5000` (puerto configurado para CORS en el backend):
   ```powershell
   flutter run -d chrome --web-port 5000
   ```
4. La aplicación web se abrirá automáticamente en tu navegador en: **`http://localhost:5000`**.

> **Ejecutar Pruebas del Frontend:**
> ```powershell
> cd web
> flutter test
> ```

---

## 🔄 Flujo de Prueba Rápido (Paso a Paso)

1. **Registro:** Ve a `http://localhost:5000/crear-cuenta` y registra un usuario (por ejemplo `generador@traxia.co`).
2. **Verificación de Correo:** Abre `http://localhost:8025`, busca el correo de activación y haz clic en el enlace.
3. **Inicio de Sesión:** Ingresa tus credenciales en `http://localhost:5000/iniciar-sesion`.
4. **Publicar Carga:** En el panel, presiona **"Nueva Carga"** y completa los 5 pasos con una ruta (ej. Bogotá ➡️ Medellín).
5. **Simulación y Oferta:** Ve a **"Cargas Disponibles"**, presiona **"Simular Ruta (Gemelo Digital)"** para ver los costos reales calculados y envía una postulación económica.
6. **Aceptar y Viajar:** Acepta la oferta y dirígete a **"Mis Viajes"** (`/viajes`) para iniciar el tránsito y registrar la entrega final.

---

## ☁️ Preparación para Despliegue en la Nube

- **Frontend:** Desplegable en [Vercel](https://vercel.com/) como aplicación web estática compilada con `flutter build web --release`.
- **Backend:** Desplegable en **Azure App Service** o **Azure Container Apps** mediante contenedor Docker con OpenJDK 21.
- **Base de Datos:** Compatible con **Azure Database for MySQL Flexible Server** inyectando las variables de entorno `MYSQL_HOST`, `MYSQL_USER`, `MYSQL_PASSWORD` y `MYSQL_DATABASE`.
