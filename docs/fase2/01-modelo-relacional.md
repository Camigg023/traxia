# Fase 2 — Modelo relacional propuesto

**Estado:** diseño documental; pendiente de revisión de la propietaria.  
**Plataforma:** Flutter Web responsive → API Spring Boot → MySQL 8.x.  
**Alcance:** cubre las áreas del Documento Maestro y la rebanada vertical propuesta. No crea SQL ni migraciones ejecutables.

## 1. Convenciones de almacenamiento

| Aspecto | Convención propuesta |
|---|---|
| Identificador interno | `BIGINT` firmado, compatible directamente con `Long` en Java. Clave primaria técnica, no expuesta en URLs públicas. |
| Identificador público | `BINARY(16)` con UUID; generar y convertir mediante una única utilidad del backend. Revisar compatibilidad ORM/migración durante scaffolding. |
| Texto | `utf8mb4`; collation uniforme elegida al confirmar versión MySQL y reglas de comparación de correo. |
| Instantes | `DATETIME(6)` UTC por convención; columnas terminan en `_at_utc`. MySQL `DATETIME` no conserva zona horaria: backend convierte en entrada/salida. |
| Fechas civiles | `DATE` para vencimientos o fecha local sin instante, según el significado del dato. No convertir fechas de vencimiento en medianoche UTC sin regla de negocio. |
| Valores económicos | `DECIMAL` exacto, nunca `FLOAT`/`DOUBLE`; moneda almacenada como código ISO (inicialmente COP) y escala definida al confirmar reglas financieras. No se precargan tarifas. |
| Magnitudes físicas | `DECIMAL` con escala explícita por unidad; guardar unidad cuando haya más de una representación posible. |
| Coordenadas | `DECIMAL` con precisión acordada en el diseño técnico. No registrar un punto si no se conoce hora/procedencia/permiso aplicable. |
| Estados | `VARCHAR` con códigos estables; transición validada en servicio y registrada en historial. No usar ordinales numéricos. Catálogo de estados o `CHECK` dependerá de versión MySQL fijada. |
| Eliminación | No usar borrado en cascada para registros contractuales, financieros, auditoría o evidencia. Retención/eliminación de información personal queda sujeta a política legal pendiente. |
| Optimistic locking | Columna `version BIGINT` en registros susceptibles a concurrencia, mapeada a `@Version` en JPA. |
| Auditoría técnica | Tablas de negocio incluyen `created_at_utc`, `updated_at_utc`, `created_by_user_id`/`updated_by_user_id` cuando aplique. El historial de estados se almacena aparte. |

### Tipos físicos candidatos para el esquema MySQL

Estos tipos concretan el diseño a nivel lógico-físico, pero son propuestas que deben probarse en la versión MySQL objetivo antes de migrar:

| Clase de columna | Tipo propuesto | Notas |
|---|---|---|
| PK/FK internos | `BIGINT` | Sin `UNSIGNED`, para mapeo Java `Long` consistente. |
| UUID público | `BINARY(16)` | Representación compacta; conversión a UUID textual canónico en el backend. |
| `email_normalized` | `VARCHAR(254)` | Longitud técnica candidata; validar normalización/collation y unicidad. |
| Código/estado/enum lógico | `VARCHAR(32)` o `VARCHAR(64)` | No usar ordinal; tamaño debe admitir evolución sin truncar. |
| Nombre/título | `VARCHAR(160)` o `VARCHAR(255)` | Validar con requisitos de UX y origen de dato. |
| Descripción/mensaje | `TEXT` con límite de longitud aplicado por API | No persistir contenido ilimitado. |
| Datos estructurados snapshot/configuración | `JSON` | Solo estructura versionada; no guardar secretos ni PII innecesaria. |
| Importe económico | `DECIMAL(19,4)` candidato + `CHAR(3)` para moneda | Precisión/escala final depende de contabilidad y operaciones; no implica tarifa definida. |
| Peso/volumen | `DECIMAL(18,4)` candidato + código de unidad | No convertir unidades sin regla explícita. |
| Latitud/longitud | `DECIMAL(10,7)` candidato | Validar rangos y precisión; ubicación precisa requiere permiso y retención aprobada. |
| Fecha sin hora | `DATE` | Por ejemplo, vencimiento que legalmente se expresa como fecha civil. |
| Instante | `DATETIME(6)` | Siempre UTC según contrato de aplicación; validar serialización. |
| Hash de token/checksum | `VARBINARY` o formato binario/textual específico | Algoritmo, tamaño y formato se fijan en decisión de seguridad; nunca almacenar token en claro. |
| Versión de concurrencia | `BIGINT` | Incremento monotónico por actualización del agregado. |
| Booleano | `BOOLEAN`/`TINYINT(1)` | El backend normaliza representación; no usar como sustituto de un estado con transiciones. |

