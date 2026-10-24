# Fase 1 — Aclaración aprobada y control de fuentes

**Fecha de aprobación:** 2026-10-22  
**Estado:** Aclaración de plataforma aprobada; entregables de análisis en preparación.

## Jerarquía de fuentes

1. El Documento Maestro adjunto se conserva literalmente como [Documento Maestro vigente](../TRAXIA_DOCUMENTO_MAESTRO.md).
2. La aclaración posterior de la propietaria sobre la plataforma web constituye una excepción de alcance aprobada y prioritaria para toda mención de plataforma:
   - TRAXIA es una **plataforma web**, no una aplicación móvil.
   - Los tres perfiles principales y administración acceden por navegador.
   - Flutter Web, Java + Spring Boot y MySQL.
   - Interfaz responsive para computadores, tabletas y celulares; no se requiere instalar aplicación.
   - No crear Flutter Mobile, proyectos Android/iOS ni estructura exclusiva para aplicaciones móviles.
   - Mapas, ubicación, seguimiento, notificaciones y verificación se diseñan dentro de las capacidades y límites web.
3. Los requisitos funcionales del Documento Maestro se conservan. La prioridad web no elimina necesidades de seguimiento, disponibilidad, evidencia, experiencia móvil responsive ni trabajo sin conexión; obliga a diseñarlas apropiadamente para navegador.
4. El maestro existente antes de esta decisión se conserva sin cambios como [maestro histórico](../historico/TRAXIA_DOCUMENTO_MAESTRO_ANTERIOR.md). Sus requisitos y discrepancias se registran en [la matriz de diferencias](06-diferencias-documentales.md).

## Alcance de la aprobación

La propietaria aprobó la planificación de la Fase 1 y la aclaración web. Esto autoriza producir artefactos de análisis y diagramas; **no** autoriza iniciar código de aplicación, activar proveedores, instalar servicios de pago ni avanzar a la Fase 2.

## Restricciones de plataforma para análisis y diseño

- Cada flujo debe ser viable desde navegador y reflow responsive.
- El acceso a geolocalización, cámara y notificaciones depende de permisos, disponibilidad del navegador, contexto seguro y decisión del usuario. Si no hay permiso o señal, debe existir un estado claro y un procedimiento alternativo cuando corresponda.
- No asumir ubicación continua en segundo plano, ejecución permanente del navegador, cámara disponible ni notificaciones push aceptadas.
- Un dato de ubicación lleva la hora de actualización y procedencia; una ubicación no disponible nunca se inventa.
- Los trámites, verificaciones, aceptación contractual y sincronización legal requieren conexión al servidor.
- La persistencia local y la sincronización offline son limitadas, cifradas/protegidas según diseño futuro, con conflictos explícitos; no equivalen a una acción confirmada por el servidor.

## Archivos de entorno

- `.env.local` existe como plantilla local sin secretos reales y debe permanecer ignorado por Git.
- `.env.example` enumera variables futuras con marcadores no utilizables como credenciales.
- La plantilla no activa servicios ni es una configuración de producción.
