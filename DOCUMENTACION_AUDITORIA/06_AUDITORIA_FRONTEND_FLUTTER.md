# AUDITORÍA TÉCNICA DEL FRONTEND: FLUTTER WEB Y DART

## 1. VISIÓN GENERAL DEL FRONTEND

El frontend de TRAXIA es una aplicación **Single Page Application (SPA)** desarrollada en **Flutter Web** con el lenguaje **Dart 3.13.7 (SDK 3.6+)**. Su propósito es ofrecer una interfaz ágil, moderna y totalmente adaptada a dispositivos móviles, tabletas y monitores de escritorio.

### Estructura de Paquetes en `web/lib/`

```
web/lib/
├── main.dart                       # Entry point con ProviderScope
├── app.dart                        # Configuración de MaterialApp.router, GoRouter y temas
├── auth/                           # Lógica de Identidad y Sesión
│   ├── auth_api.dart               # Cliente de red Dio para API de autenticación
│   ├── auth_client_adapter_web.dart# Adaptador web para cookies HttpOnly
│   ├── auth_client_adapter_stub.dart# Stub condicional para pruebas unitarias
│   ├── auth_controller.dart        # Controlador reactivo de sesión (ChangeNotifier)
│   ├── auth_models.dart            # Modelos inmutables de autenticación
│   └── google_auth_client.dart     # Cliente de Google Identity Services
├── loads/                          # Módulo de Cargas y Subastas
│   ├── load_api.dart               # API client de cargas
│   ├── trips_api.dart              # API client de viajes
│   ├── load_models.dart            # Modelos LoadModel y CreateLoadDto
│   └── bids_trips_models.dart      # Modelos BidModel y TripModel
├── screens/                        # Pantallas de la aplicación
│   ├── sign_in_screen.dart         # Inicio de sesión con split screen
│   ├── create_account_screen.dart  # Asistente de registro con bienvenida
│   ├── verify_email_screen.dart    # Verificación de correo vía token URL
│   ├── dashboard_screen.dart       # Panel de control con métricas y accesos
│   ├── loads_screen.dart           # Cartelera de fletes y modal de simulación
│   ├── publish_load_screen.dart    # Wizard de publicación en 5 pasos
│   └── trips_screen.dart           # Tablero de viajes en curso y finalizados
├── state/                          # App Providers globales de Riverpod
├── theme/                          # Paleta de colores y estilos SaaS
└── widgets/                        # Widgets reutilizables (NavBar, ThemeToggle)
```

---

## 2. GESTIÓN DE ESTADO REACTIVA CON RIVERPOD

TRAXIA utiliza **Flutter Riverpod 2.6.1**, implementando el principio de inyección de dependencias y reactividad funcional sin acoplamiento a la jerarquía de widgets.

### Providers Principales (`web/lib/state/app_providers.dart`)

1. **`authApiProvider`:** Instancia singleton del cliente de autenticación `AuthApi`.
2. **`authControllerProvider`:** `ChangeNotifierProvider<AuthController>` que mantiene:
   - `status`: Estado actual (`unauthenticated`, `authenticating`, `signedIn`, `restoring`).
   - `accessToken`: JWT en memoria para llamadas autorizadas.
   - `user`: Datos del usuario autenticado (`id`, `email`, `roles`).
   - `isSubmitting`: Indicador de carga para deshabilitar botones durante peticiones.
   - `message`: Mensajes de error o éxito propagados a la interfaz.
3. **`themeModeProvider`:** `StateProvider<ThemeMode>` para alternar entre temas Claro, Oscuro o Sistema.
4. **`loadApiProvider` y `tripsApiProvider`:** Proveedores de servicios para la interacción con los recursos de cargas y contratos.

---

## 3. ENRUTAMIENTO Y GUARDS DE NAVEGACIÓN (GOROUTER)

El enrutamiento está centralizado en `web/lib/app.dart` mediante **GoRouter 14.8.1**.

### Matriz de Redirección y Protección de Rutas