Los tamaños indicados son valores iniciales de diseño, no límites de negocio ni afirmaciones legales. Se validarán con datos sintéticos y Bean Validation antes de Fase 3.

## 2. Catálogo propuesto de entidades

Los tipos son lógicos hasta la definición física de columnas, longitudes, escalas y nulabilidad. `PK`, `FK` y `UK` identifican claves; cada entidad principal tendrá UUID público.

### 2.1 Identidad, roles y acceso

| Tabla | Propósito | Claves y campos principales | Notas |
|---|---|---|---|
| `users` | Cuenta base de persona. | PK `id`; UK `public_id`; `email_normalized` UK nullable según política; `phone_e164` nullable; `status`; `email_verified_at_utc`; `version`. | No guardar contraseña aquí si credenciales se aíslan en métodos de acceso. Evitar filtrar existencia de cuenta. |
| `roles` | Catálogo de roles. | PK `id`; UK `code`; `name_es`; `description`. | Códigos internos en inglés; etiqueta de UI en español. |
| `permissions` | Acciones autorizables. | PK `id`; UK `code`; `description`. | Denegar por defecto. |
| `user_roles` | Roles asignados a usuario y, opcionalmente, organización. | PK `id`; FK `user_id`, `role_id`; FK `company_id` nullable; UK compuesta de asignación. | Permite rol por empresa/sede sin elevar todos los contextos del usuario. |
| `role_permissions` | Relación rol-permiso. | PK compuesta o `id`; FK `role_id`, `permission_id`; UK pareja. | Semilla de catálogo, no permisos definidos desde UI. |
| `auth_methods` | Correo/contraseña y proveedores federados. | PK `id`; FK `user_id`; `provider_code`; `provider_subject` nullable; `credential_hash` nullable; `verified_at_utc`; estado. | UK (`provider_code`, `provider_subject`) y, según política, una credencial de correo por cuenta. Nunca texto plano. |
| `account_recovery_requests` | Intentos/casos de recuperación. | PK `id`; FK `user_id` nullable; `channel`; `token_hash`; `expires_at_utc`; `consumed_at_utc`; estado; metadata mínima. | Token de un solo uso como hash; límites y respuestas que no enumeren cuentas. No guardar rostro como factor único. |
| `terms_acceptances` | Evidencia de aceptación. | PK `id`; FK `user_id`; `terms_type`; `document_version`; `accepted_at_utc`; revocación si aplica. | Versión del texto y evidencia necesaria se definen en privacidad/legal. |
| `user_preferences` | Apariencia, avisos y preferencias regionales. | PK `id`; FK `user_id`; `preference_key`; valor tipado/JSON; `updated_at_utc`. | UK (`user_id`, `preference_key`); no guardar secretos. |

### 2.2 Empresas, sedes, conductores y vehículos

