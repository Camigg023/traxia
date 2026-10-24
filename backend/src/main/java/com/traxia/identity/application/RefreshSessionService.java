package com.traxia.identity.application;

import com.traxia.identity.domain.RefreshSessionEntity;
import com.traxia.identity.domain.UserEntity;
import com.traxia.identity.persistence.RefreshSessionRepository;
import com.traxia.identity.persistence.UserRepository;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.security.SecureRandom;
import java.time.Instant;
import java.util.Base64;
import java.util.HexFormat;
import java.util.Optional;
import java.util.UUID;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class RefreshSessionService {

    private final RefreshSessionRepository refreshSessionRepository;
    private final UserRepository userRepository;
    private final SecureRandom secureRandom = new SecureRandom();
    private final long lifetimeSeconds;

    public RefreshSessionService(
            RefreshSessionRepository refreshSessionRepository,
            UserRepository userRepository,
            @Value("${traxia.security.refresh.ttl-seconds}") long lifetimeSeconds) {
        if (lifetimeSeconds < 3600 || lifetimeSeconds > 2_592_000) {
            throw new IllegalArgumentException("La vigencia del refresh token debe estar entre una hora y 30 días.");
        }
        this.refreshSessionRepository = refreshSessionRepository;
        this.userRepository = userRepository;
        this.lifetimeSeconds = lifetimeSeconds;
    }

    @Transactional
    public IssuedRefreshToken issue(Long userId) {
        UserEntity user = userRepository.findById(userId)
                .orElseThrow(() -> new IllegalStateException("No se encontró la cuenta autenticada."));
        String rawToken = createRawToken();
        Instant now = Instant.now();
        UUID familyId = UUID.randomUUID();
        refreshSessionRepository.save(new RefreshSessionEntity(
                UUID.randomUUID(),
                familyId,
                user,
                hashToken(rawToken),
                now,
                now.plusSeconds(lifetimeSeconds)));
        return new IssuedRefreshToken(rawToken, familyId, lifetimeSeconds);
    }

    @Transactional
    public RotationResult rotate(String rawToken) {
        if (rawToken == null || rawToken.isBlank()) {
            return RotationResult.failure(RotationFailure.NOT_FOUND);
        }

        Optional<RefreshSessionEntity> candidate =
                refreshSessionRepository.findByTokenHashForUpdate(hashToken(rawToken));
        if (candidate.isEmpty()) {
            return RotationResult.failure(RotationFailure.NOT_FOUND);
        }

        RefreshSessionEntity current = candidate.get();
        Instant now = Instant.now();
        if (current.getRevokedAtUtc() != null) {
            refreshSessionRepository.revokeFamily(current.getFamilyId(), now);
            return RotationResult.failure(RotationFailure.REUSE_DETECTED);
        }
        if (!current.getExpiresAtUtc().isAfter(now)) {
            current.revoke(now);
            return RotationResult.failure(RotationFailure.EXPIRED);
        }

        current.revoke(now);
        String replacementToken = createRawToken();
        RefreshSessionEntity replacement = new RefreshSessionEntity(
                UUID.randomUUID(),
                current.getFamilyId(),
                current.getUser(),
                hashToken(replacementToken),
                now,
                now.plusSeconds(lifetimeSeconds));
        refreshSessionRepository.saveAndFlush(replacement);
        current.setReplacedById(replacement.getId());
        return RotationResult.success(
                replacementToken,
                current.getFamilyId(),
                current.getUser().getId(),
                lifetimeSeconds);
    }

    @Transactional
    public void revokeFamily(String rawToken) {
        if (rawToken == null || rawToken.isBlank()) {
            return;
        }
        refreshSessionRepository.findByTokenHashForUpdate(hashToken(rawToken))
                .ifPresent(session -> refreshSessionRepository.revokeFamily(
                        session.getFamilyId(), Instant.now()));
    }

    @Transactional
    public void revokeFamily(UUID familyId) {
        refreshSessionRepository.revokeFamily(familyId, Instant.now());
    }

    private String createRawToken() {
        byte[] bytes = new byte[32];
        secureRandom.nextBytes(bytes);
        return Base64.getUrlEncoder().withoutPadding().encodeToString(bytes);
    }

    static String hashToken(String rawToken) {
        try {
            byte[] digest = MessageDigest.getInstance("SHA-256")
                    .digest(rawToken.getBytes(StandardCharsets.UTF_8));
            return HexFormat.of().formatHex(digest);
        } catch (NoSuchAlgorithmException exception) {
            throw new IllegalStateException("SHA-256 no está disponible en este entorno.", exception);
        }
    }

    public record IssuedRefreshToken(String value, UUID familyId, long expiresInSeconds) {
    }

    public record RotationResult(
            boolean successful,
            RotationFailure failure,
            String replacementToken,
            UUID familyId,
            Long userId,
            long expiresInSeconds) {

        static RotationResult success(
                String token, UUID family, Long userId, long lifetimeSeconds) {
            return new RotationResult(true, null, token, family, userId, lifetimeSeconds);
        }

        static RotationResult failure(RotationFailure failure) {
            return new RotationResult(false, failure, null, null, null, 0);
        }
    }

    public enum RotationFailure {
        NOT_FOUND,
        EXPIRED,
        REUSE_DETECTED
    }
}
