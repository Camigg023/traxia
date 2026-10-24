# Fase 2 — Migraciones, trazabilidad y aceptación del diseño

**Estado:** estrategia documental; no se generan archivos SQL de Flyway en esta fase.

## 1. Estrategia de evolución del esquema

- Flyway será el mecanismo único de migración versionada para esquema y catálogos de referencia.
- Cada cambio futuro será incremental, revisado y probado contra una base MySQL vacía y una base previa.
- Las migraciones de producción deben ser compatibles con despliegue seguro: expandir esquema, desplegar código compatible y retirar columnas antiguas en otra migración solo tras validar datos y dependencias.
- No editar migraciones ya aplicadas; crear una migración correctiva nueva.
- No ejecutar migraciones de producción ni borrar/restaurar datos durante esta fase.
- Catálogos de rol/permiso/estado podrán tener seeds idempotentes; no sembrar tarifas, datos de negocio, credenciales ni identidades personales.
- Las fixtures de demostración deben ser sintéticas, reproducibles y claramente no oficiales.
- No activar mecanismo de partición antes de medir cardinalidad y validar compatibilidad con claves/consultas.

## 2. Secuencia propuesta para migraciones futuras

La siguiente secuencia es un mapa de dependencias, no scripts listos para ejecutar:

| Orden lógico | Grupo | Entidades | Dependencias |
|---:|---|---|---|
| 1 | Convenciones/catálogos | roles, permissions, data_sources (catálogos vacíos o códigos técnicos) | Ninguna |
| 2 | Identidad | users, auth_methods, roles, permissions, user_roles, role_permissions, terms_acceptances, user_preferences, account_recovery_requests | Catálogos |
| 3 | Empresas y organización | companies, company_branches, company_memberships, carrier_profiles, driver_profiles, fleets, vehicles, driver_vehicle_links, recurring_trip_plans | Identidad |
| 4 | Archivos y verificación | file_objects, documents, consent_records, verification_requests, document_reviews, verification_events, biometric_records (solo estructura si autorizada), ai_assessments | Identidad, organización |
| 5 | Cargas y negociación | loads, load_state_events, load_cargo_details, load_vehicle_requirements, load_conditions, load_stops, bids, bid_events, contracts, contract_state_events, contract_confirmations, active_load_contracts | Empresas, usuarios |
| 6 | Viaje y asignaciones | trips, trip_state_events, assignments, assignment_state_events, active_trip_assignments, active_driver_assignments, active_vehicle_assignments | Contratos, vehículos, conductores |
| 7 | Ruta y cálculo | route_plans, route_stops, trip_simulations, toll_tariffs (sin datos reales), quotes, location_points, expenses | Viajes, fuentes |
| 8 | Operación | incidents, deliveries, delivery_evidence, settlements, settlement_entries, settlement_state_events, settlement_disputes, claims, ratings | Viajes, archivos |
| 9 | Comunicación y confianza | conversations, conversation_contexts, conversation_participants, chat_messages, message_attachments, anti_evasion_events, notifications, notification_preferences, notification_deliveries | Usuarios, contratos/viajes |
| 10 | Gobierno/analítica | benefits, benefit_grants, audit_events, company_state_events, load_state_events, contract_state_events, assignment_state_events, system_parameters, system_parameter_events, report_jobs, idempotency_records, sync_operations | Dominios previos |

La estructura específica debe dividirse en migraciones pequeñas por capacidad de revisión. No es necesario que cada fila sea una sola migración.

## 3. Compatibilidad Flyway/JPA

- Flyway define el esquema; Hibernate no debe modificarlo automáticamente en entornos compartidos. En desarrollo/pruebas, validar con modo de esquema `validate`, no actualización automática.
- Restricciones e índices con nombre estable para que fallos sean identificables.
- Configuración de charset/collation por conexión y tablas explícita y uniforme.
- UTC se fija tanto en configuración de aplicación como en conexiones/serialización; verificar con prueba de integración.
- UUID `BINARY(16)` requiere conversión consistente en entity/DTO/API; el público se representa en texto UUID canónico en URLs/respuestas.
- `DATETIME(6)` se valida con serialización y round-trip de microsegundos si se usa precisión.
- Migraciones se ejecutan en CI contra versión MySQL fijada; H2 no sustituye las pruebas del dialecto real.
- No usar `ENUM` de MySQL para estados de negocio que puedan evolucionar; almacenar código `VARCHAR` y validar en backend o catálogos relacionales.

## 4. Matriz de trazabilidad de requisitos a datos

