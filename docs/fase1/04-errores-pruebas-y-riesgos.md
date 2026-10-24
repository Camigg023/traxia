# Fase 1 — Casos de error, estrategia de pruebas y riesgos

## Catálogo de casos de error demostrables

| ID | Caso | Respuesta esperada | Prueba |
|---|---|---|---|
| CE-01 | Documento vencido | Bloquear la transición que lo requiere, explicar qué documento debe renovarse y auditar el intento. | Servicio de fechas + integración |
| CE-02 | Vehículo incompatible | Rechazar asignación/oferta incompatible con capacidad o requisitos declarados; no alterar estado. | Servicio de compatibilidad |
| CE-03 | Carga excede capacidad | Impedir asignar vehículo cuya capacidad no cubre datos de carga. | Regla de dominio y persistencia |
| CE-04 | Recuperación sospechosa | Aplicar límites, no revelar si cuenta existe, revocar/retener según política y elevar revisión. | API, rate-limit y auditoría |
| CE-05 | Cancelación por empresa | Aplicar solo transición/política configurada; si política no está definida, no inventar penalidad y dejar decisión pendiente. | Máquina de estado |
| CE-06 | Cancelación por conductor/transportadora | Mismo control de política, motivo, actor y auditoría; no aplicar sanción ficticia. | Máquina de estado |
| CE-07 | Cambio/desvío de ruta | Guardar punto/registro disponible con hora y procedencia; avisar que cualquier costo/ETA es estimado. | Puerto de mapas mock |
| CE-08 | Avería con reasignación | Registrar incidencia, bloquear recursos incompatibles y pedir confirmación de reasignación antes de continuar. | Flujo de estados/concurrencia |
| CE-09 | Mercancía dañada | Registrar evidencia y abrir incidencia/reclamación; no cerrar viaje como limpio. | Integración entrega |
| CE-10 | Mercancía incompleta | Guardar cantidades declaradas/recibidas y dejar cierre sujeto a resolución autorizada. | Integración entrega |
| CE-11 | Reclamación formal | Crear caso con partes, evidencia, historial y estado; permitir solo acciones autorizadas. | API/permisos |
| CE-12 | Publicación fraudulenta | Marcar para revisión/moderación humana; no suspender solo por resultado mock de IA. | Flujo de moderación |
| CE-13 | Doble aceptación simultánea | Una solicitud gana transacción; restantes reciben conflicto sin duplicar asignación. | Prueba concurrente Testcontainers |
| CE-14 | Caída de proveedor externo | Timeout/reintento limitado, estado claro en español, sin dato inventado ni éxito falso. | Adapter contract test |
| CE-15 | Intento de evasión en chat | Advertir y registrar señal; no revelar contacto; no tratar detector heurístico como infalible. | Pruebas positivas/negativas |
| CE-16 | Token expirado | Rechazar o renovar según política; token revocado no renueva; informar al usuario sin detalle sensible. | Seguridad de sesión |
| CE-17 | Sin permiso de ubicación en web | No forzar permiso ni fabricar coordenadas; ofrecer registro manual/estado sin ubicación cuando permitido. | Pruebas navegador/mock |
| CE-18 | Navegador no permite push/cámara o no es contexto seguro | Explicar limitación y ofrecer alternativa; las funciones restantes siguen utilizables cuando sea seguro. | Prueba multi-browser |
| CE-19 | Conexión se pierde durante operación | Mostrar estado pendiente local/no sincronizado; evitar duplicado al reintentar mediante idempotencia. | Integración offline/API |
| CE-20 | URL firmada expirada o archivo sin permiso | Denegar descarga/carga y permitir generar una nueva solicitud autorizada. | Integración S3 mock |
| CE-21 | Cambio de estado inválido | Rechazar con mensaje comprensible y conservar estado anterior. | Pruebas de máquina de estados |
| CE-22 | Proveedor de IA intenta procesar dato biométrico | La capa de integración debe bloquear el envío antes de llamar proveedor y registrar fallo de política. | Prueba de contrato de IA |

