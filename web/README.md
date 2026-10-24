# TRAXIA Web

Interfaz web adaptable construida con Flutter Web. La aplicación usa Riverpod
para estado, `go_router` para navegación y Dio para consumir la API.

## Requisitos

- Flutter SDK estable para Windows con soporte Web habilitado.
- Java 25 (LTS) y el backend TRAXIA ejecutándose en `http://localhost:8080`.
- Mailpit local activo en `localhost:1025` para recibir el enlace de verificación
  (interfaz en `http://localhost:8025`).
- El registro de esta entrega solo funciona en entorno local/desarrollo y muestra
  un aviso provisional, no legal. Las cuentas nuevas deben verificar su correo
  desde la bandeja local antes de iniciar sesión.

Si Flutter no está instalado, instala Flutter para Windows desde la guía oficial:
<https://docs.flutter.dev/get-started/install/windows/web>.
Extrae el SDK en una carpeta de usuario (por ejemplo,
`%USERPROFILE%\develop\flutter`), agrega `...\flutter\bin` al `PATH`, abre una
nueva terminal y comprueba con `flutter doctor -v` y `flutter devices`.
Si tu SDK no ofrece el navegador Web como destino, habilítalo con
`flutter config --enable-web`.

## Ejecutar

Desde esta carpeta:

```powershell
flutter pub get
flutter run -d chrome --web-port=5000 --dart-define=TRAXIA_API_BASE_URL=http://localhost:8080
```

Para compilar:

```powershell
flutter build web --release --dart-define=TRAXIA_API_BASE_URL=https://api.example.com
```

La URL del API es configuración de compilación; no se incluyen credenciales en
el frontend. En local, Spring debe permitir el origen de Flutter Web
(`http://localhost:port`) mediante `WEB_ALLOWED_ORIGINS`. La cookie de refresh
se envía con credenciales del navegador; refresh y logout incluyen el encabezado
requerido por el backend.

## Alcance actual

- Inicio de sesión conectado a `POST /api/v1/auth/login`.
- Registro local con `POST /api/v1/auth/register` y verificación manual mediante
  `POST /api/v1/auth/verify-email`. Para habilitarlo, configura
  `TRAXIA_REGISTRATION_ENABLED=true` en `.env.local`; el backend lo bloquea fuera
  de `APP_ENV=local`, `development`, `dev` o `test`.
- Para ejecutar Mailpit desde la raíz del repositorio:

  ```powershell
  docker compose -f compose.mailpit.yml up -d
  ```

  Consulta los mensajes en `http://localhost:8025`. El enlace caduca a los 30
  minutos. No uses el aviso provisional en producción ni lo presentes como
  términos/privacidad aprobados.
- Restauración de sesión con `POST /api/v1/auth/refresh` y lectura de perfil con
  `GET /api/v1/auth/me`.
- Cierre de sesión con `POST /api/v1/auth/logout`.
- El perfil elegido durante el registro se guarda como intención; no concede
  automáticamente roles de usuario, conductor o empresa.
- El panel usa únicamente permisos globales recibidos del backend. Las
  membresías y los paneles empresariales operativos aún no están disponibles.
- Los temas claro/oscuro/automático funcionan durante la sesión; la preferencia
  todavía no se persiste.

Ejecuta pruebas y análisis estático con:

```powershell
flutter test
flutter analyze
```