| Requisitos | Entidades/tablas principales | Controles de datos | Evidencia de aceptación |
|---|---|---|---|
| RF-001–RF-004, RF-009–RF-010 | `users`, `auth_methods`, `account_recovery_requests`, `terms_acceptances` | Unicidad de identidad, tokens hasheados, expiración/uso, revocación | Pruebas de registro, vínculo y recuperación; hash no reversible |
| RF-005, RF-028 | `roles`, `permissions`, `user_roles`, `role_permissions`, `company_memberships` | Unicidad/asignación contextual; autorización server-side | Pruebas de acceso de cada rol y de denegación |
| RF-006–RF-008 | `verification_requests`, `documents`, `document_reviews`, `verification_events`, `consent_records`, `biometric_records`, `ai_assessments`, `file_objects` | Historial, acceso mínimo, estado explícito, consentimiento | Auditoría, alternativa manual, mock rotulado, cero biometría al LLM |
| RF-013–RF-016 | `loads`, `load_*`, `bids`, `bid_events`, `contracts`, `contract_confirmations`, `active_load_contracts` | FK, estado, snapshot de términos, lock de carga | Una única contratación activa ante llamadas concurrentes |
| RF-017–RF-018 | `companies`, `company_branches`, `fleets`, `vehicles`, `driver_profiles`, `driver_vehicle_links`, `recurring_trip_plans`, `trips` | Aislamiento de empresa, unicidad e intervalos | Pruebas de varias sedes/vehículos y viajes recurrentes separados |
| RF-019–RF-022, RF-034 | `route_plans`, `route_stops`, `trip_simulations`, `data_sources`, `toll_tariffs`, `quotes`, `expenses`, `settlements` | Snapshots, procedencia, fecha, moneda y no custodia | Simulación inmutable; tests para origen/fecha; liquidación informativa |
| RF-023, RF-031 | `location_points`, `sync_operations`, `expenses` | Procedencia/hora, permisos, idempotencia y cola | No confirmar ubicación/operación offline no recibida |
| RF-024, RF-044/45 (casos) | `deliveries`, `delivery_evidence`, `incidents`, `claims`, `file_objects` | FK, estados, almacenamiento privado, auditoría | Evidencia de entrega y creación de incidencia/reclamación |
| RF-025–RF-027 | `conversations`, `conversation_participants`, `chat_messages`, `anti_evasion_events`, `notifications`, `ratings` | Pertenencia, unicidad, expiración/retención | Lectura con permiso, contacto oculto, rating solo tras completar viaje |
| RF-030 | `benefits`, `benefit_grants`, `system_parameters` | Reglas y vigencias configuradas | No se concede/presenta beneficio sin regla/acuerdo |
| RF-032, RF-036 | `user_preferences`, `notification_preferences`, `system_parameters` | UK por usuario/categoría; historial de cambios sensibles | Persistencia de tema/aviso y auditoría |
| RF-033, RNF-008 | `*_state_events`, `version`, active lock tables, `idempotency_records` | Transacciones, optimistic locking, UK de recursos | Test concurrente, transiciones inválidas no cambian datos |
| RF-035 | `verification_events`, `ai_assessments`, `data_sources` | Campo de procedencia/etiqueta SIMULACIÓN | Mock nunca aparece como aprobación oficial |
| RNF-006–RNF-007, RNF-019 | `consent_records`, `audit_events`, `file_objects`, `documents`, `biometric_records`, `location_points` | Separación/acceso/retención; auditoría append-only | Revisión de permisos y acceso con cuenta no autorizada |
| RNF-015–RNF-018, RNF-021 | Esquema completo + `idempotency_records` | Flyway, índices, tests con MySQL real, cobertura | Construcción limpia de esquema y CI |

## 5. Validaciones de diseño antes de generar migraciones

La propietaria y la revisión técnica deben confirmar:

1. El modelo de empresa admite o no que una organización actúe como generadora y transportadora.
2. Si `tax_identifier` y placa tienen unicidad global, por país/jurisdicción o alcance distinto.
3. Si una carga permite varias publicaciones/contratos secuenciales tras una cancelación, y regla exacta de reapertura.
4. Si un viaje tiene una o varias recogidas/entregas y cómo se relacionan `deliveries` y `trip_state_events`.
5. Quién puede ser parte evaluadora de calificación en una transportadora con varios usuarios.
6. Qué valores/escala se requieren en dinero, masa, volumen y ratings; no se inferirán tarifas.
7. Versión mínima de MySQL 8.x y soporte de CHECK/JSON/UUID conversion/Flyway.
8. Retención, anonimización y borrado de documentos, ubicación, mensajes, biometría y eventos.
9. Política de carga/retención de ubicación web y datos requeridos para consentimiento.
10. Estructura de historial/auditoría y retención de evidencia ante reclamación.

Los puntos 1–6 se pueden mantener como alternativas explícitas en diseño; los puntos 7–10 son bloqueantes antes de crear esquema ejecutable que almacene datos reales sensibles o desplegar en producción.

## 6. Aceptación documental de la Fase 2

- Modelo lógico cubre los dominios indicados y conserva la aclaración web aprobada.
- Cada relación importante identifica PK/FK y cardinalidad; invariantes críticas tienen una restricción o control transaccional propuesto.
- No hay precios/tarifas ni datos personales de ejemplo presentados como reales.
- Las operaciones de concurrencia tienen una estrategia verificable, no solo una nota de “validar en aplicación”.
- Cada requisito de datos se puede rastrear a tablas y evidencia de prueba.
- Plan Flyway documenta dependencias, compatibilidad y riesgos sin scripts ejecutables.
- Pendientes técnicos/comerciales/legalmente sensibles quedan identificados y no se resuelven silenciosamente.

## 7. Referencias de versiones

La versión específica de MySQL 8.x no queda fijada en esta Fase 2: el endpoint oficial de descargas no pudo consultarse durante Fase 1. Antes de scripts Flyway se debe verificar la versión exacta y sus capacidades relevantes con documentación oficial, además de probarla con Testcontainers.