## Estrategia de pruebas

| Nivel | Alcance/herramientas | Criterio de aceptación |
|---|---|---|
| Unitarias de dominio | JUnit 5/Mockito; lógica de estados, compatibilidad, cálculos con valores ficticios explícitos. | Reglas críticas tienen pruebas de camino positivo, negativo y límites; servicio busca objetivo de cobertura de 70 %. |
| Persistencia/integración backend | Testcontainers + MySQL, Flyway, transacciones y restricciones. | Esquema se crea desde cero y constraints rechazan duplicidades/estados incompatibles. |
| API/contratos | Swagger/OpenAPI, Postman versionado, pruebas de permisos/errores. | Respuestas y códigos documentados; no filtrar secretos/datos de otras cuentas. |
| Widgets Flutter | Formularios, estados vacíos/error, roles y responsive. | Interacciones críticas se presentan en español y mantienen estado correcto. |
| Golden/accessibility | Golden claro/oscuro, Semantics, escalado, contraste y teclado. | Pantallas críticas cubren ambos temas; hallazgos bloqueantes de accesibilidad se resuelven. |
| Integración web | `integration_test` en navegador; rutas, login mock y flujo vertical. | Registro → carga → oferta → contratación → viaje → entrega → liquidación informativa completa con datos simulados identificados. |
| Seguridad | Revisión de autorización, sesiones, rate limits, exposición de archivos y datos sensibles. | Ningún endpoint depende solo del control visual; biometría no llega al LLM; auditoría de operaciones sensibles. |
| Resiliencia | Mocks con timeout, error, respuesta parcial y repetición. | Reintentos limitados/idempotentes; mensaje en español; nunca success-shaped fallback. |
| Offline | Interrupción de conectividad, cola/conflictos. | Operaciones legales y contratación no se confirman offline; estado pendiente sobrevive a recarga según diseño. |
| Navegadores | Matriz a decidir en F02; móvil/tableta/escritorio. | Flujos críticos funcionan o degradan con alternativa clara; capacidades del navegador verificadas. |
| Rendimiento/OWASP ZAP | k6 o JMeter y ZAP únicamente en F16 según decisión aprobada. | Umbrales se definen con carga objetivo antes de ejecutar; hallazgos severos no quedan sin plan de remediación. |

## Criterios de aceptación por fase

| Fase (Documento Maestro §32) | Evidencia mínima antes de solicitar aprobación de cierre |
|---|---|
| F01 Análisis de requisitos y diagramas | RF/RNF trazables, priorización, historias, casos de uso, secuencias/estados, ER/arquitectura, riesgos y pendientes. |
| F02 Diseño de la base de datos | ER lógico/físico aprobado, restricciones de concurrencia y migraciones reproducibles; versiones verificadas. |
| F03 Backend, seguridad y autenticación | API documentada, roles, políticas de sesión, pruebas unitarias e integración aprobadas. |
| F04 Registro, verificación y recuperación | estados, consentimiento/alternativa, revisión humana, rate limits y auditoría probados con mocks. |
| F05 Gestión de empresas, conductores y vehículos | permisos, sedes/flotas/documentos, compatibilidad y unicidad probados. |
| F06 Publicación, búsqueda y contratación | publicación de cinco pasos, búsqueda, ofertas y doble aceptación concurrente probadas. |
| F07 Gestión de transportadoras | revisión, asignación compatible y estados demostrables. |
| F08 Aplicación Flutter y navegación por perfiles | UI web responsive para roles; no crear apps móviles; tema y accesibilidad básica. |
| F09 Mapas, rutas y cálculo de gastos | mock etiquetado, datos con procedencia, error externo y permiso web probados. |
| F10 Gemelo digital y simulación | instantáneas inmutables y comparación plan/ejecución con etiquetas. |
| F11 Inteligencia artificial | interfaz mock, prompts versionados, minimización, auditoría y revisión humana; sin biometría al LLM. |
| F12 Chat y notificaciones | permisos, miembros, detección de contacto y alternativa sin push probados. |
| F13 Seguimiento y entrega | disponibilidad de ubicación, registro de evidencia, incidencias/cierre y límites de navegador probados. |
| F14 Pagos, liquidaciones y beneficios | liquidación solo informativa, sin custodia; reglas de beneficios explícitas. |
| F15 Reportes y panel administrativo | autorización, datos trazables, redacción de datos sensibles y auditoría. |
| F16 Pruebas, seguridad, despliegue y documentación | suite acordada, cobertura objetivo, análisis de dependencias, pruebas k6/JMeter y OWASP ZAP; riesgos residuales documentados. |

