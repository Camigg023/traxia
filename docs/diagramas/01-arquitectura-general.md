# Diagrama 01 — Arquitectura general

```mermaid
flowchart LR
    subgraph WEB["Navegador web responsive"]
        UI["Flutter Web<br/>EGC · Conductor · Transportadora"]
        ADMIN["Panel administrativo web<br/>acceso por rol"]
        BROWSER["Capacidades del navegador<br/>permisos cámara/ubicación/push"]
        LOCAL["Persistencia local limitada<br/>IndexedDB vía drift si se valida"]
        UI --> BROWSER
        UI --> LOCAL
    end

    subgraph API["Backend Java · Spring Boot · monolito modular"]
        REST["API REST<br/>validación, DTOs, OpenAPI"]
        WS["WebSocket/STOMP<br/>solo donde el flujo lo requiera"]
        SEC["Spring Security<br/>autenticación y autorización"]
        CTRL["Controllers"]
        SVC["Services / dominio"]
        REPO["Repositories"]
        PORTS["Puertos de proveedores"]
        AUDIT["Auditoría y eventos"]
        REST --> SEC --> CTRL --> SVC --> REPO
        SVC --> PORTS
        SVC --> AUDIT
        WS --> SEC
        WS --> SVC
    end

    DB[("MySQL 8.x<br/>Flyway · UTC · utf8mb4")]
    OBJ["Almacenamiento S3 compatible<br/>MinIO local · archivos privados"]

    subgraph ADAPTERS["Adaptadores externos — desactivados por defecto"]
        MAP["Mapas/rutas<br/>mock → Google Maps opcional"]
        AI["IA documental<br/>mock → Gemini opcional"]
        IDV["Identidad/liveness<br/>mock + revisión manual"]
        OFFICIAL["RUNT/RNDC/manifiesto<br/>solo simulación hasta autorización"]
        PUSH["Push web<br/>mock → FCM opcional"]
        MAIL["Correo<br/>Mailpit local → proveedor por evaluar"]
        SMS["SMS<br/>mock → proveedor por evaluar"]
    end

    UI -->|"HTTPS · API JSON"| REST
    ADMIN -->|"HTTPS · API JSON"| REST
    UI -. eventos autorizados .-> WS
    REPO --> DB
    SVC -->|"URLs firmadas con expiración"| OBJ
    PORTS --> MAP
    PORTS --> AI
    PORTS --> IDV
    PORTS --> OFFICIAL
    PORTS --> PUSH
    PORTS --> MAIL
    PORTS --> SMS

    classDef external fill:#fff3cd,stroke:#a87900,color:#222;
    class MAP,AI,IDV,OFFICIAL,PUSH,MAIL,SMS external;
```

## Principios de lectura

- El navegador nunca se conecta directamente a MySQL ni al almacenamiento privado.
- Toda regla de autorización y negocio vive en el servidor; ocultar una acción en la UI no sustituye autorización.
- Los mocks tienen etiqueta visible y no producen trámites, tarifas ni verificaciones oficiales.
- Las acciones offline se almacenan como pendientes locales; contratación, verificación final y confirmación legal requieren servidor.
- La geolocalización en web depende de permiso, contexto seguro y disponibilidad del navegador. No se promete seguimiento permanente en segundo plano.
- Los adaptadores reales se mantienen apagados por defecto. Se revisan costo, condiciones y consentimiento antes de activarlos.
