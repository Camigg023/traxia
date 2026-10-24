package com.traxia.identity.persistence;

import com.traxia.identity.domain.UserEntity;
import java.util.Optional;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface UserRepository extends JpaRepository<UserEntity, Long> {

    @EntityGraph(attributePaths = {
            "authMethods",
            "userRoles",
            "userRoles.role"
    })
    Optional<UserEntity> findByEmailNormalized(String emailNormalized);

    @EntityGraph(attributePaths = {
            "authMethods",
            "userRoles",
            "userRoles.role"
    })
    Optional<UserEntity> findWithAuthenticationDataById(Long id);

    @EntityGraph(attributePaths = {
            "authMethods",
            "userRoles",
            "userRoles.role"
    })
    Optional<UserEntity> findWithAuthenticationDataByPublicId(java.util.UUID publicId);

    boolean existsByEmailNormalized(String emailNormalized);

    @Query("""
            select count(distinct u.id)
            from UserEntity u
            join u.userRoles ur
            join ur.role r
            where u.status = 'ACTIVE'
              and r.code = :roleCode
              and ur.revokedAtUtc is null
            """)
    long countActiveUsersWithRole(@Param("roleCode") String roleCode);
}
