# Pendientes, dependencias y verificaciones

Este registro separa decisiones propias del proyecto de asuntos que dependen de proveedores, fuentes oficiales, asesoría o validación posterior. Ninguna norma, tarifa, cobertura o resultado de mock se presentará como confirmado.

## Decisiones del dueño del proyecto

| ID | Pendiente | Tratamiento provisional | Cuándo resolver |
|---|---|---|---|
| PD-001 | Comisión de TRAXIA | Parámetro configurable por administrador; sin valor inicial inventado. | Antes de activar monetización. |
| PD-002 | Cancelaciones y penalidades | Política configurable. Cualquier valor en demostraciones debe rotularse como ejemplo, no como regla aprobada. | Antes de contratar viajes reales. |
| PD-003 | Pagador del transporte | Campo explícito en las condiciones de cada carga. | Diseño de publicación/contratación. |
| PD-004 | Responsabilidad legal de TRAXIA | Se considera provisionalmente intermediario tecnológico; validar con asesoría jurídica. | Antes de operación real. |
| PD-005 | Seguro de mercancía | Cobertura y obligatoriedad por definir y validar. No inferir norma. | Antes de habilitar viajes reales. |
| PD-006 | Adopción final del alcance MVP MoSCoW | Se documenta una propuesta derivada del prompt; la propietaria debe aprobar la priorización antes de implementarla. | Antes de iniciar construcción del MVP. |
| PD-007 | Retención y eliminación de biometría, ubicación y documentos | Política mínima y consentimiento son obligatorios; plazos concretos pendientes de revisión legal y de privacidad. | Antes de recolectar datos sensibles. |
| PD-008 | Reglas de beneficios y recompensas | Parámetros configurables; no prometer beneficios de terceros sin acuerdo. | Fase de beneficios. |
| PD-009 | Empresa con varios roles | Confirmar si una misma organización puede actuar como generadora de carga y transportadora/legalizadora. | Antes de fijar restricciones de `companies`. |
| PD-010 | Unicidad de NIT/identificador empresarial y placa | Definir alcance por país/jurisdicción, formato normalizado y acceso a datos. | Antes de migraciones de empresas/vehículos. |
| PD-011 | Cardinalidad contrato/viaje/entregas | Confirmar reapertura tras cancelación, múltiples recogidas/entregas y evaluadores por empresa. | Antes de congelar modelo de operaciones. |
| PD-012 | Precisión de importes y unidades | Definir escalas para dinero, masa, volumen, mediciones y calificaciones sin fijar tarifas. | Antes de migraciones con columnas numéricas finales. |
| PD-013 | Versión mínima de MySQL 8.x | MySQL 8.4 LTS (`mysql:8.4`) aprobado como objetivo de pruebas; validar con Testcontainers antes de aprobar el esquema físico. | Prueba bloqueada hasta disponer de Docker. |
| PD-014 | Alcance de roles por organización | Principio aprobado en DEC-014: ADMIN global, roles de negocio ligados a membresía de empresa. Falta definir cardinalidad, responsables de invitación/asignación y si el perfil legalizador es empresa o persona. No se añadieron tablas. | Antes de implementar membresías y autorización por empresa. |
| PD-015 | Reactivación histórica de roles | `UNIQUE(user_id, role_id)` de V1 no permite segunda asignación conservando la revocada. Mantener filas con reactivación o permitir múltiples periodos requiere decisión de modelado; no se modifica V1 sin aprobación. | Antes de implementar cambios de roles. |
| PD-016 | Límite de intentos de autenticación | Política inicial aplicada: 5 fallos/correo o 30/dirección en 15 min; bloqueo 15 min, HTTP 429, tabla Flyway V2 y clave HMAC separada. El origen real de IP detrás del proxy y el comportamiento concurrente requieren prueba/configuración de despliegue. | Antes de exponer el backend a Internet. |
| PD-017 | Aprovisionamiento inicial de administrador | Implementado con perfil no HTTP `admin-bootstrap`, contraseña sin default y bloqueo transaccional de ADMIN. Falta validar ejecución real con MySQL y documentar/operar canal secreto en entorno objetivo. | Antes de desplegar o probar con usuarios reales. |
| PD-018 | Contrato OpenAPI de autenticación | Los endpoints existen, pero no hay documentación OpenAPI/Swagger ni pruebas de contrato. Definir el formato/alcance requerido para cerrar la aceptación de Fase 3. | Antes de solicitar cierre de Fase 3. |

## Dependencias externas

