# AUDITORÍA DE MÓDULOS DE NEGOCIO Y FUNCIONALIDADES

## 1. MÓDULO A: REGISTRO Y AUTENTICACIÓN

### Alcance y Flujo Verificado
El sistema soporta la incorporación de nuevos actores de la cadena logística mediante dos vías:
1. **Registro Local:** Inserción de credenciales con contraseña protegida por BCrypt.
2. **Registro Federado con Google:** Verificación del token OIDC emitido por Google y enlace directo a la cuenta.

### Flujo de Activación y Correo
- Generación de token criptográfico temporal en la tabla `email_verification_tokens`.
- Notificación al correo del usuario vía SMTP (Mailpit).
- El usuario no verificado permanece en estado `PENDING_VERIFICATION` y no puede iniciar sesión ni realizar transacciones hasta consumir su token en `/verificar-correo?token=...`.
- Al verificarse, pasa a estado `ACTIVE` con marca de tiempo UTC.

---

## 2. MÓDULO B: PUBLICACIÓN DE CARGAS

### Asistente de Cinco Etapas (`web/lib/screens/publish_load_screen.dart`)
Se verificó la implementación del asistente interactivo de publicación:
1. **Etapa 1: Origen:** Departamento, municipio/ciudad, dirección exacta de recogida y fecha/hora programada de cargue (`pickupDateUtc`).
2. **Etapa 2: Destino:** Departamento, municipio/ciudad, dirección exacta de descargue y fecha/hora máxima de entrega (`deliveryDateUtc`).
3. **Etapa 3: Características Físicas de la Mercancía:** Tipo de producto (ej. Alimentos, Granel, Paquetería, Construcción), peso en kilogramos (`weightKg`), volumen en metros cúbicos (`volumeM3`), tipo de embalaje (Estibas, Cajas, Sacos) y requerimiento de refrigeración (`requiresRefrigeration: true/false`).
4. **Etapa 4: Requisitos del Vehículo:** Tipología del camión (Tractomula, Doble troque, Sencillo, Turbo, Camioneta) y tipo de carrocería (Furgón, Estacas, Planchón, Refrigerado, Tanque).
5. **Etapa 5: Esquema Económico:** Modalidad de precio (`OFFERED` flete ofrecido por la empresa, o `TO_QUOTE` a convenir/cotizar), monto del flete ofrecido en pesos colombianos, pagador del flete (`REMITTENT` o `CONSIGNEE`) e instrucciones especiales para el conductor.

### Persistencia y Validación
- El backend valida que la cuenta del publicador se encuentre en estado `ACTIVE`.
- La carga se persiste transaccionalmente en la tabla `loads` con estado inicial `PUBLISHED` y un identificador público UUID.

---

## 3. MÓDULO C: CARTELERA DE CARGAS (LOAD BOARD)

### Funcionalidades Verificadas
- **Listado General:** `GET /api/v1/loads` devuelve todas las cargas activas en estado `PUBLISHED`.
- **Filtros Dinámicos:**
  - Por ciudad/municipio de origen (`originCity`).
  - Por ciudad/municipio de destino (`destinationCity`).
  - Por tipo de vehículo requerido (`vehicleType`).
- **Seguridad de Consulta:** La cartelera es pública para lectura, pero la postulación u oferta requiere autenticación obligatoria con rol activo.
- **Detalle de Carga:** Endpoint `GET /api/v1/loads/{id}` expone la totalidad de condiciones físicas y económicas del flete.

---

## 4. MÓDULO D: GEMELO DIGITAL Y SIMULACIÓN DE COSTOS

### Naturaleza del Gemelo Digital en TRAXIA
El Gemelo Digital de TRAXIA es un **modelo matemático determinístico de simulación heurística y predicción de costos directos de transporte** implementado en `SimulationService.java`. No debe confundirse con telemetría GPS vehicular en tiempo real. Su propósito es equilibrar la asimetría de información entre el generador de carga y el transportista antes de negociar.

### Variables y Fórmulas del Modelo

$$\text{Distancia (km)} = \text{Matriz de Corredores Viales Nacionales (Fallback: 380 km)}$$

$$\text{Número de Peajes} = \max\left(1, \left\lfloor\frac{\text{Distancia}}{75}\right\rfloor\right)$$

$$\text{Costo Total Peajes} = \text{Número de Peajes} \times \$14.500\text{ COP}$$

$$\text{Rendimiento Combustible} = f(\text{Tipología Vehicular})$$
- Camioneta: $30.0\text{ km/gal}$
- Turbo: $18.0\text{ km/gal}$
- Sencillo: $12.0\text{ km/gal}$
- Doble troque: $8.0\text{ km/gal}$
- Tractomula: $5.5\text{ km/gal}$

$$\text{Galones ACPM} = \frac{\text{Distancia}}{\text{Rendimiento Combustible}}$$

$$\text{Costo Combustible} = \text{Galones ACPM} \times \$10.500\text{ COP/gal}$$

$$\text{Costo Directo Total} = \text{Costo Combustible} + \text{Costo Peajes}$$

$$\text{Flete Base Sugerido} = \text{Costo Directo Total} \times 1.45\quad (\text{Margen de contingencia y operación del 45\%})$$