| Tabla | Propósito | Claves y campos principales | Notas |
|---|---|---|---|
| `companies` | Empresa generadora o transportadora/legalizadora. | PK `id`; UK `public_id`; `company_type`; `legal_name`; `tax_identifier` protegido/normalizado; `status`; `version`. | Permitir una empresa con más de una función solo si el negocio lo aprueba; perfil se expresa en tipo/relación, no inferir por nombre. |
| `company_branches` | Sedes de empresa. | PK `id`; FK `company_id`; `name`; dirección; datos de ubicación opcionales/protegidos; estado. | UK definida por regla de sede (por ejemplo código interno), no asumir dirección única. |
| `company_memberships` | Vinculación de usuario con empresa. | PK `id`; FK `company_id`, `user_id`; FK `branch_id` nullable; `membership_role`; estado; intervalos UTC. | Revocar sin borrar historial. |
| `carrier_profiles` | Datos propios de transportadora/legalizadora. | PK `id`; FK `company_id` UK; estado de revisión; referencias documentales. | No equivale a habilitación oficial. |
| `driver_profiles` | Datos laborales/operativos del conductor. | PK `id`; FK `user_id` UK; estado; preferencias operativas mínimas. | Evitar duplicar PII ya presente en `users`. |
| `fleets` | Agrupación de vehículos de transportadora. | PK `id`; UK `public_id`; FK `company_id`; `name`; estado. | Una flota puede tener cero o más vehículos. |
| `vehicles` | Unidad de transporte. | PK `id`; UK `public_id`; FK `company_id`; FK `fleet_id` nullable; FK `branch_id` nullable; placa normalizada UK según jurisdicción; clase; capacidad y unidad; estado; `version`. | Compatibilidad se evalúa en dominio; restricciones locales no bastan para interpretar regulación. |
| `driver_vehicle_links` | Relación conductor-vehículo con vigencia. | PK `id`; FK `driver_profile_id`, `vehicle_id`; tipo de relación; fechas UTC; estado. | Historial temporal; restricción de conductor/vehículo activo se define en §4. |
| `recurring_trip_plans` | Regla/plantilla de recurrencia. | PK `id`; UK `public_id`; FK `company_id`; definición de calendario; ruta/condiciones base; vigencia; estado. | Una regla genera viajes independientes; no almacenar ocurrencias como un solo viaje. |

### 2.3 Documentos, verificación e IA

| Tabla | Propósito | Claves y campos principales | Notas |
|---|---|---|---|
| `file_objects` | Referencias a objetos privados. | PK `id`; UK `public_id`; `object_key` UK; `category`; `storage_provider`; `content_type`; tamaño; checksum; `uploaded_at_utc`; vencimiento URL no se persiste como URL permanente. | Los bytes residen en almacenamiento privado, no MySQL. Nunca guardar credenciales/URLs firmadas reutilizables. |
| `documents` | Documento lógico del usuario/empresa/vehículo. | PK `id`; UK `public_id`; FK nullable a `user_id`, `company_id`, `vehicle_id`; FK `file_object_id`; tipo; número protegido si es necesario; emisión/vencimiento; estado. | CHECK/servicio garantiza un solo sujeto válido; no replicar dato sensible sin finalidad. |
| `verification_requests` | Solicitud de revisión de una identidad o empresa. | PK `id`; UK `public_id`; FK nullable `user_id`/`company_id`; estado; motivo; `submitted_at_utc`; `version`. | Exactamente un sujeto; solicitudes sucesivas preservan historial. |
| `document_reviews` | Revisión humana o asistida. | PK `id`; FK `verification_request_id`, `document_id`; FK `reviewer_user_id` nullable; tipo de revisión; resultado; razón; timestamp. | Resultado IA es sugerencia, no aprobación automática. |
| `verification_events` | Historial append-only de transiciones. | PK `id`; FK `verification_request_id`; estado anterior/nuevo; actor; motivo; fecha. | Auditoría funcional complementaria a `audit_events`. |
| `company_state_events` | Historial de estados de empresa/transportadora. | PK `id`; FK `company_id`; estado anterior/nuevo; actor; motivo; fecha. | Append-only; revisión en TRAXIA no equivale a habilitación oficial. |
| `biometric_records` | Metadata de una sesión de verificación biométrica, si se autoriza. | PK `id`; FK `user_id`; FK `file_object_id` nullable; proveedor; consentimiento FK; estado; fecha; eliminación programada. | No es necesaria en MVP real; separar categoría y permisos; nunca enviar a LLM. Requiere validación legal y retención aprobada. |
| `ai_assessments` | Resultado de apoyo de IA. | PK `id`; FK opcional solicitud/documento; proveedor/modelo; versión de prompt; confianza; explicación; resultado estructurado; `provenance`; fecha. | Evitar persistir prompts con PII innecesaria; incluir revisión humana y estado; contenido subido es no confiable. |
| `consent_records` | Evidencia de consentimiento específico. | PK `id`; FK `user_id`; propósito; versión de aviso; otorgado/revocado; timestamps. | Consentimiento no se deduce por iniciar flujo. |

### 2.4 Cargas, ofertas, contratación y ejecución

