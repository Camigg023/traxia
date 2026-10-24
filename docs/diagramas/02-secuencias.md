# Diagramas 02 — Secuencias de flujos clave

Los actores usan el navegador responsive. Las alternativas de proveedor se muestran como puertos con mocks. Ningún flujo de mock constituye aprobación oficial.

## 02.1 Registro con correo

```mermaid
sequenceDiagram
    actor U as Usuario
    participant W as Flutter Web
    participant A as API Spring Boot
    participant D as MySQL
    participant M as Mailpit/mock correo
    U->>W: Completa datos y acepta condiciones
    W->>A: POST registro
    A->>A: Validar formato, política y duplicados
    A->>D: Crear cuenta pendiente y evento de auditoría
    A->>M: Solicitar verificación
    M-->>U: Enlace/código de prueba
    U->>W: Confirma código
    W->>A: POST confirmar
    A->>D: Validar vencimiento y marcar correo verificado
    A-->>W: Resultado y siguientes pasos
```

## 02.2 Registro con Google

```mermaid
sequenceDiagram
    actor U as Usuario
    participant W as Flutter Web
    participant G as Google OIDC/mock
    participant A as API Spring Boot
    participant D as MySQL
    U->>W: Selecciona "Continuar con Google"
    W->>G: Inicia autorización OIDC
    G-->>W: Resultado/callback autorizado
    W->>A: Enviar credencial de identidad al backend
    A->>A: Validar emisor, audiencia, estado y nonce
    A->>D: Buscar identidad/cuenta
    alt Cuenta existente
        A-->>W: Sesión y perfil existente
    else Cuenta nueva
        A->>D: Crear identidad pendiente de completar
        A-->>W: Solicitar perfil y datos faltantes
    end
    Note over W,A: El mock no autentica ante Google real
```

## 02.3 Vinculación de cuentas

```mermaid
sequenceDiagram
    actor U as Usuario autenticado
    participant W as Flutter Web
    participant A as API
    participant G as Proveedor OIDC
    participant D as MySQL
    U->>W: Solicita vincular Google/correo
    W->>A: Solicitar paso de reautenticación
    A-->>W: Instrucciones de verificación
    W->>G: Autenticar identidad secundaria
    G-->>W: Identidad verificada
    W->>A: Enviar prueba de vinculación
    A->>D: Comprobar que identidad no esté asociada a otra cuenta
    alt Identidad disponible
        A->>D: Vincular método y auditar
        A-->>W: Vinculación confirmada
    else Ya pertenece a otra cuenta
        A-->>W: Rechazar; indicar recuperación segura
    end
```

## 02.4 Verificación facial web (mock inicial)

```mermaid
sequenceDiagram
    actor U as Usuario
    participant W as Navegador/Flutter Web
    participant A as API
    participant V as Puerto de identidad
    participant H as Administrador revisor
    U->>W: Lee finalidad y decide consentimiento
    alt Consentimiento otorgado
        W->>W: Solicitar cámara; comprobar permiso/disponibilidad
        W->>A: Iniciar verificación y consentimiento
        A->>V: Crear sesión de prueba sin enviar datos al LLM
        V-->>A: Resultado mock "pendiente de revisión"
        A-->>W: Mostrar simulación/estado pendiente
        H->>A: Revisar manualmente
        A-->>W: Notificar decisión y motivo
    else Sin consentimiento o cámara no disponible
        W-->>U: Ofrecer alternativa manual; no capturar biometría
    end
    Note over U,V: Mock no prueba identidad real ni reemplaza revisión humana
```

## 02.5 Recuperación de cuenta

```mermaid
sequenceDiagram
    actor U as Usuario
    participant W as Flutter Web
    participant A as API
    participant M as Correo/SMS mock
    participant D as MySQL
    U->>W: Solicita recuperación
    W->>A: Enviar identificador de cuenta
    A->>D: Aplicar límite y generar token temporal
    A->>M: Enviar código/enlace de un solo uso
    U->>W: Envía código válido y nueva contraseña
    W->>A: Confirmar recuperación
    A->>D: Validar código, hash de contraseña, revocar sesiones y auditar
    A-->>W: Confirmar o explicar error sin filtrar si la cuenta existe
    Note over W,A: Rostro por sí solo nunca completa recuperación
```

