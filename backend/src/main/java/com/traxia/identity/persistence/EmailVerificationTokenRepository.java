package com.traxia.identity.persistence;

import com.traxia.identity.domain.EmailVerificationTokenEntity;
import jakarta.persistence.LockModeType;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface EmailVerificationTokenRepository
        extends JpaRepository<EmailVerificationTokenEntity, Long> {

    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("""
            select verificationToken
            from EmailVerificationTokenEntity verificationToken
            where verificationToken.tokenHash = :tokenHash
            """)
    Optional<EmailVerificationTokenEntity> findByTokenHashForUpdate(
            @Param("tokenHash") String tokenHash);
}
