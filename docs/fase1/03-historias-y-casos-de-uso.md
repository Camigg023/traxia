# Fase 1 — Historias de usuario y casos de uso

Las historias describen objetivos comprobables, no autorizan automatizar decisiones legales o de negocio. Prioridades remiten a [la propuesta MoSCoW](02-alcance-mvp.md).

## Historias de usuario

### Empresa generadora de carga (EGC)

| ID | Historia | Criterio de aceptación |
|---|---|---|
| HU-EGC-01 | Como empresa, quiero crear una cuenta y completar mi perfil para publicar cargas con una identidad verificable. | La cuenta queda pendiente hasta revisión; errores explican el siguiente paso. |
| HU-EGC-02 | Como empresa, quiero guardar una publicación por pasos para completar sus datos antes de hacerla visible. | El borrador se recupera y no aparece en búsqueda antes de publicarse. |
| HU-EGC-03 | Como empresa, quiero indicar origen, destino, mercancía, vehículo requerido y condiciones para recibir ofertas comparables. | Publicación no válida no se activa; condiciones incluyen pagador sin valor asumido. |
| HU-EGC-04 | Como empresa, quiero filtrar ofertas y revisar estimaciones para elegir con información clara. | Las estimaciones llevan origen y fecha; los datos no disponibles no se inventan. |
| HU-EGC-05 | Como empresa, quiero confirmar una oferta y sus condiciones para contratar con trazabilidad. | Solo la secuencia de confirmaciones válida crea contratación. |
| HU-EGC-06 | Como empresa, quiero consultar el viaje, incidencias, entrega y liquidación informativa. | Se ve último estado confirmado y hora de actualización; no se muestra pago inexistente. |
| HU-EGC-07 | Como empresa, quiero calificar y abrir reclamación sobre un viaje finalizado. | El sistema exige viaje completado y registra evidencia/actor. |
| HU-EGC-08 | Como empresa, quiero administrar sedes y usuarios autorizados. | Cada usuario solo accede según permisos asignados. |

### Conductor

| ID | Historia | Criterio de aceptación |
|---|---|---|
| HU-CON-01 | Como conductor, quiero registrarme y saber qué datos/documentos faltan. | El flujo se puede reanudar y el estado se explica en español. |
| HU-CON-02 | Como conductor, quiero registrar vehículos y documentos para consultar cargas compatibles. | Capacidad/documentación se validan en servidor; incompatibles no se asignan. |
| HU-CON-03 | Como conductor, quiero buscar cargas por ruta, fecha y requisitos. | Solo aparecen resultados que cumplen filtros y permisos. |
| HU-CON-04 | Como conductor, quiero comparar un cálculo estimado de gastos y ganancia. | Valores muestran simulación, fuente/fecha y supuestos configurados. |
| HU-CON-05 | Como conductor, quiero enviar una oferta y ver su estado. | Oferta conserva fecha, estado y condiciones; contacto directo sigue oculto antes de contratar. |
| HU-CON-06 | Como conductor, quiero consultar mi viaje asignado y reportar eventos. | Estado pendiente offline no se presenta como confirmado. |
| HU-CON-07 | Como conductor, quiero registrar gastos y evidencia de entrega desde el navegador. | Se conserva hora y autor, y el envío informa si quedó local o sincronizado. |
| HU-CON-08 | Como conductor, quiero recibir calificación y calificar a la contraparte al completar el viaje. | Solo un par de calificaciones por viaje/parte según regla configurada. |
| HU-CON-09 | Como conductor, quiero cambiar apariencia y usar la plataforma en celular, tableta o computador. | Tema persiste y layout no pierde acciones a los tamaños soportados. |

### Empresa transportadora/legalizadora

| ID | Historia | Criterio de aceptación |
|---|---|---|
| HU-ET-01 | Como transportadora, quiero solicitar verificación y consultar correcciones. | Los documentos y estados se muestran con su motivo y responsable. |
| HU-ET-02 | Como transportadora, quiero administrar conductores, vehículos, flotas y sedes. | No se crean asociaciones duplicadas; cambios quedan auditados. |
| HU-ET-03 | Como transportadora, quiero asignar conductor y vehículo compatibles a un viaje. | Conflictos de capacidad/estado o viajes activos impiden asignación. |
| HU-ET-04 | Como transportadora, quiero consultar documentación y vencimientos. | El sistema advierte fechas vencidas y no comunica aprobación oficial de mock. |
| HU-ET-05 | Como transportadora, quiero gestionar incidencia y reasignación cuando hay avería. | Se preserva historial y se solicita confirmación según estados válidos. |
| HU-ET-06 | Como transportadora, quiero consultar operaciones y reportes. | Métricas se derivan de registros reales y diferencian estimados. |