## 02.6 Publicación de carga (cinco pasos)

```mermaid
sequenceDiagram
    actor E as Empresa generadora
    participant W as Flutter Web
    participant A as API
    participant D as MySQL
    E->>W: Paso 1: origen y destino
    W->>A: Guardar borrador/autosave
    E->>W: Paso 2: mercancía
    W->>A: Validar y guardar
    E->>W: Paso 3: vehículo requerido
    W->>A: Validar compatibilidad declarada
    E->>W: Paso 4: condiciones y pagador
    W->>A: Guardar condiciones configuradas
    E->>W: Paso 5: revisar y publicar
    W->>A: Solicitar publicación
    A->>A: Validar permisos, campos y estado
    A->>D: Publicar transaccionalmente
    A-->>W: ID y estado publicado
```

## 02.7 Oferta y contratación con concurrencia

```mermaid
sequenceDiagram
    actor C as Conductor/transportadora
    actor E as Empresa
    participant W as Flutter Web
    participant A as API
    participant D as MySQL
    C->>W: Envía oferta
    W->>A: Crear oferta idempotente
    A->>D: Guardar oferta e historial
    A-->>E: Notificar oferta recibida
    E->>W: Selecciona oferta y confirma condiciones
    W->>A: Confirmación de contratación
    A->>D: Transacción + bloqueo/versión + restricciones únicas
    alt Aceptación válida y primera
        D-->>A: Reservar carga/conductor/vehículo
        A-->>W: Contrato confirmado; revelar contacto permitido
    else Doble aceptación o estado cambió
        D-->>A: Conflicto
        A-->>W: Informar que ya no está disponible
    end
```

## 02.8 Gestión de empresa transportadora

```mermaid
sequenceDiagram
    actor T as Administrador transportadora
    participant W as Flutter Web
    participant A as API
    participant D as MySQL
    T->>W: Registra sede, flota, vehículos y conductores
    W->>A: Enviar datos/documentos
    A->>A: Validar permisos, compatibilidad y estados
    A->>D: Persistir entidades e historial
    T->>W: Asignar conductor y vehículo a viaje
    W->>A: Solicitar asignación idempotente
    A->>D: Comprobar viajes activos/restricciones
    alt Recursos disponibles
        A->>D: Confirmar asignación
        A-->>W: Asignación confirmada
    else Recurso ocupado/incompatible
        A-->>W: Explicar conflicto y solución
    end
```

## 02.9 Seguimiento desde navegador

```mermaid
sequenceDiagram
    actor D as Conductor
    participant W as Navegador
    participant A as API
    participant DBase as MySQL
    D->>W: Autoriza ubicación mientras usa la web
    alt Permiso concedido, contexto seguro y dato disponible
        W->>A: Enviar coordenada, precisión y hora del dispositivo
        A->>A: Validar sesión, viaje, consentimiento y límites
        A->>DBase: Guardar punto y fuente
        A-->>W: Confirmar recepción con hora del servidor
    else Permiso denegado, navegador no compatible o sin señal
        W-->>D: Informar limitación y hora del último dato sincronizado
    end
    Note over W,A: No se garantiza geolocalización en segundo plano
```

## 02.10 Entrega y cierre

```mermaid
sequenceDiagram
    actor D as Conductor
    actor R as Receptor autorizado
    participant W as Flutter Web
    participant A as API
    participant S as Almacenamiento privado S3
    participant DB as MySQL
    D->>W: Registra llegada, estado y evidencia
    W->>A: Solicitar carga de evidencia
    A->>S: Emitir URL firmada temporal
    W->>S: Subir evidencia
    W->>A: Registrar referencia y metadatos
    A->>DB: Guardar evidencia e incidencia opcional
    R->>W: Confirma recepción o reporta daño/faltante
    W->>A: Registrar respuesta
    A->>DB: Aplicar transición permitida y auditar
    A-->>W: Cierre confirmado o caso de reclamación pendiente
```
