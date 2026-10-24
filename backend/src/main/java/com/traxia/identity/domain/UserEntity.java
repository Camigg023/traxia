package com.traxia.identity.domain;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.OneToMany;
import jakarta.persistence.Table;
import jakarta.persistence.Version;
import java.time.Instant;
import java.util.HashSet;
import java.util.Set;
import java.util.UUID;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;

@Entity
@Table(name = "users")
public class UserEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @JdbcTypeCode(SqlTypes.BINARY)
    @Column(name = "public_id", nullable = false, unique = true, columnDefinition = "BINARY(16)")
    private UUID publicId;

    @Column(name = "email_normalized", nullable = false, unique = true, length = 254)
    private String emailNormalized;

    @Column(name = "display_name", length = 120)
    private String displayName;

    @Column(name = "registration_profile_code", length = 32)
    private String registrationProfileCode;

    @Column(name = "phone_e164", length = 32)
    private String phoneE164;

    @Column(nullable = false, length = 32)
    private String status;

    @Column(name = "email_verified_at_utc")
    private Instant emailVerifiedAtUtc;

    @Version
    @Column(nullable = false)
    private long version;

    @Column(name = "created_at_utc", nullable = false)
    private Instant createdAtUtc;

    @Column(name = "updated_at_utc", nullable = false)
    private Instant updatedAtUtc;

    @OneToMany(mappedBy = "user", fetch = FetchType.LAZY)
    private Set<AuthMethodEntity> authMethods = new HashSet<>();

    @OneToMany(mappedBy = "user", fetch = FetchType.LAZY)
    private Set<UserRoleEntity> userRoles = new HashSet<>();

    protected UserEntity() {
    }

    public static UserEntity bootstrapAdministrator(String emailNormalized, Instant now) {
        UserEntity user = new UserEntity();
        user.publicId = UUID.randomUUID();
        user.emailNormalized = emailNormalized;
        user.status = "ACTIVE";
        user.emailVerifiedAtUtc = now;
        user.createdAtUtc = now;
        user.updatedAtUtc = now;
        return user;
    }

    public static UserEntity pendingRegistration(
            String emailNormalized,
            String displayName,
            String registrationProfileCode,
            Instant now) {
        UserEntity user = new UserEntity();
        user.publicId = UUID.randomUUID();
        user.emailNormalized = emailNormalized;
        user.displayName = displayName;
        user.registrationProfileCode = registrationProfileCode;
        user.status = "PENDING_VERIFICATION";
        user.createdAtUtc = now;
        user.updatedAtUtc = now;
        return user;
    }

    public void verifyEmail(Instant verifiedAtUtc) {
        this.emailVerifiedAtUtc = verifiedAtUtc;
        this.status = "ACTIVE";
        this.updatedAtUtc = verifiedAtUtc;
    }

    public Long getId() {
        return id;
    }

    public UUID getPublicId() {
        return publicId;
    }

    public String getEmailNormalized() {
        return emailNormalized;
    }

    public String getDisplayName() {
        return displayName;
    }

    public String getRegistrationProfileCode() {
        return registrationProfileCode;
    }

    public String getStatus() {
        return status;
    }

    public Instant getEmailVerifiedAtUtc() {
        return emailVerifiedAtUtc;
    }

    public Set<AuthMethodEntity> getAuthMethods() {
        return authMethods;
    }

    public Set<UserRoleEntity> getUserRoles() {
        return userRoles;
    }
}
