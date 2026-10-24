package com.traxia.identity.persistence;

import com.traxia.identity.domain.RoleEntity;
import jakarta.persistence.LockModeType;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface RoleRepository extends JpaRepository<RoleEntity, Long> {

    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("select role from RoleEntity role where role.code = :code")
    Optional<RoleEntity> findByCodeForUpdate(@Param("code") String code);
}
