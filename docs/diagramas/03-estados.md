# Diagramas 03 — Máquinas de estados

Las transiciones son conceptuales y se deben refinar con reglas de negocio antes del modelo físico. Una transición no autorizada debe fallar sin alterar el estado.

## 03.1 Viaje

```mermaid
stateDiagram-v2
    [*] --> Planned: contratación confirmada
    Planned --> Ready: conductor/vehículo/documentos revisados
    Ready --> InProgress: inicio confirmado por actor autorizado
    InProgress --> Delayed: incidencia de retraso
    Delayed --> InProgress: reanuda
    InProgress --> Incident: avería/daño/otro incidente
    Incident --> ReassignmentPending: requiere reasignación
    ReassignmentPending --> Ready: recursos sustitutos confirmados
    Incident --> InProgress: incidente resuelto sin reasignar
    InProgress --> Delivered: entrega con evidencia registrada
    Delivered --> Completed: cierre validado
    Delivered --> ClaimOpen: daño/faltante/disputa
    ClaimOpen --> Completed: resolución permite cerrar
    Planned --> Cancelled: cancelación según política aprobada
    Ready --> Cancelled: cancelación según política aprobada
    InProgress --> ClaimOpen: disputa/incidente formal
    Completed --> [*]
    Cancelled --> [*]
```

## 03.2 Verificación de cuenta

```mermaid
stateDiagram-v2
    [*] --> Draft
    Draft --> Submitted: usuario envía datos
    Submitted --> UnderReview: revisión iniciada
    UnderReview --> Verified: revisor autorizado aprueba
    UnderReview --> CorrectionRequired: falta/corrección
    CorrectionRequired --> Submitted: usuario reenvía
    UnderReview --> Rejected: motivo documentado
    Verified --> Suspended: causa y revisión autorizada
    Suspended --> UnderReview: apelación/revisión
    Rejected --> UnderReview: reapertura autorizada
```

## 03.3 Pago informativo/liquidación (sin custodia)

```mermaid
stateDiagram-v2
    [*] --> Draft
    Draft --> Pending: liquidación preparada
    Pending --> PartiallyRecorded: partes registran pagos fuera de TRAXIA
    Pending --> RecordedAsPaid: partes declaran pago y adjuntan soporte
    PartiallyRecorded --> RecordedAsPaid: saldo registrado por partes
    Pending --> Disputed: disputa económica
    PartiallyRecorded --> Disputed: disputa económica
    Disputed --> Pending: corrección acordada
    Disputed --> Cancelled: anulación autorizada
    Pending --> Cancelled: anulación autorizada
    RecordedAsPaid --> [*]
    Cancelled --> [*]
    note right of Pending
      Estado informativo:
      TRAXIA no mueve dinero,
      no custodia ni certifica pago.
    end note
```

## 03.4 Gestión de transportadora

```mermaid
stateDiagram-v2
    [*] --> Draft
    Draft --> Submitted: solicita verificación
    Submitted --> UnderReview: revisión manual
    UnderReview --> Active: estado habilitado dentro de TRAXIA
    UnderReview --> CorrectionRequired: solicitar ajuste
    CorrectionRequired --> Submitted: corregir y reenviar
    Active --> Restricted: revisión/incidencia autorizada
    Restricted --> UnderReview: revisión de restricciones
    UnderReview --> Rejected: decisión motivada
    Active --> [*]: cierre de cuenta autorizado
```

## 03.5 Carga publicada

```mermaid
stateDiagram-v2
    [*] --> Draft
    Draft --> Published: revisión válida
    Published --> OfferReceived: recibe oferta válida
    OfferReceived --> Published: rechaza/caducan ofertas sin contratación
    OfferReceived --> ContractPending: partes confirman términos
    ContractPending --> Contracted: todos los pasos y recursos confirmados
    ContractPending --> Published: confirmación incompleta/caducidad
    Published --> Paused: empresa pausa
    Paused --> Published: empresa reactiva
    Published --> Cancelled: cancelación según política aprobada
    Paused --> Cancelled: cancelación según política aprobada
    Contracted --> [*]
    Cancelled --> [*]
```

## Invariantes a probar

- `Contracted` requiere secuencia de confirmaciones y una asignación única.
- Un conductor/vehículo no puede tener dos viajes activos simultáneos.
- `Completed` exige entrega/evidencia o excepción aprobada con auditoría.
- La calificación exige viaje `Completed`.
- Las transiciones de cancelación respetan política configurable aún pendiente de aprobación; no se inventan penalidades.
- Los estados informativos de liquidación no equivalen a pago procesado por TRAXIA.
