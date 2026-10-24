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
@Table(name = "email_verification_tokens")
public class EmailVerificationTokenEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @JdbcTypeCode(SqlTypes.BINARY)
    @Column(name = "public_id", nullable = false, unique = true, columnDefinition = "BINARY(16)")
    private UUID publicId;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "user_id", nullable = false)
    private UserEntity user;

    @JdbcTypeCode(SqlTypes.CHAR)
    @Column(name = "token_hash", nullable = false, unique = true, length = 64)
    private String tokenHash;

    @Column(name = "expires_at_utc", nullable = false)
    private Instant expiresAtUtc;

    @Column(name = "consumed_at_utc")
    private Instant consumedAtUtc;

    @Column(name = "created_at_utc", nullable = false)
    private Instant createdAtUtc;

    protected EmailVerificationTokenEntity() {
    }

    public EmailVerificationTokenEntity(
            UserEntity user,
            String tokenHash,
            Instant expiresAtUtc,
            Instant createdAtUtc) {
        this.publicId = UUID.randomUUID();
        this.user = user;
        this.tokenHash = tokenHash;
        this.expiresAtUtc = expiresAtUtc;
        this.createdAtUtc = createdAtUtc;
    }

    public UserEntity getUser() {
        return user;
    }

    public String getTokenHash() {
        return tokenHash;
    }

    public Instant getExpiresAtUtc() {
        return expiresAtUtc;
    }

    public Instant getConsumedAtUtc() {
        return consumedAtUtc;
    }

    public void consume(Instant consumedAtUtc) {
        this.consumedAtUtc = consumedAtUtc;
    }
}
