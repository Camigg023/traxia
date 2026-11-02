# GUÍA DE INSTALACIÓN, CONFIGURACIÓN Y EJECUCIÓN DEL SISTEMA TRAXIA

Esta guía técnica describe el procedimiento estándar, reproducible y validado para desplegar la plataforma **TRAXIA** (Backend Spring Boot, Frontend Flutter Web, Base de Datos MySQL y Servidor SMTP Mailpit) en un entorno de desarrollo local o estación de trabajo para auditoría y evaluación académica.

---

## 1. REQUISITOS PREVIOS DEL SISTEMA

Para ejecutar la solución de forma nativa en sistemas Windows (o adaptado a Linux/macOS), asegúrese de contar con las siguientes herramientas instaladas y configuradas en el `PATH` del sistema:

| Componente | Versión Comprobada | Propósito en el Proyecto | Comando de Verificación |
|---|---|---|---|
| **Java JDK** | OpenJDK 21 LTS (Temurin / Oracle) | Runtime del Backend Spring Boot | `java -version` |
| **Apache Maven** | 3.9.x o 3.10.x | Gestor de dependencias y compilación Java | `mvn -v` |
| **Flutter SDK** | 3.27.x o superior (Dart 3.6+) | Framework de Frontend Web | `flutter --version` |
| **MySQL Server** | 8.4.x LTS (o 8.0+) | Motor de Base de Datos Relacional | `mysql --version` |
| **Mailpit** | v1.20+ (v1.33.0 probado) | Servidor SMTP y visor de correos de prueba | `mailpit --version` |
| **Google Chrome** | Versión reciente | Navegador para ejecución y depuración Web | `chrome.exe --version` |

---

## 2. ARQUITECTURA DE VARIABLES DE ENTORNO

El backend de TRAXIA lee sus parámetros críticos a través de variables de entorno del sistema o del archivo `backend/src/main/resources/application.properties`.

Para el entorno local, se recomienda definir un archivo `.env.local` en la raíz del repositorio (`C:\Users\marti\Downloads\traxia-main\traxia-main\.env.local`) con la siguiente estructura:

```env
# ==========================================
# CONFIGURACIÓN DE BASE DE DATOS (MYSQL 8.4)
# ==========================================
MYSQL_HOST=localhost
MYSQL_PORT=3306
MYSQL_DATABASE=traxia
MYSQL_USER=root
MYSQL_PASSWORD=TuPasswordSeguro123*
MYSQL_SSL_MODE=DISABLED

# ==========================================
# CONFIGURACIÓN DE CORREO SMTP (MAILPIT)
# ==========================================
MAIL_HOST=localhost
MAIL_PORT=1025

# ==========================================
# CIBERSEGURIDAD Y CRIPTOGRAFÍA (BASE64)
# ==========================================
TRAXIA_ENVIRONMENT=local
TRAXIA_REGISTRATION_ENABLED=true
# Llave HMAC-SHA256 de 256 bits para firma de JWT (mínimo 32 bytes en Base64)
JWT_SIGNING_SECRET_BASE64=ztYCdfxBfLlQOqBwp+y3tCxWzxtM2nZ3BzX7Oon8EXU=
# Llave secreta para algoritmo HMAC de Rate Limiting por IP
AUTH_RATE_LIMIT_HMAC_SECRET_BASE64=8mgF93y761xNb9Lk2GRv1RQ1Z5AF4lav7jpBRkuI6hI=

# ==========================================
# OPCIONES DE MEMORIA JAVA
# ==========================================
MAVEN_OPTS=-Xmx512m
```

> [!NOTE]
> Para generar nuevas llaves criptográficas seguras de 256 bits en Base64 desde PowerShell, puede ejecutar:
> ```powershell
> [Convert]::ToBase64String((1..32 | ForEach-Object { Get-Random -Minimum 0 -Maximum 256 }))
> ```

---

## 3. PROCEDIMIENTO DE ARRANQUE PASO A PASO

Para garantizar la correcta inicialización de dependencias e integridad referencial, inicie los servicios en el siguiente orden estricto:

