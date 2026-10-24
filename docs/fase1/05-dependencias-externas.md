# Fase 1 — Matriz de dependencias externas

**Presupuesto inicial: cero.** Todas las integraciones comienzan como puertos con mocks claramente identificados. El adaptador real permanece deshabilitado hasta revisar costo, privacidad, región, términos, cobertura y aprobación. “Gratis” o “costo por verificar” no significa garantía de uso gratuito.

| ID | Necesidad/proveedor propuesto | Mock inicial | Riesgo/dependencia | Costo | Alternativa |
|---|---|---|---|---|---|
| DE-01 | Mapas/rutas: Google Maps Platform | Geometría/ruta ficticia marcada “Simulación”. | API key, cobertura y reglas de mapas de carga, permisos browser, cuotas y cambios de plan. | Por verificar antes de habilitar. | Mapbox; OpenRouteService; permitir entrada manual controlada. |
| DE-02 | Costos/rutas: Google Routes/Places si se seleccionan | Respuesta fixture sin datos reales. | API y límites facturables; no inferir tarifa del viaje. | Por verificar. | Mapbox/OpenRouteService o no mostrar cálculo real. |
| DE-03 | Peajes INVÍAS/ANI/concesiones | Tabla de ejemplo “SIMULADA”, con fecha ficticia visible. | Fuente/licencia/actualización oficial y cobertura por ruta. | Por verificar; dato/fuente oficial. | Configuración manual por administrador con fuente/fecha. |
| DE-04 | Costos de referencia SICE-TAC | Mock vacío o ejemplo simulado, nunca valor de mercado. | Acceso, autorización, condiciones y vigencia oficial. | Por verificar. | Captura/configuración manual identificada; otra fuente oficial validada. |
| DE-05 | IA documental Gemini | Adapter que responde “mock; revisión manual requerida”; documentos sintéticos. | Costo según plan/uso, privacidad, condiciones de datos, riesgo de inyección de instrucciones. | API puede tener niveles/precios distintos; verificar antes de activar. | Google Document AI; revisión manual; extracción local solo si se justifica. |
| DE-06 | Google Document AI | Mock de lectura documental. | Servicio y costo por uso; retención y protección de documentos. | Por verificar. | Gemini detrás de interfaz, OCR local o revisión manual. |
| DE-07 | Verificación facial/liveness: proveedor especializado por evaluar (Truora, Metamap, AWS Rekognition Face Liveness, Azure Face) | Revisión manual y flujo simulado. | Sensibilidad biométrica, consentimiento, alternativa, retención, cobertura Colombia, SDK web y acuerdo. | Por verificar para cada candidato. | Revisión manual no biométrica; mock para MVP. |
| DE-08 | Google OAuth 2.0/OIDC | Proveedor de identidad simulado para pruebas; nunca presentar como Google real. | Configuración de cliente/orígenes, protección de flujo web, disponibilidad de credenciales. | Por verificar términos/costos indirectos. | Correo con verificación; otro IdP tras decisión. |
| DE-09 | Firebase Cloud Messaging Web | Bandeja de notificaciones interna/local. | Service Worker, permiso del navegador, compatibilidad de navegadores y privacidad. | Condiciones vigentes por verificar; no asumir costo total de ecosistema cero. | Notificaciones in-app, correo local y fallback visible. |
| DE-10 | Correo transaccional | Mailpit local sin entrega externa. | Servicio real pendiente, reputación, dominio, límites y protección de datos. | Mailpit desarrollo local; proveedor producción por verificar. | Proveedor real sujeto a comparación/aprobación. |
| DE-11 | SMS | Adaptador mock, no envía mensajes. | Cobertura colombiana, consentimiento, costo por mensaje y abuso. | Por verificar. | Correo/in-app o proveedor por evaluar. |
| DE-12 | RUNT | Resultado “SIMULACIÓN — no consulta oficial”. | Acceso/API/acuerdo y reglas oficiales no confirmados. | Por verificar. | Revisión manual de documentos, sin afirmar consulta. |
| DE-13 | RNDC | Resultado simulado. | Acceso/acuerdo, datos y operación oficial por verificar. | Por verificar. | Mock y preparación documental sin aprobación oficial. |
| DE-14 | Manifiesto electrónico/Ministerio | Estado de prueba “no radicado/no oficial”. | Requisitos legales y canal autorizado pendientes. | Por verificar. | Documento interno de apoyo claramente no oficial. |
| DE-15 | Superintendencia de Transporte | Mock de consulta. | API/datos/acceso oficial no confirmados. | Por verificar. | Revisión documental/manual. |
| DE-16 | Archivos S3-compatible, MinIO local | MinIO en entorno local y fixtures sintéticos. | Gestión de claves, acceso, aislamiento de biometría/documentos, mantenimiento y licencia/distribución. | Local; producción y soporte por verificar. | Otro S3-compatible tras evaluación. |
| DE-17 | Proveedor de mapa adaptado a tema | Dos estilos locales ficticios. | El proveedor puede no permitir estilos/contrastes requeridos. | Incluido en cotización del proveedor; por verificar. | Mapa alterno o representación textual accesible. |
| DE-18 | Bases de datos/observabilidad/hosting de producción | Servicios locales Docker en fase de entorno. | Costos de hosting, dominio, backup, retención, región y operación. | Por verificar; fuera del presupuesto inicial. | Demostración local sin despliegue pagado. |

## Contrato común de los adaptadores

1. Interfaz de dominio propia, sin filtrar tipos del SDK externo al servicio.
2. Timeout finito, errores tipados y reintentos limitados solo para operaciones seguras/idempotentes.
3. Respuesta de error/ausencia explícita; no success-shaped fallback.
4. Metadatos de procedencia, fecha/hora, proveedor y etiqueta SIMULACIÓN/ESTIMADO cuando corresponda.
5. Secretos solo por variables de entorno/gestor de secretos; nunca en código, documentación o `.env.example`.
6. Prueba de contrato compartida por mock y adaptador real.
7. Adaptador real apagado por configuración por defecto; habilitarlo exige consentimiento y aprobación de costos.

## Verificación comercial

Las páginas oficiales consultadas el 2026-10-22 se registran en [Pendientes](../PENDIENTES.md). No se fijan aquí tarifas, cuotas, períodos promocionales ni disponibilidad para Colombia; se deben revalidar al decidir un adaptador.