| Tabla | Propósito | Claves y campos principales | Notas |
|---|---|---|---|
| `loads` | Publicación de carga. | PK `id`; UK `public_id`; FK `shipper_company_id`; FK `branch_id`; estado; fechas de recogida/entrega; origen/destino; moneda; `version`. | Borrador en pasos; direcciones/geo con protección y procedencia cuando aplique. |
| `load_state_events` | Historial de publicación y estado de carga. | PK `id`; FK `load_id`; from/to; actor; motivo; fecha. | Append-only; ninguna publicación queda contratada antes de completar el flujo. |
| `load_cargo_details` | Mercancía y restricciones físicas. | PK `id`; FK `load_id` UK; descripción; tipo; peso/volumen y unidad; cantidad; requisitos. | No colocar información pública más allá de permisos y propósito. |
| `load_vehicle_requirements` | Compatibilidad declarada. | PK `id`; FK `load_id`; tipo de vehículo y requisitos; capacidad mínima/unidad. | Reglas exactas y categorías legales pendientes. |
| `load_conditions` | Condiciones económicas/operativas de carga. | PK `id`; FK `load_id` UK; pagador; valor acordado nullable; política/configuración referenciada; notas; moneda. | No precargar comisión ni penalidad. |
| `load_stops` | Origen, destino y paradas. | PK `id`; FK `load_id`; secuencia; tipo; datos de ubicación; ventana temporal. | Dirección/ubicación con acceso restringido. |
| `bids` | Oferta sobre carga. | PK `id`; UK `public_id`; FK `load_id`, `bidder_user_id`; valor/moneda; estado; mensaje seguro; `version`. | El contacto no se contiene aquí antes de contratación. |
| `bid_events` | Historial de negociación. | PK `id`; FK `bid_id`; actor; tipo de evento; valor propuesto; fecha. | Append-only; no sobrescribir contraofertas anteriores. |
| `contracts` | Registro del acuerdo tras confirmaciones. | PK `id`; UK `public_id`; FK `load_id`, `bid_id`; estado; snapshot de términos; fecha de confirmación; `version`. | Una carga puede tener historial contractual; un solo contrato activo. |
| `contract_confirmations` | Confirmaciones de cada parte/paso. | PK `id`; FK `contract_id`, `user_id`; paso/términos versionados; resultado; fecha; UK por contrato, usuario y paso/version. | Contratado solo al completar conjunto requerido. |
| `contract_state_events` | Historial de estado contractual. | PK `id`; FK `contract_id`; estado anterior/nuevo; actor; motivo; fecha. | Append-only; un cambio de términos requiere nueva confirmación. |
| `trips` | Ejecución de transporte. | PK `id`; UK `public_id`; FK `load_id`; FK `contract_id` nullable UK; FK `recurring_trip_plan_id` nullable; estado; plan/start/end; `version`. | Cada ocurrencia recurrente es una fila independiente. Una ejecución publicada/activa requiere la relación contractual definida por el flujo aprobado; las instancias aún no contratadas pueden carecer de contrato. |
| `trip_state_events` | Historial de estados del viaje. | PK `id`; FK `trip_id`; from/to; actor; motivo; fecha; idempotency reference nullable. | Append-only. |
| `assignments` | Historial de conductor/vehículo por viaje. | PK `id`; FK `trip_id`, `driver_profile_id`, `vehicle_id`; FK `carrier_company_id` nullable; estado; vigencia UTC. | Permite reasignaciones históricas; recursos activos se bloquean aparte. |
| `assignment_state_events` | Historial de asignación y reasignación. | PK `id`; FK `assignment_id`; estado anterior/nuevo; actor; motivo; fecha. | Append-only; conserva recursos anteriores. |
| `active_load_contracts` | Exclusividad de contrato activo por carga. | PK/FK `load_id`; FK `contract_id` UK; fecha de activación. | Se elimina solo el lock al cerrar/cancelar, nunca el historial contractual. |
| `active_trip_assignments` | Asignación actual de un viaje. | PK/FK `trip_id`; FK `assignment_id` UK; fecha de activación. | Como máximo una asignación actual por viaje; una UK/FK compuesta valida que `assignment_id` pertenezca al mismo viaje. |
| `active_driver_assignments` | Exclusividad de conductor en viajes activos. | PK/FK `driver_profile_id`; FK `trip_id` UK; FK `assignment_id`; fecha de activación. | Una fila por conductor activo; FK compuesta asegura que el conductor corresponda a esa asignación/viaje. |
| `active_vehicle_assignments` | Exclusividad de vehículo en viajes activos. | PK/FK `vehicle_id`; FK `trip_id` UK; FK `assignment_id`; fecha de activación. | Una fila por vehículo activo; FK compuesta asegura que el vehículo corresponda a esa asignación/viaje. |

