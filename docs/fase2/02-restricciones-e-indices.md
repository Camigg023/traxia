# Fase 2 — Restricciones, concurrencia e índices

Este documento define controles a implementar después de aprobar el modelo. Las restricciones de base de datos complementan —no reemplazan— la autorización y las reglas del dominio en Spring Boot.

## 1. Claves y relaciones

- Todas las entidades con vida propia tienen PK técnica `BIGINT`, UUID público único cuando se expongan externamente y FK explícita.
- Usar `ON DELETE RESTRICT` en viajes, cargas contratadas, ofertas, contratos, liquidaciones, documentos revisados, eventos de estado y auditoría.
- Usar `ON DELETE CASCADE` solo para asociaciones puramente dependientes sin valor histórico (por ejemplo `role_permissions`), tras revisar retención y auditoría.
- `ON DELETE SET NULL` únicamente para referencias opcionales en las que la eliminación esté permitida y no destruya trazabilidad.
- Aplicar `NOT NULL` a claves, estados y marcas de tiempo requeridos; no emplear cadenas vacías para representar dato desconocido.
- Las columnas FK deben coincidir exactamente en tipo y signo con la PK referenciada. Crear índice en cada FK no cubierto por un índice compuesto.
- Normalizar correo/teléfono/placa en backend con reglas documentadas; conservar el dato de presentación separado cuando sea necesario. La collation se elige tras revisar equivalencias/acento y mayúsculas.

## 2. Unicidad recomendada

| Dominio | Restricción |
|---|---|
| Identidad pública | UK única por `public_id` en cada entidad publicable. |
| Correo de acceso | UK sobre `email_normalized` cuando exista; confirmar política de cuentas con más de un método de correo. |
| Identidad federada | UK (`provider_code`, `provider_subject`) en `auth_methods`; no unir automáticamente cuentas por correo coincidente. |
| Rol y permiso | UK (`role_id`, `permission_id`) y UK en asignación de rol dentro del contexto organizacional. Para roles globales y de empresa, resolver la nulabilidad del contexto con índices generados/separados o catálogo explícito antes de la migración. |
| Membresía | Evitar más de una membresía activa duplicada para mismo usuario/empresa/sede; usar llave natural acordada o tabla de vigencias. Si admite membresías históricas, validar que no existan intervalos activos solapados. |
| Vehículo | UK sobre placa normalizada por jurisdicción/país; revisión legal y de formatos pendiente. |
| Flota | FK de `fleet.company_id` debe coincidir con empresa propietaria del vehículo; comprobar en servicio o reforzar con clave compuesta. |
| Solicitud de verificación | Permitir historial de solicitudes; índice filtrado no está disponible en todas las versiones MySQL. Controlar solicitud abierta mediante transacción y una tabla de bloqueo activa o clave activa nullable. |
| Oferta | UK (`load_id`, `bidder_user_id`) para una oferta vigente por postor; cambios/contraofertas se escriben en `bid_events`. Si el producto permite múltiples ofertas independientes, revisar esta regla antes de migrar. |
| Contratación activa de carga | Tabla `active_load_contracts` con PK/FK `load_id` y FK a `contracts`; solo una contratación en curso por carga. El historial permanece en `contracts`. |
| Asignación activa por viaje | Tabla `active_trip_assignments` con PK/FK `trip_id` y FK a la asignación actual; impide más de una asignación activa por viaje. |
| Exclusividad de conductor/vehículo | Tablas `active_driver_assignments` (PK/FK `driver_profile_id`) y `active_vehicle_assignments` (PK/FK `vehicle_id`), cada una con UK `trip_id` y FK a `assignment_id`; una persona/vehículo y un viaje solo están activos en una asignación por vez. |
| Confirmación de contrato | UK (`contract_id`, `user_id`, `step_code`, `terms_version`) para impedir duplicar confirmación del mismo paso; cambios de términos originan nueva versión y confirmación nueva. |
| Calificación | UK (`trip_id`, `reviewer_user_id`) para una calificación emitida por parte y viaje; revisar modelo si una empresa puede tener varios evaluadores. |
| Preferencias y notificaciones | UK (`user_id`, `preference_key`) y UK (`user_id`, `category`, `channel`) según modelo. |
| Idempotencia | UK (`user_id`, `scope`, `idempotency_key`) y retención suficiente para cubrir reintentos esperados. |
| Sincronización | UK (`user_id`, `client_operation_id`); usar identificador generado por cliente y repetible al reintentar. |
| Auditoría | No impedir eventos legítimos por valores de contenido; correlation ID puede ser UK solo dentro de ámbito si política lo requiere. |

### Tablas de exclusividad activas

Las tablas activas recomendadas son:

- `active_load_contracts(load_id PK/FK, contract_id UK/FK, activated_at_utc)`.
- `active_trip_assignments(trip_id PK/FK, assignment_id UK/FK, activated_at_utc)`.
- `active_driver_assignments(driver_profile_id PK/FK, trip_id UK/FK, assignment_id FK, activated_at_utc)`.
- `active_vehicle_assignments(vehicle_id PK/FK, trip_id UK/FK, assignment_id FK, activated_at_utc)`.