## Matriz inicial de riesgos

| ID | Riesgo | Probabilidad | Impacto | Mitigación | Propietario/etapa |
|---|---|---:|---:|---|---|
| R-01 | Incompatibilidad entre menciones móviles del maestro y aclaración web | Alta | Alto | DEC-001 prioritaria, anexo y matriz de discrepancias; preservar el maestro literal. | Proyecto/F01 |
| R-02 | Ubicación/seguimiento web limitado por permiso, suspensión de pestaña o navegador | Alta | Alto | No prometer background; capturas foreground, estado/hora última ubicación y alternativa manual. | Producto/F09–F13 |
| R-03 | Costo/cambios de términos de APIs de mapas/IA/push | Media | Alto | Mock por defecto; costo y condiciones revalidados antes de activar; límites por configuración. | Integración/F09–F12 |
| R-04 | Exposición o uso indebido de biometría/documentos | Media | Crítico | Consentimiento, minimización, separación, cifrado, acceso y retención revisados; mock para MVP. | Seguridad/F04/F11 |
| R-05 | Requisito legal o acceso oficial no confirmado | Media | Alto | Etiquetar “por verificar”; simulación; no afirmar trámites ni aprobaciones oficiales. | Legal/F04–F07 |
| R-06 | Doble asignación por concurrencia | Media | Alto | Transacción, bloqueo/versionado, constraints únicos e idempotencia; prueba concurrente real. | Backend/F06–F07 |
| R-07 | Estimación presentada como tarifa/ubicación confirmada | Media | Alto | Tipo de procedencia/fecha en modelo y UI; test de contrato. | Producto/F09 |
| R-08 | Reglas de comisión/cancelación indefinidas | Alta | Medio | Parámetros vacíos hasta decisión; no preseleccionar cifras; decidir antes de operación real. | Dueña/F06/F14 |
| R-09 | Pérdida/conflicto de operación offline | Media | Alto | Cola acotada, idempotencia, timestamps y resolución humana; no confirmar acciones legales offline. | Cliente/F13 |
| R-10 | Tokens expuestos en aplicación web | Media | Crítico | Evaluar cookies seguras/CSRF o alternativa; reducir XSS, rotación/revocación, pruebas de sesión. | Seguridad/F03 |
| R-11 | Push/cámara no disponibles o permisos rechazados | Alta | Medio | Capacidades opt-in y fallback; no bloquear acceso básico; estado legible. | Cliente/F08/F12 |
| R-12 | El detector anti-evasión/IA produce falso positivo | Media | Medio | Alertar sin sanción automática; revisión humana y apelación; guardar evidencia mínima. | Producto/F11–F12 |
| R-13 | Credenciales subidas o commiteadas por error | Baja | Crítico | `.env.local` ignorado, ejemplo ficticio, escaneo de secretos en CI, rotar cualquier secreto expuesto. | Todos/F02 |
| R-14 | Falta de recursos para 16 fases amplias | Alta | Alto | Aprobar MVP MoSCoW, vertical slice y gate por fase; limitar proveedores reales. | Proyecto/F01 |