### 2.5 Gemelo digital, ruta, costos y ubicación

| Tabla | Propósito | Claves y campos principales | Notas |
|---|---|---|---|
| `route_plans` | Ruta acordada/propuesta para un viaje. | PK `id`; FK `trip_id`; versión; proveedor; estado; fecha y procedencia. | Revisar cardinalidad (plan actual y versiones históricas) durante diseño detallado. |
| `route_stops` | Paradas ordenadas del plan. | PK `id`; FK `route_plan_id`; secuencia; coordenadas/dirección; fecha planificada; procedencia. | No prometer ETA externa si proveedor falla. |
| `trip_simulations` | Instantánea inmutable de una simulación. | PK `id`; UK `public_id`; FK `trip_id`/`route_plan_id`; entradas/salidas snapshot; proveedor/fuente; fecha; etiqueta. | Solo insertar; nunca actualizar resultado. Retención/versionado por definir. |
| `data_sources` | Catálogo técnico de orígenes conocidos. | PK `id`; UK `code`; nombre; clase; enlace/nota de fuente; estado. | No implica validación legal ni que una fuente externa esté activa. |
| `toll_tariffs` | Configuración de peaje por estación/ruta/vehículo si hay fuente validada. | PK `id`; UK `public_id`; nombre/categoría; tarifa exacta; moneda; `source_id`; `observed_at_utc`; vigencia; etiqueta procedencia. | Valores de ejemplo solo en fixture rotulado SIMULADO; no sembrar tarifa real sin fuente. |
| `quotes` | Cálculo estimado/cotización inmutable por versión. | PK `id`; UK `public_id`; FK nullable `trip_id`/`load_id`; importe/moneda; snapshot de supuestos; fuente; fecha; tipo de procedencia. | Exactamente uno de los dos contextos; cada recálculo crea versión y se distingue del precio acordado. |
| `location_points` | Muestras autorizadas durante un viaje. | PK `id`; FK `trip_id`, `user_id`; coordenadas; precisión; observed/received UTC; fuente; consentimiento/session ref. | Acceso restringido, retención limitada aún pendiente y consultas paginadas. |
| `expenses` | Gastos declarados. | PK `id`; UK `public_id`; FK `trip_id`, `user_id`; tipo; valor/moneda; fecha de ocurrencia; fuente; sync status; comprobante nullable. | Un registro local sin sincronizar no es gasto confirmado por servidor. |

### 2.6 Entrega, comunicación, liquidación y confianza