La tabla `assignments` debe exponer UK compuestas `(trip_id, assignment_id)`, `(trip_id, assignment_id, driver_profile_id)` y `(trip_id, assignment_id, vehicle_id)` para que las tablas activas validen con FKs compuestas que viaje, conductor, vehículo y asignación coinciden. Al confirmar contratación/asignación, crear todos los bloqueos en una transacción y actualizar el registro de estado correspondiente. Una colisión de PK/UK cancela la transacción completa y se traduce a un conflicto de negocio comprensible. Una cancelación/reasignación libera las llaves activas en la misma transacción, pero conserva `contracts`, `assignments` y eventos históricos. Cada tabla de lock usa FKs concretas; no usar `resource_type + resource_id` polimórfico sin integridad referencial.

## 3. Estados y restricciones de valores

- Estados de cuentas, verificaciones, cargas, contratos, viajes, asignaciones, liquidaciones, incidencias y reclamaciones se persisten como códigos `VARCHAR` estables.
- Cada agregado tiene una única fuente de transición (servicio de dominio); no permitir actualizaciones directas desde controladores o SQL de administración sin auditoría.
- Mantener historial `*_events` append-only para reconstruir `from_state`, `to_state`, actor, fecha y motivo.
- Usar `CHECK` para condiciones locales simples (por ejemplo importe no negativo solo si la regla lo confirma, coordenadas dentro de rango, exactamente un sujeto de verificación), **solo después de fijar y probar la versión MySQL mínima que lo soporta**.
- No simular una transición válida mediante `UPDATE` directo. La transacción debe comprobar estado esperado, versión y permisos.
- No restringir una moneda a solo COP en esquema si se prevé expansión; MVP presenta COP, las monedas permitidas son decisión de producto.
- Cifras como peso, volumen o rating requieren unidad/rango aprobado; no inventar límites regulatorios en constraints.

## 4. Transacciones y condiciones de carrera

### Contratación

1. Validar autorización y clave de idempotencia.
2. Iniciar transacción MySQL/InnoDB.
3. Leer/bloquear carga y contrato/oferta en un orden consistente (`SELECT ... FOR UPDATE`) o comparar `version`.
4. Verificar oferta elegida, términos, confirmaciones y estado esperado.
5. Crear contrato e insertar `active_load_contracts`.
6. Crear viaje y registro de transición inicial.
7. Insertar/activar asignación y locks de conductor y vehículo, si ya se conocen.
8. Escribir auditoría y resultado de idempotencia.
9. Commit; ante cualquier conflicto, rollback completo y respuesta de conflicto controlada.

### Asignación y reasignación

- Adquirir bloqueos de recursos en orden fijo para evitar deadlocks (por ejemplo tipos y luego IDs ascendentes).
- Insertar en una transacción los locks de viaje, conductor y vehículo.
- Validar vigencia de documentos/capacidad en el servicio; el lock garantiza exclusividad, no compatibilidad.
- Liberar la asignación anterior solo cuando la nueva esté validada y confirmada, según flujo; registrar el intervalo y actor.
- Implementar reintento limitado únicamente ante deadlocks transitorios y con idempotencia.

### Edición concurrente

- Aplicar `version` a carga, oferta, contrato, viaje, verificación y liquidación según necesidad.
- Actualización condicional `WHERE id = ? AND version = ?`; cero filas actualizadas significa versión en conflicto.
- Evitar una transacción extensa mientras usuario completa un formulario o confirma desde navegador.

## 5. Índices secundarios propuestos

Los nombres son convenciones sugeridas (`ix_<tabla>_<columnas>`, `uk_...`, `fk_...`). El orden definitivo se valida con consultas representativas y `EXPLAIN`; índices cuestan espacio y escritura.

