package com.traxia.common.audit;

import com.traxia.identity.domain.UserEntity;
import java.time.Instant;
import java.util.UUID;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;

@Service
public class AuditService {

    private final AuditEventRepository auditEventRepository;

    public AuditService(AuditEventRepository auditEventRepository) {
        this.auditEventRepository = auditEventRepository;
    }

    @Transactional
    public void record(
            UserEntity actor,
            String action,
            String entityType,
            UUID entityPublicId,
            String outcome) {
        auditEventRepository.save(new AuditEventEntity(
                actor,
                action,
                entityType,
                entityPublicId,
                outcome,
                null,
                Instant.now()));
    }

    @Transactional(propagation = Propagation.REQUIRES_NEW)
    public void recordAuthenticationFailure(String action) {
        auditEventRepository.save(new AuditEventEntity(
                null,
                action,
                null,
                null,
                "FAILURE",
                null,
                Instant.now()));
    }
}