| Tabla | Propósito | Claves y campos principales | Notas |
|---|---|---|---|
| `incidents` | Incidencia o avería. | PK `id`; UK `public_id`; FK `trip_id`, `reported_by_user_id`; tipo; descripción; estado; timestamps. | Puede originar reasignación/reclamación; no cambia contrato automáticamente. |
| `deliveries` | Registro de recogida/entrega. | PK `id`; UK `public_id`; FK `trip_id`; registrado por; estado; cantidades declaradas/recibidas; fecha; receptor. | Discrepancia abre incidencia o reclamación según flujo aprobado. |
| `delivery_evidence` | Enlace de evidencia a entrega. | PK `id`; FK `delivery_id`, `file_object_id`; tipo; capturado por; fecha; hash. | Acceso restringido; archivos privados. |
| `settlements` | Resumen informativo de liquidación. | PK `id`; UK `public_id`; FK `trip_id` UK; estado; moneda; importes acordados/calculados; fecha; `version`. | No representa dinero custodiado por TRAXIA. |
| `settlement_entries` | Componentes del cálculo económico. | PK `id`; FK `settlement_id`; tipo; importe; fuente (gasto/acuerdo/ajuste); referencia; fecha. | Ajustes requieren actor/motivo y no alteran fuente original. |
| `settlement_state_events` | Historial de estado informativo de liquidación. | PK `id`; FK `settlement_id`; estado anterior/nuevo; actor; motivo; fecha. | Append-only; no certifica transferencia de fondos. |
| `settlement_disputes` | Desacuerdos sobre liquidación. | PK `id`; FK `settlement_id`, `opened_by_user_id`; motivo; estado; resolución. | Sin procesar pagos. |
| `conversations` | Espacio de chat. | PK `id`; UK `public_id`; estado. | El contexto se guarda en tabla tipada con FKs reales. |
| `conversation_contexts` | Vincula conversación a una carga, contrato o viaje. | PK/FK `conversation_id`; FK nullable `load_id`, `contract_id`, `trip_id`. | Exactamente un contexto no nulo; aplicar CHECK compatible o validación transaccional. |
| `conversation_participants` | Membresía de chat. | PK `id`; FK `conversation_id`, `user_id`; joined/left UTC; UK de membresía activa. | Verificar permiso en cada lectura/escritura. |
| `chat_messages` | Mensaje. | PK `id`; UK `public_id`; FK `conversation_id`, `author_user_id`; texto; fecha; estado. | Cifrado/retención y moderación deben definirse antes de producción. |
| `message_attachments` | Asociación de mensaje a archivo. | PK `id`; FK `chat_message_id`, `file_object_id`. | Analizar contenido/virus en política de archivos futura. |
| `anti_evasion_events` | Señales de datos de contacto. | PK `id`; FK `conversation_id`, `chat_message_id`; tipo/regla/versión; fecha; revisión. | No usar como sanción automática; minimizar contenido almacenado. |
| `ratings` | Calificación vinculada a viaje completado. | PK `id`; FK `trip_id`, `reviewer_user_id`, `reviewed_user_id`; puntuaciones/categorías; fecha; estado. UK (`trip_id`, `reviewer_user_id`, `reviewed_user_id`). | Solo viaje completado; política de ventana temporal pendiente. |
| `claims` | Reclamación formal. | PK `id`; UK `public_id`; FK `trip_id`, `opened_by_user_id`; tipo; estado; asignado a revisor; resolución. | Restringir evidencia y acceso por parte. |
| `benefits` | Catálogo de beneficios. | PK `id`; UK `code`; reglas configurables; periodo; estado. | Sin prometer beneficio externo sin acuerdo. |
| `benefit_grants` | Beneficio concedido a usuario o empresa por regla. | PK `id`; FK `benefit_id`; FK nullable `user_id`/`company_id`; FK opcional `trip_id`; estado; explicación; fecha. | Exactamente un receptor; CHECK compatible o validación transaccional. |

### 2.7 Operación, notificaciones, auditoría y reportes

| Tabla | Propósito | Claves y campos principales | Notas |
|---|---|---|---|
| `notifications` | Aviso de aplicación a usuario. | PK `id`; UK `public_id`; FK `user_id`; categoría; texto/template code; estado; fecha. | Evitar contenido sensible en push/email. |
| `notification_preferences` | Configuración por tipo/canal. | PK `id`; FK `user_id`; categoría/canal; enabled; UK (`user_id`, categoría, canal). | Alertas esenciales/legales no se silencian sin regla aprobada. |
| `notification_deliveries` | Intentos de entrega por canal. | PK `id`; FK `notification_id`; canal/proveedor; estado; respuesta redactada; fecha/reintento. | No guardar tokens push en registros de logs. |
| `audit_events` | Registro append-only de acciones sensibles. | PK `id`; actor; acción; entidad/tipo/id; resultado; razón; request/correlation ID; fecha; metadata minimizada. | Sin UPDATE/DELETE por usuario de aplicación; acceso de lectura restringido. |
| `system_parameters` | Parámetros administrables versionados. | PK `id`; UK `parameter_code`; valor tipado/JSON; estado; vigencia; version. | Comisión/penalidades no se activan con valores inventados; cambios auditados. |
| `system_parameter_events` | Historial de cambios de parámetros. | PK `id`; FK `system_parameter_id`; valor previo/nuevo; actor; razón; fecha. | Append-only. |
| `report_jobs` | Solicitud/estado de reporte generado. | PK `id`; UK `public_id`; FK `requested_by_user_id`; tipo; filtros snapshot; estado; archivo temporal; expiración. | Aplicar autorización y expiración al exportar. |
| `idempotency_records` | Deduplicar escrituras/reintentos críticos. | PK `id`; FK `user_id`; scope; key; request hash; resultado/status ref; expiración. UK (`user_id`, `scope`, `key`). | No guardar secretos en respuesta cacheada; definir retención. |
| `sync_operations` | Idempotencia y diagnóstico de sincronización web offline. | PK `id`; FK `user_id`; `client_operation_id`; tipo; estado; resultado; timestamps. UK (`user_id`, `client_operation_id`). | La persistencia principal de cola vive en cliente; solo acciones permitidas se sincronizan. |