### Caso de Prueba Reproducible Verificado en Laboratorio
- **Ruta:** Bogotá $\rightarrow$ Medellín.
- **Vehículo:** Sencillo ($12\text{ km/gal}$).
- **Resultados Calculados y Verificados vía API:**
  - Distancia estimada: **$420\text{ km}$**.
  - Peajes estimados: **5 casetas** ($\lfloor 420/75 \rfloor = 5$).
  - Costo de peajes: **$\$72.500,00\text{ COP}$** ($5 \times 14.500$).
  - Galones ACPM estimados: **$35,00\text{ gal}$** ($420 / 12$).
  - Costo combustible ACPM: **$\$367.500,00\text{ COP}$** ($35 \times 10.500$).
  - Costo directo total: **$\$440.000,00\text{ COP}$** ($367.500 + 72.500$).
  - Flete sugerido con contingencia: **$\$638.000,00\text{ COP}$** ($440.000 \times 1.45$).

---

## 5. MÓDULO E: POSTULACIONES Y OFERTAS (SUBASTA)

### Ciclo de Negociación y Adjudicación
1. **Creación de Oferta:**
   - Transportista autenticado envía monto propuesto y fecha estimada de cargue vía `POST /api/v1/loads/{id}/bids`.
   - Se valida monto mínimo ($>=\$1.000\text{ COP}$).
   - **Regla de Negocio:** El sistema prohíbe explícitamente que el publicador oferte en su propia carga (`BadRequest: "No puedes postularte a tu propia carga publicada"`).
2. **Visibilidad Segregada:**
   - El generador de carga ve la totalidad de las ofertas recibidas.
   - Cada transportista solo puede visualizar su propia oferta, protegiendo la confidencialidad de la subasta.
3. **Aceptación y Cierre de Subasta (`acceptBid`):**
   - El generador de carga selecciona la oferta ganadora y ejecuta `POST /api/v1/bids/{bidId}/accept`.
   - **Acción Transaccional Atómica:**
     - La oferta seleccionada pasa a `ACCEPTED`.
     - La carga pasa a `ASSIGNED`.
     - Todas las ofertas restantes abiertas en esa carga pasan automáticamente a `REJECTED`.
     - Se instancia y guarda un nuevo registro en la tabla `trips` con estado `ASSIGNED` y el monto pactado.
4. **Prevención de Condiciones de Carrera:**
   - Si se intenta aceptar una segunda oferta sobre la misma carga, el backend verifica que `load.getStatus().equals("PUBLISHED")`. Al estar ya en `ASSIGNED`, rechaza la solicitud de inmediato (`IllegalStateException: "Esta carga ya no está disponible para contratación"`).

---

## 6. MÓDULO F: GESTIÓN DE VIAJES

### Máquina de Estados del Viaje
El ciclo de vida del transporte físico sigue una máquina de estados estricta y unidireccional:

```
[ASSIGNED] ──(startTrip)──> [IN_TRANSIT] ──(deliverTrip)──> [DELIVERED]
```

### Reglas de Transición y Control de Roles
1. **Estado Inicial (`ASSIGNED`):**
   - El contrato de viaje se crea automáticamente al aceptar la oferta.
   - Asocia al conductor (`driver_user_id`), la carga (`load_id`), la oferta ganadora (`bid_id`) y el valor pactado (`agreed_amount`).
2. **Inicio de Viaje (`startTrip`):**
   - Endpoint: `POST /api/v1/trips/{id}/start`.
   - **Control de Acceso:** Solo el conductor asignado (`driver_user_id`) puede invocar este endpoint. Si la empresa generadora o un tercero lo intenta, el backend lo rechaza con error de autorización.
   - Efecto: El viaje pasa a `IN_TRANSIT`, la carga vinculada pasa a `IN_TRANSIT` y se registra la estampa `started_at_utc`.
3. **Registro de Entrega (`deliverTrip`):**
   - Endpoint: `POST /api/v1/trips/{id}/deliver`.
   - El conductor reporta la culminación del servicio adjuntando observaciones o notas de remisión (`proofNotes`).
   - Efecto: El viaje pasa a `DELIVERED`, la carga pasa a `DELIVERED`, se registra la estampa `delivered_at_utc` y las notas de entrega quedan inmutables en base de datos.
   - Se registra evento de auditoría `TRIP_DELIVERED`.

---

## 7. MÓDULO G: MÓDULOS ADICIONALES IDENTIFICADOS EN CÓDIGO

Durante la inspección forense del código se identificaron módulos y capacidades adicionales no detallados en el README:
1. **Autenticación Federada Google Identity Services (GIS):**
   - Integración con OIDC mediante la librería oficial de Google API Client (`GoogleIdTokenVerifier`).
   - Flujo de verificación de firma criptográfica de tokens emitidos por Google contra los certificados públicos de Google (`accounts.google.com`).
2. **Perfil de Aprovisionamiento de Administrador (`admin-bootstrap`):**
   - Servicio `AdminBootstrapService.java` habilitado bajo el perfil Spring `admin-bootstrap`.
   - Permite la creación del primer superusuario `ADMIN` en un despliegue limpio mediante variables de entorno seguras (`TRAXIA_BOOTSTRAP_ADMIN_EMAIL` y `TRAXIA_BOOTSTRAP_ADMIN_PASSWORD`), bloqueando cualquier ejecución a través de controladores HTTP.
3. **Inversión y Detección de Robo de Tokens de Refresco:**
   - Mecanismo en `RefreshSessionService` que detecta el reuso de refresh tokens revocados e invalida automáticamente toda la familia de sesiones activas.
4. **Conmutación Dinámica de Tema Visual (Dark/Light Mode):**
   - Widget `ThemeModeToggle` integrado con Riverpod para soporte accesible de interfaz oscura y clara en toda la aplicación.
