package com.traxia.identity.persistence;

import com.traxia.identity.domain.AuthMethodEntity;
import org.springframework.data.jpa.repository.JpaRepository;

public interface AuthMethodRepository extends JpaRepository<AuthMethodEntity, Long> {
}