## 3. Integridad y relaciones principales

- `Load` pertenece a empresa generadora y puede recibir muchas ofertas; la contratación válida origina viaje y snapshot de condiciones.
- `Company` tiene sedes, miembros, flotas y vehículos; conductor se modela aparte y se relaciona temporalmente con vehículo.
- `Trip` conserva cambios, asignaciones y ubicaciones históricas; reasignar no sobrescribe asignaciones previas.
- `RecurringTripPlan` es plantilla; cada instancia generada apunta a ella pero es un `Trip` independiente.
- `VerificationRequest` y `DocumentReview` distinguen solicitante, sujeto, revisor humano y asistencia IA.
- `Simulation` conserva entradas/resultados, fuente y fecha; un cambio produce una nueva simulación, no edición.
- `Quote`, `TollTariff`, `LocationPoint` y `Expense` mantienen procedencia y timestamps para diferenciar confirmado/estimado/simulado.
- `Settlement` consolida información y no ejecuta transferencia. Datos sobre pagos reportados por partes son declaraciones/evidencias.
- `AuditEvent` y eventos de estado son históricos; no sustituyen el estado actual, pero permiten reconstruirlo y revisarlo.

### Cobertura de las 20 áreas del Documento Maestro (§30)

| Área | Tablas principales |
|---|---|
| Usuarios, roles y permisos | `users`, `roles`, `permissions`, `user_roles`, `role_permissions` |
| Métodos de acceso | `auth_methods`, `account_recovery_requests`, `terms_acceptances` |
| Empresas y representantes | `companies`, `company_memberships`, `company_branches` |
| Conductores y perfiles | `driver_profiles`, `driver_vehicle_links` |
| Vehículos y documentación | `vehicles`, `fleets`, `documents`, `file_objects` |
| Solicitudes de verificación | `verification_requests`, `document_reviews`, `verification_events`, `biometric_records`, `ai_assessments` |
| Cargas y viajes | `loads`, `load_cargo_details`, `load_vehicle_requirements`, `load_conditions`, `trips`, `recurring_trip_plans` |
| Ofertas y asignaciones | `bids`, `bid_events`, `contracts`, `contract_confirmations`, `assignments`, `active_*` |
| Transportadoras y gestiones | `carrier_profiles`, `company_state_events`, `fleets`, `vehicles` |
| Rutas y paradas | `route_plans`, `route_stops`, `load_stops` |
| Simulaciones del gemelo digital | `trip_simulations` |
| Cotizaciones y gastos | `quotes`, `expenses`, `toll_tariffs`, `data_sources` |
| Seguimiento y ubicaciones | `location_points` |
| Incidencias y entregas | `incidents`, `deliveries`, `delivery_evidence` |
| Mensajes y notificaciones | `conversations`, `conversation_contexts`, `conversation_participants`, `chat_messages`, `notifications`, `notification_deliveries` |
| Pagos y liquidaciones | `settlements`, `settlement_entries`, `settlement_disputes`, `settlement_state_events` |
| Calificaciones y reclamaciones | `ratings`, `claims` |
| Beneficios y recompensas | `benefits`, `benefit_grants` |
| Auditorías | `audit_events`, `trip_state_events`, `load_state_events`, `contract_state_events`, `assignment_state_events` |
| Reportes | `report_jobs` |

## 4. Alcance aplazado o sujeto a decisión

- No se fijan reglas de precio, escala monetaria, penalidades, ventanas de calificación, retención biométrica, reglas de beneficios ni requisitos legales.
- El modelo de conversación debe resolver FK de contexto sin una referencia polimórfica sin integridad antes de generar migraciones.
- La forma exacta de almacenar direcciones/coordenadas y las tablas de categorías oficiales depende de fuente/cobertura y privacidad.
- Cifrado en reposo, claves y separación física de buckets requieren configuración del entorno; la referencia de tabla no los implementa.
- Los registros de ubicación/biometría tienen alta sensibilidad; solo se crearán para una finalidad autorizada, minimizando campos y definiendo borrado legal.