```dart
redirect: (context, state) {
  final path = state.uri.path;
  final isSignedIn = _authController.status == AuthStatus.signedIn;
  if (_authController.status == AuthStatus.restoring) {
    return null; // Espera a que termine la restauración de sesión por cookie
  }

  final authOnlyPaths = ['/panel', '/publicar-carga', '/publish-load', '/viajes', '/trips'];
  final unauthOnlyPaths = ['/iniciar-sesion', '/crear-cuenta'];

  if (path == '/') {
    return isSignedIn ? '/panel' : '/iniciar-sesion';
  }
  if (isSignedIn && unauthOnlyPaths.contains(path)) {
    return '/panel'; // Si ya está logueado, no debe ver login ni registro
  }
  if (!isSignedIn && authOnlyPaths.contains(path)) {
    return '/iniciar-sesion'; // Si no está autenticado, no puede entrar al panel
  }
  return null;
}
```

### Rutas Declaradas
- Públicas: `/`, `/iniciar-sesion`, `/crear-cuenta`, `/verificar-correo`, `/cargas`.
- Privadas: `/panel`, `/publicar-carga`, `/viajes`.

---

## 4. INTEGRACIÓN DE RED Y SOPORTE DE COOKIES (DIO)

El cliente de red principal es **Dio 5.8.0**. En entornos web, los navegadores imponen políticas estrictas para la transmisión de cookies en peticiones asíncronas *cross-origin*.

### Compilación Condicional del Adaptador Web
En `web/lib/auth/auth_api.dart`:
```dart
import 'auth_client_adapter_stub.dart'
    if (dart.library.js_interop) 'auth_client_adapter_web.dart';
```
Y en `web/lib/auth/auth_client_adapter_web.dart`:
```dart
import 'package:dio/browser.dart';
import 'package:dio/dio.dart';

HttpClientAdapter createAuthHttpClientAdapter() {
  return BrowserHttpClientAdapter()..withCredentials = true;
}
```
Esto habilita la directiva `withCredentials` del objeto `XMLHttpRequest` / `Fetch API` subyacente del navegador, permitiendo enviar la cookie `TRAXIA_REFRESH` al backend en `http://localhost:8080`.

---

## 5. DISEÑO RESPONSIVO Y SISTEMA VISUAL SAAS

La aplicación implementa una interfaz moderna basada en **Material Design 3**, optimizada mediante:
- **`LayoutBuilder` y `MediaQuery`:** Para conmutar dinámicamente entre diseño de una sola columna en pantallas móviles ($<980$ px) y diseño panorámico de dos paneles en pantallas amplias ($\ge 980$ px).
- **Estilos Glassmorphism:** Contenedores con desenfoque de fondo (`BackdropFilter(sigmaX: 16, sigmaY: 16)`) y bordes semitransparentes.
- **Soporte Dual de Tema:** `AppTheme.light` y `AppTheme.dark`, con paleta cromática profesional (`AppColors.primary = Color(0xFF1E3A8A)` azul marino corporativo y `AppColors.secondary = Color(0xFF0D9488)` verde azulado).

---

## 6. RESULTADOS DE ANÁLISIS ESTÁTICO Y PRUEBAS

### A. Análisis Estático (`flutter analyze`)
Tras corregir la variable local huérfana en `create_account_screen.dart` (BUG-005):
```
Analyzing web...
No issues found! (ran in 14.2s)
```
**Resultado:** Cero errores de sintaxis, cero advertencias de linter, 100% limpio.

### B. Pruebas Unitarias Automatizadas (`flutter test`)
Se ejecutó la suite de pruebas unitarias sobre los modelos y controladores:
```
00:00 +0: test/account_profile_test.dart: presenta los tres perfiles aprobados para la plataforma web
00:00 +1: test/auth_models_test.dart: lee el usuario de la respuesta de autenticación del backend
00:00 +2: test/auth_models_test.dart: no admite roles mal formados en la respuesta de sesión
00:00 +3: test/loads_models_test.dart: serializa y deserializa LoadModel correctamente
00:00 +4: All tests passed!
```
**Resultado:** 4 de 4 pruebas aprobadas con éxito en 1.0 segundos.