| Tabla | Índice/campos | Propósito |
|---|---|---|
| `users` | `uk_users_public_id(public_id)`; `uk_users_email_normalized(email_normalized)` | Consulta pública y autenticación. |
| `auth_methods` | `uk_auth_provider_subject(provider_code, provider_subject)`; `ix_auth_user(user_id, status)` | OIDC y métodos del usuario. |
| `user_roles` | `ix_user_roles_user_context(user_id, company_id, status)`; UK asignación | Resolver permisos contextualizados. |
| `company_memberships` | `ix_membership_company_status(company_id, status, user_id)`; `ix_membership_user_status(user_id, status)` | Listados empresa/usuarios. |
| `company_branches` | `ix_branches_company_status(company_id, status)` | Sedes por empresa. |
| `vehicles` | UK placa normalizada; `ix_vehicles_company_status(company_id, status)`; `ix_vehicles_fleet(fleet_id, status)` | Administración y asignación de flota. |
| `driver_vehicle_links` | `ix_driver_vehicle_driver(driver_profile_id, status, valid_from_utc)`; `ix_driver_vehicle_vehicle(vehicle_id, status)` | Historial de relación. |
| `documents` | `ix_documents_subject_status(subject key, status)`; `ix_documents_expiry(status, expires_on)` | Documentos por entidad y vencimientos. |
| `verification_requests` | `ix_verification_queue(status, submitted_at_utc)`; `ix_verification_user(user_id, submitted_at_utc)` | Bandeja admin y seguimiento. |
| `document_reviews` | `ix_reviews_request(verification_request_id, reviewed_at_utc)` | Historial de revisión. |
| `loads` | `ix_loads_search(state, pickup_from_utc, pickup_to_utc, created_at_utc)`; `ix_loads_shipper(shipper_company_id, state, created_at_utc)` | Búsqueda/administración. |
| `load_stops` | UK/índice `(load_id, sequence_number)` | Recuperar paradas ordenadas. |
| `bids` | UK `(load_id, bidder_user_id)` según decisión; `ix_bids_load_state(load_id, state, created_at_utc)`; `ix_bids_bidder_state(bidder_user_id, state, created_at_utc)` | Negociación por carga o usuario. |
| `contracts` | `ix_contracts_load_state(load_id, state)`; `ix_contracts_bid(bid_id)` | Historial contractual. |
| `trips` | `ix_trips_state_schedule(state, planned_start_at_utc)`; `ix_trips_load(load_id, created_at_utc)`; `ix_trips_recurring_plan(recurring_trip_plan_id)` | Tableros y viajes recurrentes. |
| `assignments` | `ix_assignments_trip_state(trip_id, state)`; `ix_assignments_driver(driver_profile_id, state)`; `ix_assignments_vehicle(vehicle_id, state)` | Historial y disponibilidad. |
| Locks activos | PK/UK definidas en §2 | Control concurrente mediante índices únicos. |
| `route_stops` | UK `(route_plan_id, sequence_number)` | Orden de paradas. |
| `trip_simulations` | `ix_simulations_trip_created(trip_id, created_at_utc)` | Versiones históricas. |
| `location_points` | `(trip_id, observed_at_utc)`; `(user_id, observed_at_utc)` solo si consulta autorizada lo requiere | Consulta de recorrido por rango/retención. |
| `quotes` | `(trip_id, created_at_utc)` y/o `(load_id, created_at_utc)` | Historial de cálculos. |
| `expenses` | `(trip_id, occurred_at_utc)`; `(user_id, sync_status, created_at_utc)` | Liquidación y operaciones pendientes. |
| `incidents` | `(trip_id, status, created_at_utc)`; `(status, created_at_utc)` | Operación y revisión. |
| `deliveries` | UK `trip_id` solo si una entrega final es única; definir recogidas múltiples antes de fijar | Cierre por viaje. |
| `settlements` | UK `trip_id`; `(status, updated_at_utc)` | Una liquidación vigente/resumen por viaje. |
| `claims` | `(trip_id, status, created_at_utc)`; `(assigned_reviewer_user_id, status)` | Reclamaciones abiertas. |
| `ratings` | UK `(trip_id, reviewer_user_id)` y `(reviewed_user_id, created_at_utc)` | Regla anti-duplicado y reputación. |
| `conversations`/`chat_messages` | `(conversation_id, created_at_utc, id)`; UK participante activo | Paginación estable del chat. |
| `notifications` | `(user_id, status, created_at_utc)` | Bandeja por usuario. |
| `audit_events` | `(entity_type, entity_id, occurred_at_utc)`; `(actor_user_id, occurred_at_utc)`; `(correlation_id)` | Auditoría por entidad/actor. |
| `report_jobs` | `(requested_by_user_id, status, created_at_utc)` | Seguimiento de exportaciones. |
| `idempotency_records` | UK por scope/actor/key; índice de expiración | Evitar duplicados y limpiar según retención. |

## 6. Datos sensibles y rendimiento

- Nunca indexar texto de documentos, biometría, contenido de chat o credenciales.
- No indexar coordenadas precisas de forma global; restringir por viaje/usuario y evaluar retención/consultas.
- No incluir PII en claves de cache, nombres de objeto o logs SQL.
- Guardar en base solo metadata de archivo; contenido en almacenamiento privado.
- Revisar volumen esperado de `location_points`, `chat_messages`, `audit_events` y `notification_deliveries` antes de particionar. No particionar prematuramente ni perder FK.
- Fijar límites de paginación y orden estable en API; índices deben coincidir con filtros reales.
- Cualquier indexación espacial depende de versión MySQL y necesidad medida; no se exige para el prototipo.

## 7. Estrategia de borrado/retención

La retención por tipo de dato se debe definir antes de producción conforme validación legal. El diseño distingue:

- **Borrado lógico/estado inactivo:** perfiles y catálogos que deban dejar de ofrecerse sin perder referencias.
- **Anonimización o eliminación programada:** PII/biometría/ubicación cuando proceda y sea legalmente permitido.
- **Preservación restringida:** evidencia, auditoría y registros asociados a disputa/contrato según política aprobada.
- **Objetos privados:** eliminación física coordinada con metadata, backups y obligaciones de retención.

No se crea proceso de borrado que elimine evidencia requerida por disputa ni se conserva biometría indefinidamente por defecto.