### Administrador

| ID | Historia | Criterio de aceptación |
|---|---|---|
| HU-ADM-01 | Como administrador autorizado, quiero revisar verificaciones y solicitar corrección. | Cambios de estado tienen motivo, actor y auditoría. |
| HU-ADM-02 | Como administrador, quiero moderar publicaciones/reportes sospechosos. | La moderación no borra evidencia y registra su decisión. |
| HU-ADM-03 | Como administrador, quiero configurar parámetros de negocio sin valores predeterminados inventados. | Parámetros nulos/no aprobados no se presentan como política vigente. |
| HU-ADM-04 | Como administrador, quiero ver actividad, incidencias y servicios externos. | Datos sensibles se ocultan según permiso y fallos externos se muestran explícitos. |
| HU-ADM-05 | Como administrador, quiero gestionar beneficios y categorías cuando existan reglas aprobadas. | No se promete beneficio sin regla/acuerdo configurado. |
| HU-ADM-06 | Como administrador, quiero operar el panel desde navegador de escritorio o móvil. | Rutas administrativas exigen autorización en servidor. |

## Casos de uso

| ID | Nombre | Actor principal | Precondición | Resultado |
|---|---|---|---|---|
| CU-01 | Registrarse con correo | Cualquier visitante | Acepta términos aplicables | Cuenta pendiente de verificación. |
| CU-02 | Registrarse con Google | Visitante | Google disponible/autorizado o mock | Cuenta iniciada/vinculada sin duplicado. |
| CU-03 | Vincular método de acceso | Usuario autenticado | Reautenticación y verificación | Método vinculado a la misma cuenta. |
| CU-04 | Recuperar cuenta | Usuario sin acceso | Acceso a canal verificado o revisión | Credenciales recuperadas de forma segura o caso pendiente. |
| CU-05 | Verificar perfil | Usuario/administrador | Solicitud y documentos disponibles | Estado revisado, con motivo y auditoría. |
| CU-06 | Publicar carga | EGC | Cuenta autorizada | Carga visible y buscable. |
| CU-07 | Buscar y ofertar | Conductor/ET | Carga activa y perfil elegible | Oferta registrada, partes aún sin contrato. |
| CU-08 | Contratar | EGC + conductor/ET | Oferta válida | Estado contratado solo después de todas confirmaciones. |
| CU-09 | Gestionar transportadora | ET | Cuenta con permisos | Vehículo/conductor/documentación asignados sin conflicto. |
| CU-10 | Simular viaje | EGC/conductor/ET | Ruta/datos de entrada | Instantánea etiquetada y con procedencia. |
| CU-11 | Seguir viaje | Partes autorizadas | Viaje activo y permiso de ubicación si se usa | Estado/ubicación disponible con fecha o estado no disponible. |
| CU-12 | Entregar y cerrar | Conductor/ET + receptor autorizado | Viaje en estado entregable | Evidencia, incidencias y cierre según reglas. |
| CU-13 | Liquidar información | Partes autorizadas | Gastos/acuerdo registrados | Liquidación calculada, sin movimiento monetario. |
| CU-14 | Calificar/crear reclamación | Parte del viaje | Viaje completado o incidente válido | Registro único o caso abierto. |
| CU-15 | Administrar plataforma | Administrador | Sesión y permiso vigente | Acción administrativa auditada. |
| CU-16 | Sincronizar datos pendientes | Usuario web | Conectividad recuperada | Operaciones aplicadas o conflicto informado; nunca confirmación ficticia. |

## Reglas transversales

- Toda autorización se valida en el backend, incluso si la interfaz oculta la acción.
- La secuencia de contratación no se salta.
- Proveedor, IA, fuente oficial y geolocalización pueden fallar o no estar disponibles.
- Ningún mock constituye prueba oficial, verificación legal, aprobación o pago.
- Cualquier flujo sin conectividad indica claramente qué permanece local y pendiente.
