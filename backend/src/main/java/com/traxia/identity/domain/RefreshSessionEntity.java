package com.traxia.identity.domain;

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
@Table(name = "refresh_sessions")
public class RefreshSessionEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @JdbcTypeCode(SqlTypes.BINARY)
    @Column(name = "public_id", nullable = false, unique = true, columnDefinition = "BINARY(16)")
    private UUID publicId;

    @JdbcTypeCode(SqlTypes.BINARY)
    @Column(name = "family_id", nullable = false, columnDefinition = "BINARY(16)")
    private UUID familyId;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "user_id", nullable = false)
    private UserEntity user;

    @JdbcTypeCode(SqlTypes.CHAR)
    @Column(name = "token_hash", nullable = false, unique = true, length = 64)
    private String tokenHash;

    @Column(name = "created_at_utc", nullable = false)
    private Instant createdAtUtc;

    @Column(name = "expires_at_utc", nullable = false)
    private Instant expiresAtUtc;

    @Column(name = "revoked_at_utc")
    private Instant revokedAtUtc;

    @Column(name = "replaced_by_id")
    private Long replacedById;

    protected RefreshSessionEntity() {
    }

    public RefreshSessionEntity(
            UUID publicId,
            UUID familyId,
            UserEntity user,
            String tokenHash,
            Instant createdAtUtc,
            Instant expiresAtUtc) {
        this.publicId = publicId;
        this.familyId = familyId;
        this.user = user;
        this.tokenHash = tokenHash;
        this.createdAtUtc = createdAtUtc;
        this.expiresAtUtc = expiresAtUtc;
    }

    public Long getId() {
        return id;
    }

    public UUID getFamilyId() {
        return familyId;
    }

    public String getTokenHash() {
        return tokenHash;
    }

    public UserEntity getUser() {
        return user;
    }

    public Instant getExpiresAtUtc() {
        return expiresAtUtc;
    }

    public Instant getRevokedAtUtc() {
        return revokedAtUtc;
    }

    public void revoke(Instant revokedAtUtc) {
        this.revokedAtUtc = revokedAtUtc;
    }

    public void setReplacedById(Long replacedById) {
        this.replacedById = replacedById;
    }
}