```
[1. MySQL 8.4] ---> [2. Mailpit SMTP] ---> [3. Backend Spring Boot] ---> [4. Frontend Flutter Web]
```

---

### PASO 1: Inicialización de la Base de Datos MySQL

1. Verifique que el servicio de MySQL esté en ejecución en el puerto 3306:
   ```powershell
   Get-Service -Name MySQL*
   ```
2. Asegúrese de que exista la base de datos `traxia`:
   ```sql
   CREATE DATABASE IF NOT EXISTS traxia CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
   ```
3. **No es necesario ejecutar scripts SQL manuales para crear las tablas**: La herramienta **Flyway** integrada en Spring Boot ejecutará automáticamente todas las migraciones incrementales (`V1__...` hasta `V5__...`) tan pronto inicie el backend.

---

### PASO 2: Inicialización del Servidor de Correo de Pruebas (Mailpit)

Mailpit intercepta todos los correos electrónicos de registro y confirmación generados por TRAXIA sin enviarlos a servidores reales de internet.

**Opción A: Ejecutable Nativo Independiente (Recomendado)**
Descargue el binario de Mailpit para Windows y ejecútelo en una terminal:
```powershell
& "C:\tools\mailpit\mailpit.exe"
```
Mailpit abrirá:
- **Puerto SMTP:** `1025` (recibe los correos enviados por Spring Boot).
- **Puerto HTTP Web UI:** `http://localhost:8025` (consola web para ver y abrir los correos).

**Opción B: Con Docker Compose**
Si dispone del motor Docker activo:
```bash
docker compose -f compose.mailpit.yml up -d
```

---

### PASO 3: Compilación y Ejecución del Backend (Spring Boot)

Abra una terminal PowerShell en el directorio del proyecto:

```powershell
cd C:\Users\marti\Downloads\traxia-main\traxia-main\backend

# Exportar las variables de entorno de conexión
$env:MYSQL_HOST = "localhost"
$env:MYSQL_PORT = "3306"
$env:MYSQL_DATABASE = "traxia"
$env:MYSQL_USER = "root"
$env:MYSQL_PASSWORD = "TuPasswordSeguro123*"
$env:MYSQL_SSL_MODE = "DISABLED"
$env:MAIL_HOST = "localhost"
$env:MAIL_PORT = "1025"
$env:TRAXIA_REGISTRATION_ENABLED = "true"
$env:TRAXIA_ENVIRONMENT = "local"
$env:JWT_SIGNING_SECRET_BASE64 = "ztYCdfxBfLlQOqBwp+y3tCxWzxtM2nZ3BzX7Oon8EXU="
$env:AUTH_RATE_LIMIT_HMAC_SECRET_BASE64 = "8mgF93y761xNb9Lk2GRv1RQ1Z5AF4lav7jpBRkuI6hI="
$env:MAVEN_OPTS = "-Xmx512m"

# Iniciar el backend con Maven
mvn spring-boot:run
```

**Comprobación de Salud del Backend:**
Una vez finalizado el arranque (aproximadamente 6 segundos), abra su navegador o ejecute:
```powershell
Invoke-RestMethod -Uri "http://localhost:8080/actuator/health"
```
**Respuesta esperada:**
```json
{
  "status": "UP"
}
```

---

### PASO 4: Compilación y Ejecución del Frontend (Flutter Web)

Abra una segunda terminal PowerShell:

```powershell
cd C:\Users\marti\Downloads\traxia-main\traxia-main\web

# Descargar las dependencias del proyecto Flutter
flutter pub get

# Ejecutar la aplicación web en el puerto 5000
flutter run -d chrome --web-port 5000
```
> [!TIP]
> Si prefiere iniciar el servidor web sin abrir automáticamente una nueva ventana de Chrome, use el dispositivo `web-server`:
> ```powershell
> flutter run -d web-server --web-port 5000 --web-hostname localhost
> ```

La aplicación estará accesible en su navegador en:
**`http://localhost:5000`**

---

## 4. MATRIZ DE SERVICIOS Y PUERTOS ACTIVOS

Al completar el arranque, el ecosistema de TRAXIA estará compuesto por los siguientes servicios en escucha:

