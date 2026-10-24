# Fase 1 — Alcance del MVP (MoSCoW)

## Regla de alcance

La aclaración web aprobada tiene prioridad de plataforma: todos los perfiles usan Flutter Web responsive; no se construye app móvil. El Documento Maestro adjunto conserva sus funciones completas. La clasificación de esta propuesta no elimina funcionalidades: define qué se propone implementar primero y qué permanece documentado para fases posteriores. El alcance definitivo del MVP necesita aprobación antes de implementación.

### Rebanada vertical propuesta

1. Empresa crea cuenta por correo o Google, selecciona perfil y completa verificación inicial mock/manual.
2. Empresa registra una carga en cinco pasos, incluyendo condiciones y pagador.
3. Conductor/transportadora consulta cargas y filtros, registra vehículo y cotiza una simulación marcada con procedencia.
4. Se registra oferta y se ejecuta una contratación con confirmaciones y control de doble aceptación.
5. Transportadora asigna conductor y vehículo compatibles.
6. Durante viaje, el usuario registra estados y ubicación solo si navegador/permisos/señal lo permiten; gastos e incidencias se pueden guardar localmente como pendientes, sin afirmar sincronización.
7. Se registra evidencia de entrega, gastos y liquidación informativa; no se mueve dinero.
8. Partes califican viaje completado; administración revisa usuarios/estados y ve trazabilidad.
9. Todo el recorrido funciona en UI responsive en español, con temas claro/oscuro/automático y backend de autorización.

## Priorización MoSCoW propuesta

**Must:** necesario para que la rebanada vertical del MVP sea demostrable y segura.  
**Should:** alto valor, pero puede seguir después del primer flujo completo.  
**Could:** valor complementario, si capacidad disponible.  
**Won't (por ahora):** no se implementa en MVP; se conserva en backlog/fases futuras y no significa eliminación del producto.