| ID | Dependencia | Estado inicial | Riesgo/validación pendiente |
|---|---|---|---|
| DE-001 | Google Maps Platform (mapas/rutas) | Adaptador mock; activación externa deshabilitada. | Cobertura de rutas de carga y peajes en Colombia, permisos web, límites, términos y costo vigentes por verificar. |
| DE-002 | Mapbox u OpenRouteService | Alternativas a comparar. | Cobertura, atribución, límites, términos y costos por verificar. |
| DE-003 | Fuente de tarifas de peaje INVÍAS/ANI/concesiones | Datos de ejemplo simulados; no tarifa oficial. | Fuente, licencia, cobertura, actualización y vigencia por verificar con fuente oficial. |
| DE-004 | SICE-TAC | Adaptador mock. | Acceso, autorización y datos oficiales por verificar con fuente oficial. |
| DE-005 | IA documental (Gemini) | Adaptador mock; no enviar datos reales. | Costos, términos de tratamiento, retención y uso de datos; contenido de documentos es no confiable. |
| DE-006 | Google Document AI | Alternativa a IA documental. | Costo, tratamiento, cobertura y precisión por verificar. |
| DE-007 | Verificación facial/prueba de vida | Mock y revisión manual. | Proveedor especializado por seleccionar; costo, protección de biometría, disponibilidad en Colombia, alternativa no biométrica y base legal pendientes. |
| DE-008 | Firebase Cloud Messaging Web | Mock/local en desarrollo inicial. | Configuración de Service Worker, permisos del navegador, soporte por navegador y condiciones vigentes. |
| DE-009 | Correo | Mailpit en local. | Proveedor real, costo, entregabilidad y tratamiento de datos por evaluar. |
| DE-010 | SMS | Sin proveedor; mock. | Cobertura en Colombia, costo y consentimiento por verificar. |
| DE-011 | RUNT, RNDC, manifiesto electrónico, Superintendencia | Solo simulación etiquetada. | Toda integración y trámite requiere autorización/acuerdo y fuente oficial; no asumir API pública. |
| DE-012 | Almacenamiento S3 | MinIO local. | Cifrado en reposo, políticas, gestión de claves y costo de proveedor futuro por verificar. |
| DE-013 | Google OAuth/OIDC | Mock o entorno de prueba. | Configuración OAuth, dominios/orígenes autorizados, condiciones y secretos de despliegue. |

## Verificación oficial/legal

- Ley 1581 de 2012, reglamentación aplicable, datos sensibles, consentimiento, derechos de titulares y retención: **por verificar con fuente oficial y asesoría competente**.
- Transporte de carga, habilitación de transportadoras, documentos, manifiesto, RNDC, RUNT y SICE-TAC: **por verificar con fuente oficial**.
- Responsabilidad civil y contractual de TRAXIA, seguros, reclamaciones y cancelaciones: **validar con abogado**.
- Los documentos de requisitos no sustituyen una opinión jurídica.

## Versiones, costos y fuentes actuales

La selección de una tecnología no significa que su precio sea cero ni que esté activada. Los precios cambian y dependen de uso, región, plan y condiciones. El presupuesto inicial es cero; por tanto, todo adaptador de pago permanecerá apagado hasta autorización.

Referencias consultadas para orientar la verificación (consulta: 2026-10-22):

- [Flutter SDK archive](https://docs.flutter.dev/install/archive) — escoger versión estable compatible al inicio de Fase 2.
- [Spring Boot](https://spring.io/projects/spring-boot) — revisar matriz de compatibilidad/soporte vigente.
- [Oracle Java SE support roadmap](https://www.oracle.com/java/technologies/java-se-support-roadmap.html) — validar JDK LTS y términos de distribución; la licencia depende del proveedor.
- [MySQL downloads](https://dev.mysql.com/downloads/mysql/) — la página oficial no pudo consultarse desde este entorno; confirmar versión exacta y licencia antes de scaffolding.
- [Google Maps Platform pricing](https://mapsplatform.google.com/pricing/) — página consultada; planes, créditos, cuotas y costos aplicables a TRAXIA deben verificarse antes de habilitar.
- [Gemini API pricing](https://ai.google.dev/gemini-api/docs/pricing) — la página consultada muestra categorías gratuitas y pagas, límites y condiciones; no se enviarán documentos ni se habilitará el servicio con este plan sin revisar privacidad y costos.
- [Firebase pricing](https://firebase.google.com/pricing) — página consultada; es dinámica y no permite asumir que todos los servicios/uso de TRAXIA son gratuitos. Confirmar condiciones específicas de FCM y servicios relacionados antes de despliegue.
- [MinIO documentation](https://min.io/docs/minio/kubernetes/upstream/index.html) — página consultada y redirigida a documentación de AIStor; no confirma por sí sola costo/licencia de todas las ediciones. Verificar la edición, términos y soporte antes de elegirla para el entorno local.
- [Mailpit](https://mailpit.axllent.org/) — servidor local de correo para desarrollo; no equivale a proveedor de correo de producción.

**Decisión de fase:** fijar versiones exactas durante Fase 2 con verificación oficial y compatibilidad documentada; no agregar números no verificados a la especificación funcional.
