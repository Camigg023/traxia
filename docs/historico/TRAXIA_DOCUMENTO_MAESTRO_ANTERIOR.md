# TRAXIA — Documento Maestro
> **Versión:** 1.0.1-draft  
> **Fecha:** 2026-10-18  
> **Estado:** Borrador inicial — construido desde la especificación fundacional del proyecto de grado  
> **Autor principal:** Estudiante (Ingeniería de Software) — revisado con asistencia de IA  
> **Cambio v1.0.1:** Plataforma frontend actualizada a **Flutter Web** (aplicación web en navegador, no app móvil nativa). Carpeta `/mobile` renombrada a `/web`. Ver DEC-021 en `docs/DECISIONES.md`.  
> **Nota de integridad:** Este documento es la fuente de verdad del proyecto. Nada puede ser eliminado sin dejar registro en `docs/DECISIONES.md`. Todo dato numérico, tarifa, norma o integración externa está marcado según su procedencia.

---

## Tabla de contenido

1. [Descripción general del proyecto](#1-descripción-general-del-proyecto)
2. [Propósito académico y justificación](#2-propósito-académico-y-justificación)
3. [Actores y roles del sistema](#3-actores-y-roles-del-sistema)
4. [Principios de diseño y reglas no negociables](#4-principios-de-diseño-y-reglas-no-negociables)
5. [Stack tecnológico obligatorio](#5-stack-tecnológico-obligatorio)
6. [Stack tecnológico — Backend (Java)](#6-stack-tecnológico--backend-java)
7. [Stack tecnológico — App móvil (Flutter)](#7-stack-tecnológico--app-móvil-flutter)
8. [Proveedores externos](#8-proveedores-externos)
9. [DevOps y calidad](#9-devops-y-calidad)
10. [Estructura del repositorio](#10-estructura-del-repositorio)
11. [Forma de trabajo y metodología](#11-forma-de-trabajo-y-metodología)
12. [Áreas funcionales del sistema (20 dominios)](#12-áreas-funcionales-del-sistema-20-dominios)
13. [Flujos clave del sistema](#13-flujos-clave-del-sistema)
14. [Reglas de negocio críticas](#14-reglas-de-negocio-críticas)
15. [Modelo de datos de alto nivel](#15-modelo-de-datos-de-alto-nivel)
16. [Seguridad y privacidad](#16-seguridad-y-privacidad)
17. [Modo sin conexión](#17-modo-sin-conexión)
18. [Inteligencia artificial — reglas y límites](#18-inteligencia-artificial--reglas-y-límites)
19. [Gemelo digital y simulaciones](#19-gemelo-digital-y-simulaciones)
20. [Anti-evasión y calificaciones](#20-anti-evasión-y-calificaciones)
21. [Internacionalización y accesibilidad](#21-internacionalización-y-accesibilidad)
22. [Temas visuales](#22-temas-visuales)
23. [Procedencia de datos](#23-procedencia-de-datos)
24. [Marco legal (por verificar)](#24-marco-legal-por-verificar)
25. [Modelo de ingresos (por definir)](#25-modelo-de-ingresos-por-definir)
26. [Gestión de errores y resiliencia](#26-gestión-de-errores-y-resiliencia)
27. [Panel administrativo](#27-panel-administrativo)
28. [Pagos — alcance actual y fase futura](#28-pagos--alcance-actual-y-fase-futura)
29. [Preguntas abiertas de negocio](#29-preguntas-abiertas-de-negocio)
30. [Áreas de dominio detalladas](#30-áreas-de-dominio-detalladas)
31. [Casos de error documentados](#31-casos-de-error-documentados)
32. [Plan de fases de desarrollo](#32-plan-de-fases-de-desarrollo)

---

## 1. Descripción general del proyecto

**TRAXIA** es una plataforma digital de intermediación para el transporte de carga en Colombia. Conecta a empresas generadoras de carga, conductores independientes y empresas transportadoras en un flujo digital completo: desde la publicación de una carga hasta la entrega, liquidación y calificación.

El sistema está compuesto por:
- Una **aplicación móvil** (Flutter, Android e iOS) para conductores, empresas generadoras de carga y empresas transportadoras.
- Un **backend** (Java + Spring Boot) que expone una API REST documentada con Swagger/OpenAPI.
- Una **base de datos relacional** (MySQL 8.x) gestionada por el backend.
- Un **panel administrativo** (propuesta: Flutter Web dentro del mismo proyecto móvil — decisión final pendiente del estudiante).
- Integraciones con **proveedores externos** mediante interfaces intercambiables con mocks claramente identificados.

> **⚠️ Contexto académico:** Este proyecto es el trabajo de grado de Ingeniería de Software. Cada decisión técnica debe poder sustentarse académicamente. Las normas, tarifas y requisitos legales están marcados "por verificar con fuente oficial" y nunca se presentan como aprobados.

---

## 2. Propósito académico y justificación

| Aspecto | Descripción |
|---|---|
| **Tipo de proyecto** | Trabajo de grado — Ingeniería de Software |
| **Objetivo** | Diseñar, implementar y sustentar una plataforma de transporte de carga con estándares de la industria |
| **Alcance demostrable** | Rebanada vertical completa: publicación → oferta → contratación → viaje → entrega → liquidación → calificación |
| **Justificación de monolito modular** | Para un proyecto de grado con un equipo pequeño, el monolito modular permite demostrar todos los patrones arquitectónicos (capas, DDD ligero, CQRS básico) sin la sobrecarga operativa de los microservicios. La modularidad interna garantiza que la migración futura sea viable. |

---

## 3. Actores y roles del sistema

### 3.1 Empresa Generadora de Carga (EGC)
Empresa o persona natural que necesita transportar mercancía. Publica cargas, revisa ofertas, contrata transportadores, hace seguimiento y califica el servicio.

**Subtipos:**
- Persona natural (cliente ocasional)
- Empresa con múltiples sedes y múltiples usuarios

### 3.2 Conductor
Persona natural con licencia de conducción y vehículo propio o asignado. Busca cargas, simula costos, hace ofertas, gestiona su viaje y registra la entrega.

**Subtipos:**
- Conductor independiente (propietario del vehículo)
- Conductor vinculado a una empresa transportadora

### 3.3 Empresa Transportadora (ET)
Empresa habilitada legalmente para prestar servicios de transporte de carga. Gestiona su flota de vehículos, vincula conductores, gestiona viajes y cobra por el servicio.

**Subtipos:**
- Empresa transportadora pequeña (1–5 vehículos)
- Empresa transportadora mediana/grande (flota amplia, múltiples sedes)

### 3.4 Administrador de la Plataforma
Usuario interno de TRAXIA con acceso total al panel administrativo. Gestiona usuarios, revisa verificaciones, modera publicaciones, configura parámetros del sistema y genera reportes.

**Subtipos:**
- Superadministrador (acceso total)
- Moderador (revisión de verificaciones y reportes)
- Soporte (consulta y gestión de incidencias)

---

## 4. Principios de diseño y reglas no negociables

### R-01 — Idioma y localización
- Toda la interfaz en **español colombiano** cotidiano ("Iniciar sesión", no "Login"; "Contraseña", no "Password").
- Internacionalización desde el inicio: archivos ARB + `flutter_localizations`, `es-CO` como locale principal.
- Moneda: **COP**. Zona horaria de interfaz: **America/Bogotá**. Fechas almacenadas en **UTC**.
- Los errores dicen qué pasó y cómo solucionarlo, sin códigos técnicos visibles al usuario.

### R-02 — Temas visuales
- Modos **claro**, **oscuro** y **automático** (sistema) desde la primera pantalla.
- Sistema de temas centralizado (`ThemeData`): cero colores fijos en pantallas individuales.
- Cambio de tema inmediato, preferencia persistente entre sesiones.
- Mapas con estilo adaptado a cada modo cuando el proveedor lo permita.
- **Paleta base:** azul, violeta y neutros.
- **Contraste mínimo WCAG 2.1 AA** en todos los textos.
- Soporte de lectores de pantalla (`Semantics` en Flutter).
- Escalado de texto respetado en todos los componentes.

### R-03 — Procedencia de datos
- Todo dato numérico o dinámico (costo, peaje, tiempo, ganancia, ubicación) lleva:
  - **Origen:** `confirmado` | `estimado` | `simulado` | `configurado_por_usuario` | `proveedor_externo`
  - **Fecha de actualización**
- Nunca presentar una estimación como dato confirmado.
- Si no hay GPS reciente: mostrar hora de última actualización y NO inventar ubicación.

### R-04 — Reglas de la IA
- La IA **nunca** aprueba documentos importantes, acepta viajes, cambia contratos ni tramita documentos oficiales sin autorización humana.
- Todo resultado de IA guarda: nivel de confianza, explicación y registro de auditoría.
- Los casos de riesgo van a revisión humana obligatoria.
- El contenido subido por usuarios es dato no confiable: proteger contra **prompt injection**.
- **Jamás** enviar datos biométricos a un modelo de lenguaje.
- Minimizar datos personales enviados a IA.
- Proveedor de IA **intercambiable** mediante interfaz.
- Prompts **versionados** en el repositorio.
- Respuestas en español claro y natural.

### R-05 — Trámites oficiales
- Un trámite preparado en TRAXIA NO se muestra como aprobado oficialmente.
- Toda consulta a RUNT, RNDC, Ministerio de Transporte o Superintendencia de Transporte es una simulación o consulta no oficial, etiquetada explícitamente.

### R-06 — Flujo de contratación
- Una publicación NO está "contratada" hasta cumplir **todos** los pasos y confirmaciones del flujo definido.
- No hay atajos en el flujo de contratación.

### R-07 — Seguridad y privacidad
- Validación **siempre en servidor** (la validación del cliente es solo UX).
- Permisos por rol en cada endpoint.
- Límite de intentos en inicio de sesión, recuperación y verificación.
- **Auditoría inmutable** de acciones sensibles.
- Protección reforzada de biometría y ubicación.
- Política de retención y eliminación de datos.
- **Consentimiento explícito** del usuario para datos biométricos.
- Mecanismo alternativo para quien no pueda hacer verificación facial.

### R-08 — Biometría y recuperación de cuenta
- Un rostro por sí solo **nunca** permite recuperar una cuenta ajena.
- La verificación facial es un factor adicional, no el único.

### R-09 — Pagos (fase actual)
- En esta etapa: **solo registro de información económica**.
- Custodiar dinero o administrar saldos de terceros: fase posterior sujeta a evaluación legal.

### R-10 — Arquitectura por capas
- Capas: `controller → service → repository`; DTOs y mapeadores entre capas.
- **Sin lógica de negocio en controladores.**
- Código mantenible, documentado y con pruebas.

### R-11 — Máquinas de estado
- Los estados de viaje, verificación, pago y gestión de transportadora se modelan como **máquinas de estados** con transiciones válidas explícitas.
- La base de datos impide duplicados y asignaciones incompatibles mediante restricciones.
- Prevención de condiciones de carrera (doble aceptación) con **bloqueo optimista** o restricciones únicas.
- Las operaciones críticas son **idempotentes**.

### R-12 — Gemelo digital
- El plan del viaje vs. la ejecución real se modelan explícitamente como entidades separadas.
- Las simulaciones son **instantáneas inmutables** que guardan parámetros, fuentes y fecha.
- Las simulaciones se etiquetan siempre como `SIMULACIÓN`.

### R-13 — Trabajo sin conexión
- La app permite: consultar viajes asignados y registrar gastos sin señal.
- **Cola de sincronización** con reglas de conflicto definidas.
- Ninguna confirmación legal, contratación ni aprobación se completa sin conexión.

### R-14 — Anti-evasión
- Los datos de contacto no se revelan entre partes hasta que la contratación esté **confirmada**.
- El chat detecta e informa intentos de sacar la negociación de la plataforma.

### R-15 — Calificaciones
- Solo existen sobre **viajes reales completados**.
- Medidas básicas contra manipulación de calificaciones.

### R-16 — Resiliencia con proveedores externos
- Toda llamada a proveedor externo pasa por una **interfaz** con implementación real y mock.
- Tiempos de espera y reintentos configurados.
- Comportamiento definido cuando el proveedor falla: la app informa en español y NO inventa datos.

---

## 5. Stack tecnológico obligatorio

| Componente | Tecnología |
|---|---|
| **Aplicación web** | **Flutter Web** (navegador: Chrome, Firefox, Safari, Edge) |
| Backend | Java + Spring Boot 3.x |
| Base de datos | MySQL 8.x |
| API | REST documentada con Swagger / OpenAPI 3 |
| Seguridad | Spring Security + JWT |
| Acceso con Google | OAuth 2.0 / OpenID Connect |
| Tiempo real | WebSockets (Spring WebSocket + STOMP) |
| Pruebas de API | Postman (colecciones versionadas en el repo) |
| Control de versiones | Git + GitHub |

> **Restricción fundamental:** La aplicación Flutter Web **NUNCA** accede directamente a MySQL. Todo pasa por el backend REST.

> **⚠️ Decisión pendiente (DEC-P05):** Almacenamiento seguro de tokens en Flutter Web. Opciones: cookies HttpOnly + SameSite=Strict manejadas por el backend (más seguro), o localStorage cifrado. Esta decisión afecta el flujo de JWT.


---

## 6. Stack tecnológico — Backend (Java)

| Componente | Tecnología | Versión objetivo |
|---|---|---|
| Lenguaje | Java LTS vigente | Java 21 *(por verificar versión estable actual)* |
| Framework | Spring Boot | 3.x *(por verificar versión estable actual)* |
| Persistencia | Spring Data JPA + Hibernate | — |
| Validación | Bean Validation (Jakarta) | — |
| Mapeadores | MapStruct | *(por verificar versión estable actual)* |
| WebSocket | Spring WebSocket + STOMP | — |
| Migraciones DB | Flyway | *(por verificar versión estable actual)* |
| JWT | Access token corto + refresh token con rotación y revocación | — |
| Hash contraseñas | BCrypt o Argon2 | — |
| Resiliencia | Resilience4j (reintentos, timeout, circuit breaker) | *(por verificar)* |
| Rate limiting | Bucket4j u opción justificada | *(por verificar)* |
| Observabilidad | Spring Boot Actuator + logs estructurados | — |
| Arquitectura | Monolito modular por dominios | — |

**Justificación del monolito modular sobre microservicios:**
Para un proyecto de grado con equipo de una persona, los microservicios añaden complejidad operativa (descubrimiento de servicios, comunicación entre procesos, trazabilidad distribuida) que no agrega valor académico demostrable en el tiempo disponible. El monolito modular organizado por dominios demuestra los mismos patrones (separación de responsabilidades, bajo acoplamiento, alta cohesión) y permite una migración futura justificada.

---

## 7. Stack tecnológico — Aplicación web (Flutter Web)

| Componente | Tecnología | Justificación |
|---|---|---|
| Arquitectura | Clean Architecture (presentación / dominio / datos) | Separación de responsabilidades, testabilidad, independencia de frameworks |
| Estado | Riverpod *(propuesto)* o Bloc | *Decisión pendiente — ver sección 29* |
| Navegación | `go_router` | Navegación declarativa, soporte deep links y URL del navegador, bien mantenido por Google |
| Cliente HTTP | `dio` con interceptores | Manejo centralizado de tokens, renovación automática, errores en español |
| Almacenamiento tokens | Cookies HttpOnly (backend) o `flutter_secure_storage` web | ⚠️ DEC-P05 pendiente — cookies HttpOnly es la opción más segura en web |
| DB local (offline) | `drift` con WASM (web) o IndexedDB | *Decisión pendiente — ver sección 29* |
| i18n | `flutter_localizations` + archivos ARB (`es-CO`) | Estándar de Flutter para internacionalización |
| Temas | `ThemeData` claro/oscuro centralizado + preferencia persistente | R-02 |
| Mapas | `google_maps_flutter_web` o `flutter_map` + `geolocator` (web) | Geolocation API del navegador vía geolocator *(por verificar cobertura CO)* |
| Notificaciones | Firebase Cloud Messaging Web (Service Workers) | FCM Web — push notifications en navegador |
| Offline | Service Workers + drift WASM / IndexedDB | Modo sin conexión en navegador web |
| Pruebas | Widget tests + `integration_test` (Chrome headless) + golden tests (resoluciones web) | Cobertura multi-nivel en entorno web |
| Compatibilidad | Chrome, Firefox, Safari, Edge (últimas 2 versiones principales) | Cobertura amplia de navegadores modernos |
| Cámara / archivos | `image_picker` web (MediaDevices API del navegador) | Acceso a cámara y archivos del dispositivo vía navegador |


---

## 8. Proveedores externos

> **Regla:** Todo proveedor externo tiene una interfaz con mock claramente identificado. Los costos y coberturas están marcados "por verificar".

| Función | Proveedor propuesto | Alternativas | Costo | Cobertura CO | Mock inicial |
|---|---|---|---|---|---|
| Mapas / rutas / lugares | Google Maps Platform (Maps SDK, Routes API, Places API) | Mapbox, OpenRouteService | ⚠️ Por verificar | ⚠️ Por verificar (peajes de carga) | Sí |
| Tarifas de peajes | Tabla configurable desde INVÍAS / ANI / concesiones | — | N/A (datos abiertos) | ⚠️ Por verificar | Sí — tabla estática de ejemplo |
| Costos de referencia | SICE-TAC u otra fuente oficial | — | N/A | ⚠️ Por verificar | Sí — valores de ejemplo marcados "simulado" |
| Verificación facial / prueba de vida | Truora / Metamap / AWS Rekognition Face Liveness / Azure Face | — | ⚠️ Por verificar | ⚠️ Por verificar (validación CO) | Sí |
| Lectura de documentos con IA | Gemini (API) mediante interfaz intercambiable | Google Document AI | ⚠️ Por verificar | Global | Sí |
| Almacenamiento de archivos | MinIO (local) / S3 o Cloud Storage (producción) | — | ⚠️ Por verificar | — | MinIO local |
| Notificaciones móviles | Firebase Cloud Messaging | — | Gratuito hasta cuota | Global | Sí |
| Correo transaccional | Amazon SES / SendGrid / Resend | — | ⚠️ Por verificar | — | Mailpit (local) |
| SMS / código por celular | Twilio u otro con cobertura CO | — | ⚠️ Por verificar | ⚠️ Por verificar | Sí |
| RUNT | Consulta oficial (API no pública) | — | ⚠️ Por verificar (convenio) | Colombia | Mock / simulación |
| RNDC | Consulta oficial (API no pública) | — | ⚠️ Por verificar (convenio) | Colombia | Mock / simulación |
| Manifiesto electrónico | Ministerio de Transporte | — | ⚠️ Por verificar | Colombia | Mock / simulación |
| Superintendencia de Transporte | Consulta oficial | — | ⚠️ Por verificar | Colombia | Mock / simulación |
| Pasarela de pagos | Fase futura | — | — | — | — |
| Facturación electrónica DIAN | Fase futura | — | — | — | — |

---

## 9. DevOps y calidad

| Aspecto | Herramienta / práctica |
|---|---|
| Entorno local | Docker + Docker Compose (MySQL, backend, MinIO, Mailpit) — un solo comando |
| CI/CD | GitHub Actions: compilar, probar, análisis estático, escaneo de dependencias en cada PR |
| Pruebas backend | JUnit 5, Mockito, Testcontainers (MySQL real) |
| Pruebas rendimiento | k6 o JMeter |
| Seguridad | OWASP Top 10 + ASVS (guía), OWASP ZAP, Dependabot |
| Cobertura mínima | Acordada por fase *(propuesta: 80% en capa de servicio)* |
| Secretos | `.env.example` en repo; **nunca** secretos reales en el repositorio |
| Flujo de ramas | `main` protegida; ramas por funcionalidad; commits convencionales |
| Despliegue | Contenedores Docker en proveedor cloud / VPS compatible con Java + MySQL *(costo por verificar)* |
| Diagramas | Mermaid o PlantUML dentro de `/docs` |

---

## 10. Estructura del repositorio

```
traxia/
├── docs/                          # Documentación, diagramas, decisiones
│   ├── TRAXIA_DOCUMENTO_MAESTRO.md
│   ├── DECISIONES.md
│   ├── PENDIENTES.md
│   ├── GLOSARIO.md
│   └── diagramas/
├── backend/                       # Proyecto Spring Boot (Maven o Gradle)
│   └── src/
├── web/                           # Proyecto Flutter Web (aplicación web en navegador)
│   └── lib/
├── database/                      # Scripts SQL iniciales (si aplica fuera de Flyway)
├── infra/                         # Docker Compose y configuración de infraestructura local
│   ├── docker-compose.yml
│   └── .env.example
└── .github/
    └── workflows/                 # GitHub Actions
```

**Panel administrativo:** Flutter Web dentro del mismo proyecto `/web`. Rutas de admin protegidas por rol (`/admin/*`). Un solo codebase Flutter. Ver sección 27.


---

## 11. Forma de trabajo y metodología

### Proceso por fase
Al inicio de cada fase:
1. (a) Resumen de lo entendido
2. (b) Lista de supuestos y preguntas abiertas
3. (c) Plan de archivos y tareas
4. (d) Esperar visto bueno antes de escribir código

Al terminar cada fase:
- Código funcional
- Pruebas que pasan
- Criterios de aceptación con evidencia
- Documentación actualizada
- Resumen de pendientes

### Documentos vivos obligatorios
| Archivo | Contenido |
|---|---|
| `docs/DECISIONES.md` | Decisión + justificación + alternativas descartadas |
| `docs/PENDIENTES.md` | Dependencias externas, riesgos, normas por verificar |
| `docs/GLOSARIO.md` | Términos del dominio y técnicos |

### Reglas de comandos
- **Nunca** ejecutar comandos destructivos sin confirmación explícita (borrar carpetas, resetear BD, force push).
- **Nunca** instalar dependencias o servicios de pago sin informar el costo al estudiante.

---

## 12. Áreas funcionales del sistema (20 dominios)

> **Nota:** Esta clasificación en 20 dominios fue inferida de la especificación fundacional. Debe ser validada y ajustada por el estudiante.

| # | Dominio | Descripción resumida |
|---|---|---|
| D-01 | Gestión de usuarios y roles | Registro, autenticación, perfiles, roles, permisos |
| D-02 | Verificación de identidad | Correo, Google OAuth, verificación facial, prueba de vida, documentos |
| D-03 | Gestión de empresas generadoras de carga | Perfiles empresariales, sedes, usuarios administradores |
| D-04 | Gestión de conductores | Perfil, licencias, historial, calificación, estado de disponibilidad |
| D-05 | Gestión de empresas transportadoras | Perfil, habilitación, conductores vinculados, vehículos, sedes |
| D-06 | Gestión de vehículos y flotas | Registro, documentos, mantenimiento, asignación, compatibilidad con carga |
| D-07 | Publicación de carga | Creación, edición, tipos de carga, requisitos, estados |
| D-08 | Búsqueda y filtrado de cargas | Filtros por tipo, ruta, fecha, capacidad, calificación |
| D-09 | Oferta y negociación | Cotización, contraoferta, simulación de costos |
| D-10 | Contratación | Flujo de aceptación, confirmaciones, generación de acuerdo |
| D-11 | Seguimiento en tiempo real | GPS, actualización de ubicación, estado del viaje, alertas |
| D-12 | Gestión de viajes | Plan vs. ejecución real, incidencias, cambios de ruta |
| D-13 | Documentación de viaje | Manifiestos (mock), fotografías, registros de novedad |
| D-14 | Entrega y cierre | Confirmación de entrega, firma, registro fotográfico |
| D-15 | Liquidación y pagos | Cálculo de costos, peajes, registros económicos (no custodia de dinero) |
| D-16 | Calificaciones y reputación | Calificación bidireccional sobre viajes reales completados |
| D-17 | Notificaciones | Push (FCM), correo, SMS, notificaciones en app |
| D-18 | Gemelo digital y simulaciones | Plan vs. ejecución, simulaciones inmutables etiquetadas |
| D-19 | Consultas a entidades oficiales | RUNT, RNDC, Ministerio de Transporte (mocks, por verificar) |
| D-20 | Administración y reportes | Panel admin, moderación, configuración, analíticas |

---

## 13. Flujos clave del sistema

> Los diagramas detallados se generan en la Fase 1 como entregables específicos.

| Flujo | Descripción |
|---|---|
| F-01 | Registro con correo electrónico |
| F-02 | Registro con Google (OAuth 2.0 / OIDC) |
| F-03 | Vinculación de cuentas (correo + Google) |
| F-04 | Verificación facial y prueba de vida |
| F-05 | Recuperación de cuenta |
| F-06 | Publicación de carga |
| F-07 | Búsqueda, simulación de costos y oferta |
| F-08 | Contratación completa (todos los pasos) |
| F-09 | Gestión de la transportadora (asignación de conductor y vehículo) |
| F-10 | Seguimiento en tiempo real del viaje |
| F-11 | Entrega y cierre del viaje |
| F-12 | Liquidación y calificación |
| F-13 | Reasignación por avería |
| F-14 | Reclamación por mercancía dañada o incompleta |

---

## 14. Reglas de negocio críticas

| ID | Regla |
|---|---|
| RN-01 | Un conductor no puede tener dos viajes activos simultáneos |
| RN-02 | Un vehículo no puede estar asignado a dos viajes activos simultáneos |
| RN-03 | La carga solo puede ser contratada por una transportadora / conductor a la vez |
| RN-04 | El viaje no inicia hasta que todos los documentos obligatorios estén cargados y verificados (o en revisión) |
| RN-05 | La calificación solo existe sobre viajes en estado `COMPLETADO` |
| RN-06 | Un trámite preparado en TRAXIA no equivale a aprobación oficial |
| RN-07 | Los datos de contacto entre partes no se revelan hasta contratación confirmada |
| RN-08 | Las tarifas estimadas llevan marca `ESTIMADO` y fecha de referencia |
| RN-09 | La doble aceptación simultánea debe prevenirse con bloqueo optimista o restricción única |
| RN-10 | Los viajes recurrentes son instancias separadas de un plan base, cada una con su propio estado |

---

## 15. Modelo de datos de alto nivel

> Entidades principales identificadas. El diagrama ER detallado se genera en la Fase 1.

**Entidades nucleares:**
- `Usuario` (base de todos los perfiles)
- `PerfilConductor`
- `PerfilEmpresaGeneradora`
- `PerfilEmpresaTransportadora`
- `Vehiculo`
- `Flota` (conjunto de vehículos de una transportadora)
- `SedeEmpresa`
- `PublicacionCarga`
- `Oferta`
- `Contrato`
- `Viaje` (ejecución real)
- `PlanViaje` (gemelo digital — plan)
- `SimulacionViaje` (instantánea inmutable)
- `UbicacionViaje` (histórico de posiciones GPS)
- `Documento` (licencias, SOAT, tecno-mecánica, habilitaciones)
- `VerificacionIdentidad`
- `Calificacion`
- `Notificacion`
- `Liquidacion`
- `RegistroGasto`
- `AuditoriaAccion` (registro inmutable de acciones sensibles)
- `ConfiguracionSistema`
- `TarifaPeaje` (tabla configurable con fuente y fecha)

---

## 16. Seguridad y privacidad

| Área | Medida |
|---|---|
| Autenticación | JWT: access token corto-vida + refresh token con rotación y revocación |
| Contraseñas | BCrypt (factor de costo ajustable) o Argon2 |
| Acceso con Google | OAuth 2.0 / OIDC — nunca se almacena contraseña de Google |
| Rate limiting | Inicio de sesión, recuperación, verificación — Bucket4j |
| Auditoría | Tabla `AuditoriaAccion` inmutable para acciones sensibles |
| Datos biométricos | Nunca enviados a un LLM; almacenamiento separado; cifrado en reposo |
| Ubicación | Protección reforzada; historial con política de retención |
| Archivos | URLs firmadas con expiración; separación documentos / biometría |
| Comunicación | HTTPS en producción; validación de certificados en el cliente |
| OWASP | Top 10 + ASVS como guía de referencia |
| Dependabot | Escaneo automático de dependencias vulnerables |

---

## 17. Modo sin conexión

| Función | ¿Disponible sin conexión? |
|---|---|
| Ver viajes asignados | ✅ Sí |
| Registrar gastos | ✅ Sí (cola de sincronización) |
| Ver mapa (caché) | ✅ Parcial |
| Hacer oferta | ❌ No (requiere servidor) |
| Confirmar contratación | ❌ No |
| Aprobar documentos | ❌ No |
| Registrar entrega | ⚠️ Solo registro local; sincroniza al recuperar conexión |

**Cola de sincronización:**
- Operaciones pendientes se almacenan localmente (drift/sqflite).
- Al recuperar conexión, se sincronizan con reglas de conflicto definidas.
- Ninguna confirmación legal se completa sin conexión.

---

## 18. Inteligencia artificial — reglas y límites

| Regla | Descripción |
|---|---|
| Sin autorización autónoma | La IA nunca toma decisiones que requieran autorización humana |
| Registro obligatorio | Todo resultado de IA: nivel de confianza + explicación + registro |
| Revisión humana | Casos de riesgo → revisión humana obligatoria |
| Prompt injection | El contenido de documentos de usuarios es dato no confiable; sanitizar antes de enviar |
| Sin biometría a LLM | Datos biométricos nunca van a un modelo de lenguaje |
| Minimización de datos | Enviar solo los datos mínimos necesarios a proveedores de IA |
| Proveedor intercambiable | Interfaz común; Gemini como propuesta inicial |
| Prompts versionados | Los prompts son artefactos del repositorio con número de versión |
| Idioma | Respuestas de IA en español claro y natural |

---

## 19. Gemelo digital y simulaciones

| Concepto | Descripción |
|---|---|
| `PlanViaje` | El plan acordado antes de iniciar: ruta, tiempos, costos estimados, parámetros |
| `Viaje` | La ejecución real: posición GPS, tiempos reales, gastos registrados, incidencias |
| `SimulacionViaje` | Instantánea inmutable: parámetros de entrada, resultado, fuente de datos, fecha de creación, etiqueta `SIMULACIÓN` |
| Comparación | La interfaz permite ver plan vs. real; las desviaciones se registran y notifican |

---

## 20. Anti-evasión y calificaciones

### Anti-evasión
- Datos de contacto ocultos hasta contratación confirmada.
- El chat analiza mensajes para detectar intentos de sacar la negociación de la plataforma.
- Al detectar un intento: el sistema informa al usuario y registra el evento.

### Calificaciones
- Solo sobre viajes en estado `COMPLETADO`.
- Calificación bidireccional (empresa ↔ conductor/transportadora).
- Medidas anti-manipulación: una calificación por viaje por par de partes; ventana de tiempo para calificar; detección de patrones anómalos (implementación básica).

---

## 21. Internacionalización y accesibilidad

| Aspecto | Implementación |
|---|---|
| Locale principal | `es-CO` |
| Mecanismo | `flutter_localizations` + archivos `.arb` |
| Expansión | Estructura lista para agregar `es-MX`, `es-PE`, etc. en el futuro |
| Accesibilidad | `Semantics` en todos los widgets interactivos |
| Contraste | WCAG 2.1 AA mínimo |
| Escalado texto | `textScaler` respetado; sin tamaños fijos que rompan el layout |
| Fechas | Mostradas en formato colombiano; guardadas en UTC |
| Moneda | COP con formato colombiano (. como separador de miles) |
| Zona horaria | `America/Bogotá` en interfaz; UTC en base de datos |

---

## 22. Temas visuales

```
Paleta base:
  Primario: Azul (#por definir en fase 2)
  Secundario: Violeta (#por definir en fase 2)
  Neutros: Grises (#por definir en fase 2)
  Error: Rojo semántico
  Éxito: Verde semántico
  Advertencia: Naranja/amarillo semántico

Modos:
  Claro: fondo blanco/gris muy claro, texto oscuro
  Oscuro: fondo gris muy oscuro/negro, texto claro
  Automático: sigue la preferencia del sistema operativo
```

- Los tokens de color se definen en una sola clase/archivo de tema.
- Las pantallas usan `Theme.of(context).colorScheme.*` exclusivamente.
- La preferencia se persiste con `shared_preferences` o `flutter_secure_storage`.

---

## 23. Procedencia de datos

Cada campo dinámico en el modelo de datos debe incluir o referenciar:

| Campo | Tipo | Ejemplo |
|---|---|---|
| `fuente_dato` | Enum | `CONFIRMADO`, `ESTIMADO`, `SIMULADO`, `USUARIO`, `PROVEEDOR_EXTERNO` |
| `fecha_actualizacion` | Timestamp UTC | — |
| `proveedor_fuente` | String nullable | `"SICE-TAC"`, `"Google Routes API"`, `"Usuario"` |

En la interfaz: mostrar siempre el origen y la fecha cuando el dato es estimado, simulado o externo.

---

## 24. Marco legal (por verificar)

> ⚠️ **Todo lo listado aquí debe ser verificado con fuentes oficiales antes de implementar cualquier flujo que lo involucre.**

| Norma | Área | Estado |
|---|---|---|
| Ley 1581 de 2012 y decretos reglamentarios | Datos personales, datos sensibles y biométricos | Por verificar |
| Ley 336 de 1996 | Transporte en Colombia | Por verificar |
| Decreto 1079 de 2015 | Regulación del transporte | Por verificar |
| RNDC (Registro Nacional de Despacho de Carga) | Registro de despachos de carga | Por verificar |
| Manifiesto electrónico de carga | Ministerio de Transporte | Por verificar |
| RUNT (Registro Único Nacional de Tránsito) | Conductores y vehículos | Por verificar |
| Superintendencia de Transporte | Habilitación de empresas transportadoras | Por verificar |
| SICE-TAC | Costos de referencia del transporte de carga | Por verificar |
| INVÍAS / ANI / concesiones | Tarifas de peajes | Por verificar |
| Responsabilidad legal de TRAXIA como intermediario | Marco de responsabilidad civil | Por verificar |
| Seguros de mercancía | Obligatoriedad y cobertura | Por verificar |

---

## 25. Modelo de ingresos (por definir)

> ⚠️ **No definido en la especificación inicial. Requiere decisión del estudiante / equipo.**

Preguntas abiertas:
- ¿Comisión por transacción? ¿Quién la paga (empresa, transportadora o ambas)?
- ¿Suscripción mensual para empresas?
- ¿Modelo freemium para conductores?
- ¿Publicidad?

Ver sección 29 — Preguntas abiertas de negocio.

---

## 26. Gestión de errores y resiliencia

| Nivel | Mecanismo |
|---|---|
| Backend — proveedores externos | Resilience4j: reintentos exponenciales, timeout, circuit breaker |
| Backend — autenticación | Rate limiting (Bucket4j): bloqueo temporal tras N intentos fallidos |
| Backend — errores de negocio | Excepciones tipadas con mensaje en español; mapeo a código HTTP correcto |
| Frontend — errores de red | Interceptor `dio`: reintento automático, renovación de token, mensaje en español |
| Frontend — error de proveedor | Mensaje claro al usuario: qué pasó, qué puede hacer, sin datos inventados |
| Frontend — modo offline | Indicador visible; operaciones bloqueadas con explicación |
| Base de datos | Transacciones con rollback; bloqueo optimista en operaciones críticas |

---

## 27. Panel administrativo

**Decisión adoptada:** Flutter Web dentro del mismo proyecto `/web` (un solo codebase Flutter con rutas protegidas por rol en `/admin/*`).

**Ventajas:** Un solo lenguaje, componentes compartidos, un solo deploy, temas claro/oscuro consistentes.  
**Limitaciones conocidas de Flutter Web:** rendimiento inicial (WASM mejora esto en versiones recientes), SEO limitado (no relevante para un panel admin interno).  
**Alternativa descartada:** Proyecto web separado (React + TypeScript) — descartada por complejidad de mantener dos codebases en un proyecto de grado individual.

> Registrado como **DEC-021** en `docs/DECISIONES.md`.


---

## 28. Pagos — alcance actual y fase futura

### Fase actual (incluida en el proyecto de grado)
- Registro de información económica: costos acordados, peajes estimados, gastos registrados, liquidación calculada.
- **No hay custodia de dinero real.**
- **No hay integración con pasarela de pagos.**

### Fase futura (fuera del alcance del proyecto de grado)
- Pasarela de pagos autorizada (evaluación legal requerida).
- Facturación electrónica DIAN.
- Administración de saldos de terceros.

---

## 29. Preguntas abiertas de negocio

| # | Pregunta | Impacto |
|---|---|---|
| P-01 | ¿Cuál es el modelo de ingresos de TRAXIA? ¿Comisión, suscripción, freemium, mixto? | Alto — afecta flujos de pago y registro |
| P-02 | ¿Cuál es la política de cancelación y penalidades para empresa y transportadora? | Alto — afecta máquina de estados del viaje |
| P-03 | ¿Quién paga a la transportadora / conductor? ¿TRAXIA media el pago o es acuerdo directo? | Alto — afecta módulo de liquidación |
| P-04 | ¿Cuál es la responsabilidad legal de TRAXIA como intermediario? | Alto — afecta términos de uso y flujos legales |
| P-05 | ¿TRAXIA exige seguro de mercancía? ¿A quién? ¿Con qué proveedor? | Medio — afecta documentos requeridos |
| P-06 | ¿Manejo de estado Riverpod o Bloc? | Bajo-Medio — afecta arquitectura del frontend |
| P-07 | ¿Base de datos local en Flutter: drift o sqflite? | Bajo — afecta persistencia offline |
| P-08 | ¿Panel admin: Flutter Web o proyecto web separado? | Medio — afecta estructura del repositorio |
| P-09 | ¿Qué proveedor de verificación facial se prefiere para el MVP? | Medio — afecta flujo de registro |
| P-10 | ¿Se requiere manifiesto electrónico de carga en el MVP o queda como mock? | Alto — afecta flujo de documentación de viaje |
| P-11 | ¿Viajes recurrentes están en el MVP? | Medio — afecta modelo de datos |
| P-12 | ¿Múltiples sedes por empresa en el MVP? | Medio — afecta modelo de datos |
| P-13 | ¿El chat en tiempo real está en el MVP o es una fase posterior? | Medio — afecta arquitectura WebSocket |
| P-14 | ¿Qué porcentaje de cobertura de pruebas es el objetivo mínimo? | Bajo — propuesta: 80% en capa de servicio |

---

## 30. Áreas de dominio detalladas

> Cada uno de los 20 dominios listados en la sección 12 se desarrollará en su propia subsección con: entidades, reglas de negocio, flujos, estados y dependencias externas. Este desarrollo se completa en la Fase 1 (análisis de requisitos).

*(Contenido a desarrollar en la Fase 1 — Entregables RF, RNF, HU, CU)*

---

## 31. Casos de error documentados

> Los siguientes casos de error deben ser demostrados en pruebas de extremo a extremo.

| ID | Caso de error | Descripción |
|---|---|---|
| CE-01 | Documentos vencidos | Conductor o vehículo con SOAT, tecno-mecánica o licencia vencida |
| CE-02 | Vehículo incompatible | El vehículo no cumple las dimensiones o capacidad de la carga publicada |
| CE-03 | Exceso de capacidad | La carga supera el peso o volumen máximo del vehículo asignado |
| CE-04 | Recuperación sospechosa | Intento de recuperar cuenta con datos inconsistentes; bloqueo y alerta |
| CE-05 | Cancelación por empresa | La empresa cancela una carga ya contratada; penalidad según política |
| CE-06 | Cancelación por conductor/transportadora | Conductor o transportadora cancela un viaje aceptado; penalidad según política |
| CE-07 | Cambio de ruta en viaje | El conductor registra un desvío; se notifica y se recalcula estimado |
| CE-08 | Avería con reasignación | Vehículo averiado en ruta; flujo de reasignación de conductor/vehículo |
| CE-09 | Mercancía dañada | El receptor reporta daño en la mercancía al momento de la entrega |
| CE-10 | Mercancía incompleta | La cantidad entregada no coincide con la declarada |
| CE-11 | Reclamación formal | Una parte abre una reclamación sobre el servicio |
| CE-12 | Publicación fraudulenta | Se detecta una publicación con datos falsos o intento de estafa |
| CE-13 | Doble aceptación simultánea | Dos conductores aceptan la misma carga al mismo tiempo; solo una debe prosperar |
| CE-14 | Caída de proveedor externo | Google Maps, verificación facial u otro proveedor no responde; app informa en español |
| CE-15 | Intento de evasión en chat | El chat detecta número de teléfono o email enviado directamente |
| CE-16 | Token expirado | El usuario intenta una operación con JWT vencido; flujo de renovación |

---

## 32. Plan de fases de desarrollo

> El orden de las fases es obligatorio. No se avanza sin aprobación del estudiante.

| Fase | Nombre | Entregables principales |
|---|---|---|
| **Fase 1** | Análisis de requisitos y diagramas | RF, RNF, HU, CU, diagramas, ER, arquitectura, riesgos |
| **Fase 2** | Configuración del entorno y scaffolding | Repo, Docker Compose, Spring Boot base, Flutter base, CI/CD inicial |
| **Fase 3** | Autenticación y gestión de usuarios | Registro, login, OAuth, JWT, roles, verificación de correo |
| **Fase 4** | Verificación de identidad | Verificación facial (mock), documentos, estados de verificación |
| **Fase 5** | Publicación de carga y búsqueda | CRUD de publicaciones, filtros, tipos de carga |
| **Fase 6** | Oferta, simulación y contratación | Cotización, simulación de costos, flujo de contratación completo |
| **Fase 7** | Gestión de transportadora y vehículos | Flota, conductores vinculados, asignación |
| **Fase 8** | Seguimiento en tiempo real | WebSocket, GPS, estado del viaje, gemelo digital |
| **Fase 9** | Entrega, cierre y liquidación | Confirmación de entrega, registro fotográfico, liquidación |
| **Fase 10** | Calificaciones y reputación | Calificación bidireccional, historial |
| **Fase 11** | Notificaciones y comunicación | FCM, correo, SMS, chat básico |
| **Fase 12** | Panel administrativo | Moderación, configuración, reportes |
| **Fase 13** | Pruebas, seguridad y despliegue | Pruebas integrales, OWASP ZAP, k6, despliegue en cloud |

---

*Fin del Documento Maestro v1.0.0-draft — 2026-10-18*
