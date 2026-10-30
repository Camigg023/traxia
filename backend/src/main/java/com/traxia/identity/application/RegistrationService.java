package com.traxia.identity.application;

import com.traxia.common.audit.AuditService;
import com.traxia.identity.api.AuthDtos.RegisterRequest;
import com.traxia.identity.domain.AuthMethodEntity;
import com.traxia.identity.domain.EmailVerificationTokenEntity;
import com.traxia.identity.domain.RegistrationNoticeAcceptanceEntity;
import com.traxia.identity.domain.UserEntity;
import com.traxia.identity.persistence.AuthMethodRepository;
import com.traxia.identity.persistence.EmailVerificationTokenRepository;
import com.traxia.identity.persistence.RegistrationNoticeAcceptanceRepository;
import com.traxia.identity.persistence.UserRepository;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.security.SecureRandom;
import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.Base64;
import java.util.HexFormat;
import java.util.Locale;
import java.util.Set;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class RegistrationService {

    private static final Set<String> ALLOWED_ENVIRONMENTS =
            Set.of("local", "development", "dev", "test", "production");
    private static final Set<String> ALLOWED_PROFILES =
            Set.of("SHIPPER", "DRIVER", "LEGALIZER");
    private static final SecureRandom SECURE_RANDOM = new SecureRandom();
    private static final String REGISTRATION_MESSAGE =
            "Si el correo puede registrarse, recibirás un enlace de verificación en el correo local de pruebas.";

    private final UserRepository userRepository;
    private final AuthMethodRepository authMethodRepository;
    private final RegistrationNoticeAcceptanceRepository noticeRepository;
    private final EmailVerificationTokenRepository tokenRepository;
    private final PasswordEncoder passwordEncoder;
    private final AuditService auditService;
    private final RegistrationEmailSender emailSender;
    private final boolean registrationEnabled;
    private final String appEnvironment;
    private final String testNoticeVersion;
    private final long verificationTtlMinutes;

    public RegistrationService(
            UserRepository userRepository,
            AuthMethodRepository authMethodRepository,
            RegistrationNoticeAcceptanceRepository noticeRepository,
            EmailVerificationTokenRepository tokenRepository,
            PasswordEncoder passwordEncoder,
            AuditService auditService,
            RegistrationEmailSender emailSender,
            @Value("${traxia.registration.enabled}") boolean registrationEnabled,
            @Value("${APP_ENV:local}") String appEnvironment,
            @Value("${traxia.registration.test-notice-version}") String testNoticeVersion,
            @Value("${traxia.registration.verification-ttl-minutes}") long verificationTtlMinutes) {
        this.userRepository = userRepository;
        this.authMethodRepository = authMethodRepository;
        this.noticeRepository = noticeRepository;
        this.tokenRepository = tokenRepository;
        this.passwordEncoder = passwordEncoder;
        this.auditService = auditService;
        this.emailSender = emailSender;
        this.registrationEnabled = registrationEnabled;
        this.appEnvironment = appEnvironment.trim().toLowerCase(Locale.ROOT);
        this.testNoticeVersion = testNoticeVersion;
        this.verificationTtlMinutes = verificationTtlMinutes;
    }

    @Transactional
    public void register(RegisterRequest request) {
        requireRegistrationEnabled();
        String email = TraxiaUserDetailsService.normalizeEmail(request.email());
        String profile = request.profile().trim().toUpperCase(Locale.ROOT);
        String displayName = request.displayName().trim();
        if (!ALLOWED_PROFILES.contains(profile)
                || request.password().codePointCount(0, request.password().length()) < 16
                || request.password().getBytes(StandardCharsets.UTF_8).length > 72) {
            throw new InvalidRegistrationException();
        }
        if (userRepository.existsByEmailNormalized(email)) {
            return;
        }

        Instant now = Instant.now();
        UserEntity user = userRepository.save(
                UserEntity.pendingRegistration(email, displayName, profile, now));
        String passwordHash = passwordEncoder.encode(request.password());
        AuthMethodEntity authMethod = authMethodRepository.save(
                AuthMethodEntity.pendingEmailPassword(user, passwordHash, now));
        user.getAuthMethods().add(authMethod);
        noticeRepository.save(new RegistrationNoticeAcceptanceEntity(
                user, testNoticeVersion, now));

        String rawToken = createRawToken();
        tokenRepository.save(new EmailVerificationTokenEntity(
                user,
                hashToken(rawToken),
                now.plus(verificationTtlMinutes, ChronoUnit.MINUTES),
                now));
        auditService.record(user, "AUTH_REGISTER", "USER", user.getPublicId(), "PENDING_VERIFICATION");
        emailSender.sendVerification(email, displayName, rawToken);
    }

    @Transactional
    public void verifyEmail(String rawToken) {
        requireRegistrationEnabled();
        if (rawToken == null || !rawToken.matches("[A-Za-z0-9_-]{43}")) {
            throw new InvalidVerificationTokenException();
        }
        Instant now = Instant.now();
        EmailVerificationTokenEntity token = tokenRepository.findByTokenHashForUpdate(hashToken(rawToken))
                .filter(candidate -> candidate.getConsumedAtUtc() == null)
                .filter(candidate -> candidate.getExpiresAtUtc().isAfter(now))
                .orElseThrow(InvalidVerificationTokenException::new);
        UserEntity user = token.getUser();
        if (!"PENDING_VERIFICATION".equals(user.getStatus())) {
            throw new InvalidVerificationTokenException();
        }
        AuthMethodEntity emailMethod = user.getAuthMethods().stream()
                .filter(method -> "EMAIL".equals(method.getProviderCode()))
                .filter(method -> "PENDING_VERIFICATION".equals(method.getStatus()))
                .findFirst()
                .orElseThrow(InvalidVerificationTokenException::new);

        token.consume(now);
        user.verifyEmail(now);
        emailMethod.verify(now);
        auditService.record(user, "AUTH_EMAIL_VERIFIED", "USER", user.getPublicId(), "SUCCESS");
    }

    private void requireRegistrationEnabled() {
        if (!registrationEnabled || !ALLOWED_ENVIRONMENTS.contains(appEnvironment)) {
            throw new RegistrationDisabledException();
        }
    }

    private static String createRawToken() {
        byte[] bytes = new byte[32];
        SECURE_RANDOM.nextBytes(bytes);
        return Base64.getUrlEncoder().withoutPadding().encodeToString(bytes);
    }

    private static String hashToken(String token) {
        try {
            byte[] digest = MessageDigest.getInstance("SHA-256")
                    .digest(token.getBytes(StandardCharsets.US_ASCII));
            return HexFormat.of().formatHex(digest);
        } catch (NoSuchAlgorithmException exception) {
            throw new IllegalStateException("SHA-256 no está disponible.", exception);
        }
    }

    public static final class RegistrationDisabledException extends RuntimeException {
    }

    public static final class InvalidRegistrationException extends RuntimeException {
    }

    public static final class InvalidVerificationTokenException extends RuntimeException {
    }
}
