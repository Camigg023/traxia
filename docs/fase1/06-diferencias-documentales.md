# Fase 1 — Diferencias documentales y conservación

## Fuentes comparadas

| Fuente | Rol |
|---|---|
| [Documento Maestro vigente](../TRAXIA_DOCUMENTO_MAESTRO.md) | Copia literal del texto incluido en el prompt final, conservada como fuente base funcional. |
| [Documento Maestro anterior](../historico/TRAXIA_DOCUMENTO_MAESTRO_ANTERIOR.md) | Archivo anterior del repositorio, preservado íntegro para historia y requisitos adicionales. |
| [Aclaración aprobada](00-aclaracion-y-control.md) | DEC-001, prioridad vigente de plataforma web responsive sobre toda mención de app móvil. |

## Resolución de la contradicción de plataforma

El Documento Maestro vigente, tal como se pidió conservar literalmente, menciona Flutter móvil, Android/iOS, “aplicación móvil” en fases y `/mobile`. La aclaración posterior aprobada establece que TRAXIA será una plataforma web, no una aplicación móvil. Se conserva el texto fuente sin alteración y se aplica la aclaración web como excepción prioritaria de plataforma. No se crea Flutter Mobile ni se exige instalación.

La aclaración de plataforma no elimina los objetivos funcionales descritos en móvil: se reinterpretan para web con responsive, permisos y límites de navegador. Las capacidades que no se puedan garantizar en navegador (por ejemplo ejecución de geolocalización en segundo plano) deben expresarse como limitación y alternativa, no prometerse como equivalentes.

## Diferencias y tratamiento

| Tema | Maestro anterior | Maestro del prompt final | Aclaración/decisión vigente | Tratamiento |
|---|---|---|---|---|
| Plataforma | Flutter Web para perfiles (versión 1.0.1-draft), panel web en el mismo proyecto. | Flutter móvil, perfiles por app y propuesta Flutter/administración en estructura `/mobile`. | Todo web en Flutter Web responsive; no Android/iOS. | DEC-001 prevalece; maestro nuevo permanece literal; discrepancia visible. |
| Alcance funcional | 32 secciones con dominios, reglas, offline, anti-evasión, auditoría, resiliencia y fases propias. | 34 secciones con detalle de registro, publicación en cinco pasos, IA, beneficios, reportes, arquitectura y 16 fases. | No eliminar requisitos funcionales de ninguna fuente; decidir compatibilidad al consolidar requisitos. | Ambos documentos conservados; los requisitos se trazan por fuente/sección. |
| Fases | Plan de 13 fases. | 16 fases, incluyendo diseño de BD, IA, chat, pagos/beneficios y reportes. | No avanzar fase sin aprobación. La secuencia vigente para gobierno documental es §32 del maestro del prompt. | Diferencia de planificación se registra; no se mezclan números. |
| Dominios/datos | 20 dominios D-01 a D-20 y modelo de alto nivel con auditoría, configuración y peajes. | §30 enumera 20 áreas de modelo; §31 añade flotas, recurrencia, retorno, incidencias y offline. | Cubrir las 20 áreas enumeradas más entidades explícitas adicionales. | ER Fase 1 incluye ambos alcances y marca elementos adicionales. |
| Seguridad/autenticación | JWT con refresh rotatorio, OAuth, Argon2/BCrypt, rate limit y tokens web pendiente. | OAuth, JWT, recuperación, biometría, documentos y controles generales. | Diseño del almacenamiento de token web debe verificarse antes de implementar. | No asumir `flutter_secure_storage` equivale a un almacén seguro en navegador. |
| Datos/procedencia | Enum de fuente/fecha/proveedor y simulaciones inmutables. | Solicita separar confirmados/estimados/simulados y registrar eventos. | Toda métrica dinámica conserva origen y fecha; no inventar datos. | Unificar en requisitos y modelo ER; no cambiar texto fuente. |
| Pagos | Fase actual explícitamente sin custodia/pasarela. | Registra acuerdos, anticipos, gastos, comisiones, saldos y estado; futuro con pasarela. | Solo información económica; nada de dinero/custodia. | Interpretar estados como declarativos/informativos y validar con abogado. |
| Proveedores oficiales | RUNT/RNDC y otros como mocks/dependencias a verificar. | Menciona contraste “cuando sea posible y autorizado” y documentos oficiales. | Dependencias externas; simulación identificada hasta acceso/autorización. | No comunicar resultado mock como consulta/aprobación oficial. |
| Gobernanza | Documentos vivos decisiones/pendientes/glosario obligatorios. | Requiere registrar decisiones y preguntar contradicciones. | Crear/actualizar esos registros; no avanzar sin aprobación. | DEC-001..012 y documentos Fase 1 registran decisiones y brechas. |

## Requisitos adicionales del maestro histórico preservados

Se conservan y trazan en la matriz cuando aplican: máquina de estados por dominio, idempotencia y concurrencia; datos de procedencia en el modelo; modo offline con cola; detección de evasión; calificaciones solo sobre viajes completados; mecanismo alternativo a rostro; cifrado/privacidad; interacción resiliente con mocks; Swagger/OpenAPI; fases de documentación; panel por rol; pagos sin custodia. La conservación documental no significa que todos entren al MVP.

## Integridad documental

- El maestro adjunto se conserva como texto UTF-8 sin reescritura de sus requisitos; su primera línea es `TRAXIA — DOCUMENTO MAESTRO DEL PROYECTO` y su última frase es la indicada en el prompt.
- El archivo anterior se conserva como copia histórica íntegra; no se modifica ni se elimina.
- Las discrepancias se resuelven mediante esta matriz/DECISIONES, no cambiando uno de los documentos silenciosamente.
- `.env.local` se mantiene fuera de Git; `.env.example` no contiene secretos reales.