| Servicio | Puerto Local | Protocolo | URL de Acceso / Interfaz |
|---|---|---|---|
| **Flutter Web UI** | `5000` | HTTP | `http://localhost:5000` (Pantalla de Login y Módulos) |
| **Spring Boot API** | `8080` | HTTP | `http://localhost:8080/api/v1/...` (Endpoints REST) |
| **Spring Actuator** | `8080` | HTTP | `http://localhost:8080/actuator/health` (Healthcheck) |
| **Mailpit Web UI** | `8025` | HTTP | `http://localhost:8025` (Bandeja de Entrada de Correos) |
| **Mailpit SMTP** | `1025` | SMTP | `localhost:1025` (Recepción de Mails del Backend) |
| **MySQL Database** | `3306` | TCP/MySQL | `localhost:3306/traxia` (Almacenamiento Persistente) |

---

## 5. USUARIOS Y CREDENCIALES DE PRUEBA VERIFICADAS

Para realizar pruebas completas de los flujos de negocio sin necesidad de registrar nuevos usuarios cada vez, puede utilizar las siguientes cuentas creadas y validadas en el entorno local:

### Perfil 1: Empresa Generadora de Carga (Shipper)
- **Correo Electrónico:** `empresa.colombia@traxia.local`
- **Contraseña:** `SecurePassword2026*`
- **Rol:** `SHIPPER` (Empresa)
- **Capacidades:** Publicar cargas en el asistente de 5 pasos, simular rutas y costos, visualizar ofertas recibidas, aceptar ofertas de transportistas.

### Perfil 2: Conductor / Transportista Principal (Driver)
- **Correo Electrónico:** `conductor.bogota@traxia.local`
- **Contraseña:** `SecurePassword2026*`
- **Rol:** `DRIVER` (Conductor)
- **Capacidades:** Consultar la cartelera de cargas disponibles, postular ofertas económicas sobre cargas publicadas, gestionar viajes adjudicados (iniciar tránsito, registrar entregas con novedades).

### Perfil 3: Conductor Secundario (Para Pruebas de Subasta y Concurrencia)
- **Correo Electrónico:** `conductor2@traxia.local`
- **Contraseña:** `SecurePassword2026*`
- **Rol:** `DRIVER` (Conductor)
- **Capacidades:** Postular contraofertas en competencia directa con el conductor principal para validar el rechazo automático de ofertas excedentes.

### Perfil 4: Usuario Personal
- **Correo Electrónico:** `martinmontoya.1247@gmail.com`
- **Contraseña:** `SecurePassword2026*`
- **Rol:** `DRIVER` (Conductor)

---

## 6. GUÍA DE RESOLUCIÓN DE PROBLEMAS COMUNES (TROUBLESHOOTING)

### 1. Error de Puerto en Uso (`BindException: Address already in use`)
- **Causa:** Quedó una instancia previa de Spring Boot (puerto 8080) o de Flutter (puerto 5000) corriendo en segundo plano.
- **Solución en PowerShell:**
  ```powershell
  # Identificar el PID del proceso en el puerto 8080
  Get-NetTCPConnection -LocalPort 8080 -ErrorAction SilentlyContinue | Select-Object OwningProcess
  # Terminar el proceso
  Stop-Process -Id <PID> -Force
  ```

### 2. Error de Codificación en PowerShell (`HttpMessageNotReadableException: 400 Bad Request`)
- **Causa:** En consolas Windows con codificación Windows-1252 predeterminada, caracteres como tildes ("Bogotá", "Medellín") o la letra "ñ" pueden enviarse corrompidos al backend al usar scripts `Invoke-RestMethod`.
- **Solución:** Configure explícitamente el encabezado `-ContentType "application/json; charset=utf-8"` y guarde sus scripts en formato UTF-8 sin BOM.

### 3. Falla de Conexión a Base de Datos (`Communications link failure`)
- **Causa:** El servicio `MySQL84` no está iniciado o las credenciales no coinciden.
- **Solución:**
  ```powershell
  Start-Service -Name MySQL84
  mysql -u root -p -e "SHOW DATABASES;"
  ```
