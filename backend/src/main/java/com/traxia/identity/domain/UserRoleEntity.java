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

@Entity
@Table(name = "user_roles")
public class UserRoleEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "user_id", nullable = false)
    private UserEntity user;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "role_id", nullable = false)
    private RoleEntity role;

    @Column(name = "assigned_at_utc", nullable = false)
    private Instant assignedAtUtc;

    @Column(name = "revoked_at_utc")
    private Instant revokedAtUtc;

    protected UserRoleEntity() {
    }

    public static UserRoleEntity assign(UserEntity user, RoleEntity role, Instant now) {
        UserRoleEntity assignment = new UserRoleEntity();
        assignment.user = user;
        assignment.role = role;
        assignment.assignedAtUtc = now;
        return assignment;
    }

    public RoleEntity getRole() {
        return role;
    }

    public Instant getRevokedAtUtc() {
        return revokedAtUtc;
    }
}
