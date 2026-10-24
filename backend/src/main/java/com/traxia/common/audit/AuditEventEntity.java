package com.traxia.common.audit;

import com.traxia.identity.domain.UserEntity;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;
import java.time.Instant;
import java.util.UUID;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;

@Entity
@Table(name = "audit_events")
public class AuditEventEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "actor_user_id")
    private UserEntity actor;

    @Column(name = "action_code", nullable = false, length = 64)
    private String actionCode;

    @Column(name = "entity_type", length = 64)
    private String entityType;

    @JdbcTypeCode(SqlTypes.BINARY)
    @Column(name = "entity_public_id", columnDefinition = "BINARY(16)")
    private UUID entityPublicId;

    @Column(nullable = false, length = 32)
    private String outcome;

    @Column(name = "correlation_id", length = 64)
    private String correlationId;

    @Column(name = "occurred_at_utc", nullable = false)
    private Instant occurredAtUtc;

    protected AuditEventEntity() {
    }

    public AuditEventEntity(
            UserEntity actor,
            String actionCode,
            String entityType,
            UUID entityPublicId,
            String outcome,
            String correlationId,
            Instant occurredAtUtc) {
        this.actor = actor;
        this.actionCode = actionCode;
        this.entityType = entityType;
        this.entityPublicId = entityPublicId;
        this.outcome = outcome;
        this.correlationId = correlationId;
        this.occurredAtUtc = occurredAtUtc;
    }
}
