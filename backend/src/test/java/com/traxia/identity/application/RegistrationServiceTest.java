package com.traxia.identity.application;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verifyNoInteractions;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import com.traxia.common.audit.AuditService;
import com.traxia.identity.api.AuthDtos.RegisterRequest;
import com.traxia.identity.domain.AuthMethodEntity;
import com.traxia.identity.domain.EmailVerificationTokenEntity;
import com.traxia.identity.domain.UserEntity;
import com.traxia.identity.persistence.AuthMethodRepository;
import com.traxia.identity.persistence.EmailVerificationTokenRepository;
import com.traxia.identity.persistence.RegistrationNoticeAcceptanceRepository;
import com.traxia.identity.persistence.UserRepository;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.util.HexFormat;
import java.util.Optional;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;
import org.springframework.security.crypto.password.PasswordEncoder;

class RegistrationServiceTest {

    @Test
    void createsPendingAccountAndSendsOnlyAHashedVerificationToken() throws Exception {
        UserRepository users = mock(UserRepository.class);
        AuthMethodRepository authMethods = mock(AuthMethodRepository.class);
        RegistrationNoticeAcceptanceRepository notices =
                mock(RegistrationNoticeAcceptanceRepository.class);
        EmailVerificationTokenRepository tokens = mock(EmailVerificationTokenRepository.class);
        PasswordEncoder passwordEncoder = mock(PasswordEncoder.class);
        AuditService audit = mock(AuditService.class);
        RegistrationEmailSender emailSender = mock(RegistrationEmailSender.class);
        when(users.existsByEmailNormalized("persona@example.test")).thenReturn(false);
        when(users.save(any(UserEntity.class))).thenAnswer(invocation -> invocation.getArgument(0));
        when(authMethods.save(any(AuthMethodEntity.class)))
                .thenAnswer(invocation -> invocation.getArgument(0));
        when(tokens.save(any(EmailVerificationTokenEntity.class)))
                .thenAnswer(invocation -> invocation.getArgument(0));
        when(passwordEncoder.encode("Una-clave-de-prueba-de-16"))
                .thenReturn("bcrypt-hash");
        RegistrationService service = service(
                users, authMethods, notices, tokens, passwordEncoder, audit, emailSender,
                true, "local");

        service.register(new RegisterRequest(
                "Persona de prueba",
                " Persona@Example.Test ",
                "Una-clave-de-prueba-de-16",
                "DRIVER",
                true));

        ArgumentCaptor<UserEntity> userCaptor = ArgumentCaptor.forClass(UserEntity.class);
        verify(users).save(userCaptor.capture());
        UserEntity user = userCaptor.getValue();
        assertThat(user.getEmailNormalized()).isEqualTo("persona@example.test");
        assertThat(user.getDisplayName()).isEqualTo("Persona de prueba");
        assertThat(user.getRegistrationProfileCode()).isEqualTo("DRIVER");
        assertThat(user.getStatus()).isEqualTo("PENDING_VERIFICATION");
        assertThat(user.getEmailVerifiedAtUtc()).isNull();
        assertThat(user.getUserRoles()).isEmpty();

        ArgumentCaptor<AuthMethodEntity> methodCaptor =
                ArgumentCaptor.forClass(AuthMethodEntity.class);
        verify(authMethods).save(methodCaptor.capture());
        assertThat(methodCaptor.getValue().getStatus()).isEqualTo("PENDING_VERIFICATION");
        assertThat(methodCaptor.getValue().getCredentialHash()).isEqualTo("bcrypt-hash");
        verify(notices).save(any());

        ArgumentCaptor<EmailVerificationTokenEntity> tokenCaptor =
                ArgumentCaptor.forClass(EmailVerificationTokenEntity.class);
        verify(tokens).save(tokenCaptor.capture());
        ArgumentCaptor<String> rawToken = ArgumentCaptor.forClass(String.class);
        verify(emailSender).sendVerification(
                eq("persona@example.test"), eq("Persona de prueba"), rawToken.capture());
        assertThat(tokenCaptor.getValue().getTokenHash())
                .isEqualTo(hashToken(rawToken.getValue()))
                .isNotEqualTo(rawToken.getValue());
    }

    @Test
    void duplicateEmailGetsSameResponseWithoutSendingAnotherMessage() {
        UserRepository users = mock(UserRepository.class);
        RegistrationEmailSender emailSender = mock(RegistrationEmailSender.class);
        when(users.existsByEmailNormalized("persona@example.test")).thenReturn(true);
        RegistrationService service = service(
                users, mock(AuthMethodRepository.class),
                mock(RegistrationNoticeAcceptanceRepository.class),
                mock(EmailVerificationTokenRepository.class),
                mock(PasswordEncoder.class), mock(AuditService.class), emailSender, true, "local");

        service.register(new RegisterRequest(
                "Persona de prueba", "persona@example.test",
                "Una-clave-de-prueba-de-16", "DRIVER", true));

        verify(users, never()).save(any());
        verify(emailSender, never()).sendVerification(any(), any(), any());
    }

