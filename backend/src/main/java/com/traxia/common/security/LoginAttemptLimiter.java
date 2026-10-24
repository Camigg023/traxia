package com.traxia.common.security;

import java.nio.charset.StandardCharsets;
import java.security.GeneralSecurityException;
import java.time.Duration;
import java.time.Instant;
import java.util.Base64;
import java.util.Arrays;
import javax.crypto.Mac;
import javax.crypto.SecretKey;
import javax.crypto.spec.SecretKeySpec;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;

@Service
public class LoginAttemptLimiter {

    private static final String UPSERT_SQL = """
            INSERT INTO auth_attempt_limits (
                bucket_hash, window_started_at_utc, failure_count, blocked_until_utc, updated_at_utc
            ) VALUES (?, ?, 1, NULL, ?)
            ON DUPLICATE KEY UPDATE
                blocked_until_utc = CASE
                    WHEN window_started_at_utc <= ? THEN NULL
                    WHEN failure_count + 1 >= ? THEN ?
                    ELSE blocked_until_utc
                END,
                failure_count = CASE
                    WHEN window_started_at_utc <= ? THEN 1
                    ELSE failure_count + 1
                END,
                window_started_at_utc = CASE
                    WHEN window_started_at_utc <= ? THEN ?
                    ELSE window_started_at_utc
                END,
                updated_at_utc = ?
            """;

    private final JdbcTemplate jdbcTemplate;
    private final SecretKey hashingKey;
    private final int accountFailureLimit;
    private final int addressFailureLimit;
    private final Duration window;
    private final Duration blockDuration;

    public LoginAttemptLimiter(
            JdbcTemplate jdbcTemplate,
            @Value("${traxia.security.login-limit.hashing-secret-base64}") String hashingSecretBase64,
            @Value("${traxia.security.login-limit.account-failures}") int accountFailureLimit,
            @Value("${traxia.security.login-limit.address-failures}") int addressFailureLimit,
            @Value("${traxia.security.login-limit.window-seconds}") long windowSeconds,
            @Value("${traxia.security.login-limit.block-seconds}") long blockSeconds,
            @Value("${traxia.security.login-limit.cleanup-delay-millis}") long cleanupDelayMillis) {
        if (accountFailureLimit < 2 || addressFailureLimit < accountFailureLimit
                || windowSeconds < 60 || blockSeconds < 60 || cleanupDelayMillis < 60_000) {
            throw new IllegalArgumentException("La configuración de límite de intentos no es válida.");
        }
        this.jdbcTemplate = jdbcTemplate;
        byte[] decodedSecret;
        try {
            decodedSecret = Base64.getDecoder().decode(hashingSecretBase64);
        } catch (IllegalArgumentException exception) {
            throw new IllegalArgumentException(
                    "La clave HMAC del límite de intentos debe estar codificada en Base64.", exception);
        }
        if (decodedSecret.length < 32) {
            Arrays.fill(decodedSecret, (byte) 0);
            throw new IllegalArgumentException(
                    "La clave HMAC del límite de intentos debe contener al menos 32 bytes.");
        }
        this.hashingKey = new SecretKeySpec(decodedSecret, "HmacSHA256");
        Arrays.fill(decodedSecret, (byte) 0);
        this.accountFailureLimit = accountFailureLimit;
        this.addressFailureLimit = addressFailureLimit;
        this.window = Duration.ofSeconds(windowSeconds);
        this.blockDuration = Duration.ofSeconds(blockSeconds);
    }

    public void assertAllowed(String normalizedEmail, String remoteAddress) {
        Instant now = Instant.now();
        checkBucket(hashBucket("email", normalizedEmail), "correo", now);
        checkBucket(hashBucket("address", requireRemoteAddress(remoteAddress)), "conexión", now);
    }

    @Transactional(propagation = Propagation.REQUIRES_NEW)
    public void recordFailure(String normalizedEmail, String remoteAddress) {
        Instant now = Instant.now();
        recordBucket(hashBucket("email", normalizedEmail), accountFailureLimit, now);
        recordBucket(hashBucket("address", requireRemoteAddress(remoteAddress)), addressFailureLimit, now);
    }

    @Transactional
    public void clearAccountFailures(String normalizedEmail) {
        jdbcTemplate.update(
                "DELETE FROM auth_attempt_limits WHERE bucket_hash = ?",
                hashBucket("email", normalizedEmail));
    }

    @Scheduled(fixedDelayString = "${traxia.security.login-limit.cleanup-delay-millis}")
    @Transactional
    public void deleteExpiredBuckets() {
        jdbcTemplate.update(
                """
                        DELETE FROM auth_attempt_limits
                        WHERE window_started_at_utc < ?
                          AND (blocked_until_utc IS NULL OR blocked_until_utc <= ?)
                        """,
                java.sql.Timestamp.from(Instant.now().minus(window)),
                java.sql.Timestamp.from(Instant.now()));
    }

    private void checkBucket(byte[] bucketHash, String category, Instant now) {
        var blockedUntil = jdbcTemplate.query(
                "SELECT blocked_until_utc FROM auth_attempt_limits WHERE bucket_hash = ?",
                resultSet -> {
                    if (!resultSet.next()) {
                        return null;
                    }
                    java.sql.Timestamp timestamp = resultSet.getTimestamp(1);
                    return timestamp == null ? null : timestamp.toInstant();
                },
                bucketHash);
        if (blockedUntil != null && blockedUntil.isAfter(now)) {
            long retryAfter = Math.max(1, Duration.between(now, blockedUntil).toSeconds());
            throw new LoginRateLimitExceededException(category, retryAfter);
        }
    }

    private void recordBucket(byte[] bucketHash, int failureLimit, Instant now) {
        Instant cutoff = now.minus(window);
        Instant blockedUntil = now.plus(blockDuration);
        java.sql.Timestamp timestamp = java.sql.Timestamp.from(now);
        jdbcTemplate.update(
                UPSERT_SQL,
                bucketHash,
                timestamp,
                timestamp,
                java.sql.Timestamp.from(cutoff),
                failureLimit,
                java.sql.Timestamp.from(blockedUntil),
                java.sql.Timestamp.from(cutoff),
                java.sql.Timestamp.from(cutoff),
                timestamp,
                timestamp);
    }

    private byte[] hashBucket(String type, String value) {
        if (value == null || value.isBlank()) {
            throw new IllegalArgumentException("No se puede limitar un intento sin identificador.");
        }
        try {
            Mac mac = Mac.getInstance("HmacSHA256");
            mac.init(hashingKey);
            return mac.doFinal((type + ":" + value).getBytes(StandardCharsets.UTF_8));
        } catch (GeneralSecurityException exception) {
            throw new IllegalStateException("No se pudo proteger la clave del límite de intentos.", exception);
        }
    }

    private static String requireRemoteAddress(String remoteAddress) {
        if (remoteAddress == null || remoteAddress.isBlank()) {
            throw new IllegalArgumentException("No se pudo determinar la conexión del usuario.");
        }
        return remoteAddress;
    }

    public static final class LoginRateLimitExceededException extends RuntimeException {

        private final String category;
        private final long retryAfterSeconds;

        public LoginRateLimitExceededException(String category, long retryAfterSeconds) {
            super("Se alcanzó el límite temporal de intentos.");
            this.category = category;
            this.retryAfterSeconds = retryAfterSeconds;
        }

        public String getCategory() {
            return category;
        }

        public long getRetryAfterSeconds() {
            return retryAfterSeconds;
        }
    }
}
