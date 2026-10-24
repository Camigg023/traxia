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
@Table(name = "auth_methods")
public class AuthMethodEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @JdbcTypeCode(SqlTypes.BINARY)
    @Column(name = "public_id", nullable = false, unique = true, columnDefinition = "BINARY(16)")
    private UUID publicId;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "user_id", nullable = false)
    private UserEntity user;

    @Column(name = "provider_code", nullable = false, length = 32)
    private String providerCode;

    @Column(name = "provider_subject", length = 255)
    private String providerSubject;

    @Column(name = "credential_hash", length = 255)
    private String credentialHash;

    @Column(nullable = false, length = 32)
    private String status;

    @Column(name = "verified_at_utc")
    private Instant verifiedAtUtc;

    @Column(name = "created_at_utc", nullable = false)
    private Instant createdAtUtc;

    protected AuthMethodEntity() {
    }

    public static AuthMethodEntity emailPassword(
            UserEntity user, String passwordHash, Instant now) {
        return emailPassword(user, passwordHash, now, "ACTIVE");
    }

    public static AuthMethodEntity pendingEmailPassword(
            UserEntity user, String passwordHash, Instant now) {
        return emailPassword(user, passwordHash, now, "PENDING_VERIFICATION");
    }

    private static AuthMethodEntity emailPassword(
            UserEntity user, String passwordHash, Instant now, String status) {
        AuthMethodEntity method = new AuthMethodEntity();
        method.publicId = UUID.randomUUID();
        method.user = user;
        method.providerCode = "EMAIL";
        method.credentialHash = passwordHash;
        method.status = status;
        if ("ACTIVE".equals(status)) {
            method.verifiedAtUtc = now;
        }
        method.createdAtUtc = now;
        return method;
    }

    public void verify(Instant verifiedAtUtc) {
        this.status = "ACTIVE";
        this.verifiedAtUtc = verifiedAtUtc;
    }

    public Instant getVerifiedAtUtc() {
        return verifiedAtUtc;
    }

    public String getProviderCode() {
        return providerCode;
    }

    public String getCredentialHash() {
        return credentialHash;
    }

    public String getStatus() {
        return status;
    }
}