    @Test
    void verifiesEmailAndActivatesPendingCredentialsWithoutAssigningRoles() throws Exception {
        UserRepository users = mock(UserRepository.class);
        AuthMethodRepository authMethods = mock(AuthMethodRepository.class);
        RegistrationNoticeAcceptanceRepository notices =
                mock(RegistrationNoticeAcceptanceRepository.class);
        EmailVerificationTokenRepository tokens = mock(EmailVerificationTokenRepository.class);
        AuditService audit = mock(AuditService.class);
        String rawToken = "abcdefghijklmnopqrstuvwxyz0123456789ABCDEFG";
        UserEntity user = UserEntity.pendingRegistration(
                "persona@example.test", "Persona de prueba", "DRIVER", java.time.Instant.now());
        AuthMethodEntity authMethod = AuthMethodEntity.pendingEmailPassword(
                user, "bcrypt-hash", java.time.Instant.now());
        user.getAuthMethods().add(authMethod);
        EmailVerificationTokenEntity token = new EmailVerificationTokenEntity(
                user,
                hashToken(rawToken),
                java.time.Instant.now().plusSeconds(600),
                java.time.Instant.now());
        when(tokens.findByTokenHashForUpdate(hashToken(rawToken))).thenReturn(Optional.of(token));
        RegistrationService service = service(
                users, authMethods, notices, tokens, mock(PasswordEncoder.class), audit,
                mock(RegistrationEmailSender.class), true, "local");

        service.verifyEmail(rawToken);

        assertThat(user.getStatus()).isEqualTo("ACTIVE");
        assertThat(user.getEmailVerifiedAtUtc()).isNotNull();
        assertThat(authMethod.getStatus()).isEqualTo("ACTIVE");
        assertThat(authMethod.getVerifiedAtUtc()).isNotNull();
        assertThat(token.getConsumedAtUtc()).isNotNull();
        assertThat(user.getUserRoles()).isEmpty();
        verify(audit).record(eq(user), eq("AUTH_EMAIL_VERIFIED"), eq("USER"),
                eq(user.getPublicId()), eq("SUCCESS"));
    }

    @Test
    void rejectsExpiredVerificationTokensWithoutActivatingAccount() throws Exception {
        String rawToken = "abcdefghijklmnopqrstuvwxyz0123456789ABCDEFG";
        UserEntity user = UserEntity.pendingRegistration(
                "persona@example.test", "Persona de prueba", "DRIVER", java.time.Instant.now());
        EmailVerificationTokenEntity expiredToken = new EmailVerificationTokenEntity(
                user,
                hashToken(rawToken),
                java.time.Instant.now().minusSeconds(1),
                java.time.Instant.now().minusSeconds(601));
        EmailVerificationTokenRepository tokens = mock(EmailVerificationTokenRepository.class);
        AuditService audit = mock(AuditService.class);
        when(tokens.findByTokenHashForUpdate(hashToken(rawToken)))
                .thenReturn(Optional.of(expiredToken));
        RegistrationService service = service(
                mock(UserRepository.class), mock(AuthMethodRepository.class),
                mock(RegistrationNoticeAcceptanceRepository.class), tokens,
                mock(PasswordEncoder.class), audit, mock(RegistrationEmailSender.class),
                true, "local");

        assertThatThrownBy(() -> service.verifyEmail(rawToken))
                .isInstanceOf(RegistrationService.InvalidVerificationTokenException.class);

        assertThat(user.getStatus()).isEqualTo("PENDING_VERIFICATION");
        assertThat(user.getEmailVerifiedAtUtc()).isNull();
        assertThat(expiredToken.getConsumedAtUtc()).isNull();
        verifyNoInteractions(audit);
    }

    @Test
    void refusesRegistrationWhenDisabledOrOutsideDevelopment() {
        RegistrationService disabled = service(
                mock(UserRepository.class), mock(AuthMethodRepository.class),
                mock(RegistrationNoticeAcceptanceRepository.class),
                mock(EmailVerificationTokenRepository.class),
                mock(PasswordEncoder.class), mock(AuditService.class),
                mock(RegistrationEmailSender.class), false, "local");
        RegistrationService production = service(
                mock(UserRepository.class), mock(AuthMethodRepository.class),
                mock(RegistrationNoticeAcceptanceRepository.class),
                mock(EmailVerificationTokenRepository.class),
                mock(PasswordEncoder.class), mock(AuditService.class),
                mock(RegistrationEmailSender.class), true, "production");

        RegisterRequest request = new RegisterRequest(
                "Persona de prueba", "persona@example.test",
                "Una-clave-de-prueba-de-16", "DRIVER", true);
        assertThatThrownBy(() -> disabled.register(request))
                .isInstanceOf(RegistrationService.RegistrationDisabledException.class);
        assertThatThrownBy(() -> production.register(request))
                .isInstanceOf(RegistrationService.RegistrationDisabledException.class);
    }

    private static RegistrationService service(
            UserRepository users,
            AuthMethodRepository authMethods,
            RegistrationNoticeAcceptanceRepository notices,
            EmailVerificationTokenRepository tokens,
            PasswordEncoder passwordEncoder,
            AuditService audit,
            RegistrationEmailSender emailSender,
            boolean enabled,
            String environment) {
        return new RegistrationService(
                users, authMethods, notices, tokens, passwordEncoder, audit, emailSender,
                enabled, environment, "local-testing-1", 30);
    }

    private static String hashToken(String token) throws Exception {
        return HexFormat.of().formatHex(
                MessageDigest.getInstance("SHA-256")
                        .digest(token.getBytes(StandardCharsets.US_ASCII)));
    }
}