| ID | Sección/función del maestro | Prioridad | Alcance o nota |
|---|---|---|---|
| A-001 | §1–§2 propósito, Colombia, intermediación y objetivo | Must | Contexto y criterios de producto. |
| A-002 | §3 roles principales y administración | Must | Tres perfiles en web responsive y admin web por permisos. |
| A-003 | §4 bienvenida, entrar/crear cuenta, elección de perfil | Must | Pantallas adaptables; español. |
| A-004 | §5.1 correo/contraseña, validación, aceptación | Must | Verificación por mock/correo local inicial. |
| A-005 | §5.2 Google OIDC y vinculación | Should | Proveedor externo; mock primero, habilitación real sujeta a setup. |
| A-006 | §5.3 continuar registro | Should | Persistencia del borrador y estado faltante. |
| A-007 | §6 estados de verificación y revisión por admin | Must | Revisión manual para recorrido vertical. |
| A-008 | §6.1 verificación empresarial y fuentes oficiales | Must/Should | Campos y revisión manual Must; consulta oficial real Won't. |
| A-009 | §6.2 verificación de conductor/vehículo | Must | Registro y revisión básica; fuentes oficiales simuladas. |
| A-010 | §6.3 verificación facial/liveness | Should (mock) | Simulación/revisión humana; captura real y biometría real Won't. |
| A-011 | §6.4 verificación transportadora | Must (manual) | Estados y documentos; consulta externa real Won't. |
| A-012 | §7 IA documental | Could (mock) | No decisión autónoma; IA real posterior, documentos ficticios de prueba. |
| A-013 | §8 sesión, recuperación por correo | Must | Sesión segura, expiración y revocación. |
| A-014 | §8 recuperación facial | Won't | Mantener documentado, no sustituye recuperación segura. |
| A-015 | §9 panel por perfil | Must | Datos de la rebanada vertical y estado real. |
| A-016 | §10 publicación en cinco pasos | Must | Validación, guardado y condiciones de carga. |
| A-017 | §11 búsqueda y filtros | Must | Filtrar cargas existentes; estado vacío. |
| A-018 | §12 ofertas, negociación y contratación completa | Must | Flujo completo, control de concurrencia y contacto oculto. |
| A-019 | §13 gestión básica de transportadora y asignaciones | Must | Control de elegibilidad y conflicto de vehículo/conductor. |
| A-020 | §14 gemelo digital/simulación inmutable | Should | MVP puede mostrar simulación simple etiquetada; fidelidad de ruta depende proveedor. |
| A-021 | §15 mapas/rutas y ubicación | Should | Adaptador mock; geolocation solo por permiso web y con fecha. |
| A-022 | §15 peajes, hospedaje y otros servicios | Could | Datos solo con fuente/procedencia; no inventar tarifas ni acuerdos. |
| A-023 | §15 seguimiento/ubicación | Must (básico) | Actualización permitida por web foreground; no garantizar background. |
| A-024 | §16 cálculo de costos/gastos/ganancia | Must (simulado) | Parámetros sin tarifa real inventada; procedencia y fecha. |
| A-025 | §17 IA general/recomendaciones | Could (mock) | No decisiones autónomas; funcionalidades reales posteriores. |
| A-026 | §18 beneficios/recompensas | Won't | Sin acuerdos reales; conservar modelo futuro. |
| A-027 | §19 chat completo | Could | Mensajes básicos si no bloquea MVP; tiempo real completo posterior. |
| A-028 | §19 notificaciones | Should | Avisos dentro de la plataforma Must; push/email real depende servicio. |
| A-029 | §20 registro pre/durante/post viaje | Must | Confirmaciones, gastos, incidencias, evidencia y cierre. |
| A-030 | §21 liquidación informativa | Must | Valor acordado, gastos, ajustes y estado; sin custodia/pago. |
| A-031 | §22 calificaciones y reclamaciones | Must (calificación); Should (reclamación) | Calificación solo en viaje completado; reclamación básica. |
| A-032 | §23 panel administrativo | Must | Revisión y configuración controladas por rol; operaciones auditadas. |
| A-033 | §24 reportes | Should | Resúmenes básicos y trazables; exportación/analítica avanzada posterior. |
| A-034 | §25 apariencia claro/oscuro/automático | Must | Aplicación global, preferencia persistente. |
| A-035 | §26 español completo | Must | Interfaz y mensajes; identificadores de código en inglés conforme convención. |
| A-036 | §27 accesibilidad/adaptabilidad/usabilidad | Must | Responsive, teclado/semantics, escalado y contraste objetivo WCAG AA. |
| A-037 | §28 seguridad y privacidad | Must | Validación servidor, roles, auditoría, minimización, consentimiento. |
| A-038 | §29 tecnologías | Must | Flutter Web, Spring Boot, MySQL, REST; integraciones por adaptador. |
| A-039 | §30 modelo de datos | Must | Dominios principales y restricciones para flujo vertical. |
| A-040 | §31 vehículos múltiples, flota, recurrentes, retorno, averías, daños, offline, exportación, ayuda, privacidad, historial, fraude, integración y avisos | Must/Should/Could/Won't | Vehículos múltiples e historial básico Must; resto clasificado abajo por función. |
| A-041 | Varios vehículos y flotas básicas | Must | Para asignación de transportadora. |
| A-042 | Viajes recurrentes | Could | Instancias separadas; posterior al primer flujo vertical. |
| A-043 | Cargas de retorno | Could | Recomendación no vinculante y trazable. |
| A-044 | Reasignación por avería | Should | Flujo con registro e historial; no termina contrato automáticamente. |
| A-045 | Mercancía dañada/incompleta y reclamaciones | Should | Evidencia, responsables y estado. |
| A-046 | Consulta y gastos sin conexión | Should | Cola limitada, estados locales/no confirmados y conflicto explícito. |
| A-047 | Exportación de informes | Could | Respetar roles y privacidad. |
| A-048 | Ayuda contextual | Should | Mensajes en español, no reemplaza soporte legal. |
| A-049 | Varias sedes de empresa | Should | Modelo presente; UI completa puede ser posterior al primer flujo. |
| A-050 | Protección ante publicación fraudulenta | Should | Reportar/moderar y auditar; detección automática avanzada posterior. |
| A-051 | Integración empresarial futura | Won't | Interfaz/extensibilidad documentada; sin integración real inicial. |
| A-052 | §32 fases de desarrollo | Must (gobierno) | Mantener orden y no avanzar sin aprobación de fase. |
| A-053 | §33 resultado esperado | Must (criterio de producto) | Rebanada demostrable, sin prometer operación comercial real. |
| A-054 | §34 instrucciones de calidad y alcance | Must | No inventar, preservar alcance y separar estimación/simulación/confirmación. |

## Límites explícitos del MVP

- No pagos/custodia/facturación.
- No integraciones oficiales reales sin autorización y acceso confirmado.
- No proveedor de pago activado; presupuesto de proveedor externo cero.
- No biometría/IA real con documentos o datos de personas.
- No afirmar ubicación continua en segundo plano desde el navegador.
- No se considera una acción confirmada hasta respuesta del servidor.
- No fijar porcentajes de comisión, tarifas de peaje, penalidades o beneficios.
- No eliminar las funciones marcadas Should/Could/Won't del backlog.

## Aprobación de alcance

La clasificación MoSCoW es una propuesta para la Fase 1. La propietaria debe aprobar el alcance definitivo del MVP antes de comenzar implementación. La aprobación de este plan documental no equivale a aceptar prioridades de producto.
