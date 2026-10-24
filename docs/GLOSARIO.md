# Glosario TRAXIA

La interfaz y la explicación funcional se redactan en español. Los identificadores técnicos se escriben en inglés, según la convención aprobada.

| Término en español | Identificador sugerido en inglés | Significado en TRAXIA |
|---|---|---|
| Empresa generadora de carga | `ShipperCompany` | Organización que publica una necesidad de transporte. |
| Conductor | `Driver` | Persona que conduce el vehículo asignado al viaje. |
| Empresa transportadora/legalizadora | `CarrierCompany` | Organización que gestiona vehículos, conductores y documentación aplicable. |
| Administrador | `Administrator` | Usuario interno autorizado para gestionar funciones administrativas. |
| Usuario | `User` | Identidad de acceso y datos básicos de una persona. |
| Rol | `Role` | Conjunto de permisos asignado a una cuenta. |
| Permiso | `Permission` | Autorización concreta para una operación. |
| Método de acceso | `AuthMethod` | Credencial o proveedor asociado, como correo o Google OIDC. |
| Sede | `CompanyBranch` | Ubicación organizacional de una empresa. |
| Vehículo | `Vehicle` | Unidad de transporte, con capacidad y documentos. |
| Flota | `Fleet` | Conjunto de vehículos gestionados por una transportadora. |
| Carga publicada | `Load` | Solicitud/oferta de transporte creada por una empresa. |
| Oferta | `Bid` | Propuesta económica/operativa para una carga. |
| Asignación | `Assignment` | Asociación confirmada entre carga/viaje, conductor y vehículo. |
| Viaje | `Trip` | Ejecución del transporte, con estados e historial. |
| Viaje recurrente | `RecurringTrip` | Instancia creada desde una regla/plan recurrente. |
| Ruta | `Route` | Recorrido propuesto o realizado entre origen, destino y paradas. |
| Parada | `RouteStop` | Punto intermedio de una ruta. |
| Gemelo digital | `DigitalTwin` | Comparación explícita del plan con la ejecución del viaje. |
| Simulación | `Simulation` | Resultado inmutable, con parámetros, fuentes y fecha, rotulado como simulación. |
| Cotización | `Quote` | Cálculo económico preliminar, con procedencia y fecha. |
| Gasto | `Expense` | Egreso registrado en la operación. |
| Liquidación | `Settlement` | Resumen de valores acordados y gastos; no implica movimiento de dinero. |
| Fuente del dato | `DataProvenance` | Categoría de procedencia: confirmado, estimado, simulado, usuario o proveedor externo. |
| Verificación | `Verification` | Revisión de cuenta, empresa, persona, vehículo o documento. |
| Evidencia de entrega | `DeliveryEvidence` | Registro que respalda recepción/entrega, sujeto a revisión. |
| Incidencia | `Incident` | Evento que altera la ejecución prevista. |
| Reclamación | `Claim` | Caso de desacuerdo o problema abierto por una parte. |
| Calificación | `Rating` | Evaluación asociada exclusivamente a un viaje completado. |
| Beneficio | `Benefit` | Ventaja sujeta a reglas y acuerdos explícitos. |
| Auditoría | `AuditEvent` | Registro protegido de una acción sensible. |
| Manifiesto | `CargoManifest` | Documento de transporte; TRAXIA no lo presenta como oficial sin validación/autorización. |
| Recuperación de cuenta | `AccountRecovery` | Procedimiento reforzado para recuperar acceso; rostro no basta por sí solo. |
| Modo sin conexión | `OfflineMode` | Funciones locales permitidas y cola de sincronización con conflictos definidos. |
| Puerto/adaptador | `PortAdapter` | Interfaz que desacopla el dominio de proveedores y permite implementaciones mock/reales. |
| Mock | `MockProvider` | Implementación de prueba, claramente identificada y sin afirmar datos oficiales. |
| Rebanada vertical | `VerticalSlice` | Flujo ejecutable de extremo a extremo a través de interfaz, API y persistencia. |

## Códigos de procedencia

Los nombres de interfaz visibles deben ser claros: **Confirmado**, **Estimado**, **Simulación**, **Configurado por el usuario** y **Proveedor externo**. Los identificadores internos y reglas de presentación se definirán en el diseño técnico.
