package com.traxia.identity.persistence;

import com.traxia.identity.domain.RegistrationNoticeAcceptanceEntity;
import org.springframework.data.jpa.repository.JpaRepository;

public interface RegistrationNoticeAcceptanceRepository
        extends JpaRepository<RegistrationNoticeAcceptanceEntity, Long> {
}
