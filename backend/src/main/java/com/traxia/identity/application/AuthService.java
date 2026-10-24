package com.traxia.identity.application;

import com.traxia.common.audit.AuditService;
import com.traxia.common.security.AccessTokenService;
import com.traxia.common.security.GlobalRolePolicy;
import com.traxia.common.security.LoginAttemptLimiter;
import com.traxia.identity.api.AuthDtos.AuthResponse;
import com.traxia.identity.api.AuthDtos.AuthenticatedUser;
import com.traxia.identity.api.AuthDtos.MeResponse;
import com.traxia.identity.domain.UserEntity;
import com.traxia.identity.persistence.UserRepository;
import java.util.List;
import java.util.UUID;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.AuthenticationException;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class AuthService {

    private final AuthenticationManager authenticationManager;
    private final AccessTokenService accessTokenService;
    private final RefreshSessionService refreshSessionService;
    private final TraxiaUserDetailsService userDetailsService;
    private final UserRepository userRepository;
    private final AuditService auditService;
    private final LoginAttemptLimiter loginAttemptLimiter;

    public AuthService(
            AuthenticationManager authenticationManager,
            AccessTokenService accessTokenService,
            RefreshSessionService refreshSessionService,
            TraxiaUserDetailsService userDetailsService,
            UserRepository userRepository,
            AuditService auditService,
            LoginAttemptLimiter loginAttemptLimiter) {
        this.authenticationManager = authenticationManager;
        this.accessTokenService = accessTokenService;
        this.refreshSessionService = refreshSessionService;
        this.userDetailsService = userDetailsService;
        this.userRepository = userRepository;
        this.auditService = auditService;
        this.loginAttemptLimiter = loginAttemptLimiter;
    }

    @Transactional
    public AuthResult login(String email, String password, String remoteAddress) {
        String normalizedEmail = TraxiaUserDetailsService.normalizeEmail(email);
        loginAttemptLimiter.assertAllowed(normalizedEmail, remoteAddress);
        Authentication authentication;
        try {
            authentication = authenticationManager.authenticate(
                    UsernamePasswordAuthenticationToken.unauthenticated(
                            normalizedEmail, password));
        } catch (AuthenticationException exception) {
            loginAttemptLimiter.recordFailure(normalizedEmail, remoteAddress);
            auditService.recordAuthenticationFailure("AUTH_LOGIN");
            throw new InvalidCredentialsException();
        }

        loginAttemptLimiter.clearAccountFailures(normalizedEmail);
        TraxiaUserDetails principal = (TraxiaUserDetails) authentication.getPrincipal();
        UserEntity user = userRepository.findById(principal.getUserId())
                .orElseThrow(() -> new IllegalStateException("No se encontró la cuenta autenticada."));
        return issueAuthResult(user, principal);
    }

    public AuthResult refresh(String rawRefreshToken) {
        RefreshSessionService.RotationResult rotation = refreshSessionService.rotate(rawRefreshToken);
        if (!rotation.successful()) {
            auditService.recordAuthenticationFailure("AUTH_REFRESH");
            throw new InvalidRefreshTokenException();
        }

        TraxiaUserDetails principal;
        try {
            principal = userDetailsService.loadEnabledUserById(rotation.userId());
        } catch (org.springframework.security.core.userdetails.UsernameNotFoundException exception) {
            refreshSessionService.revokeFamily(rotation.familyId());
            auditService.recordAuthenticationFailure("AUTH_REFRESH");
            throw new InvalidRefreshTokenException();
        }

        AccessTokenService.IssuedAccessToken accessToken = accessTokenService.issue(
                principal.getPublicId(), principal.getUsername(), principal.getRoleCodes());
        auditService.record(
                userRepository.findById(principal.getUserId()).orElseThrow(),
                "AUTH_REFRESH",
                "REFRESH_SESSION",
                rotation.familyId(),
                "SUCCESS");
        return new AuthResult(
                new AuthResponse(
                        accessToken.value(),
                        "Bearer",
                        accessToken.expiresInSeconds(),
                        new AuthenticatedUser(
                                principal.getPublicId(),
                                principal.getUsername(),
                                principal.getRoleCodes())),
                rotation.replacementToken(),
                rotation.expiresInSeconds());
    }

    @Transactional
    public void logout(String rawRefreshToken) {
        refreshSessionService.revokeFamily(rawRefreshToken);
        auditService.record(null, "AUTH_LOGOUT", "REFRESH_SESSION", null, "SUCCESS");
    }

    public MeResponse getCurrentUser(Jwt jwt) {
        List<String> roles = GlobalRolePolicy.filter(jwt.getClaimAsStringList("roles"));
        return new MeResponse(
                UUID.fromString(jwt.getSubject()),
                jwt.getClaimAsString("email"),
                roles);
    }

    private AuthResult issueAuthResult(UserEntity user, TraxiaUserDetails principal) {
        AccessTokenService.IssuedAccessToken accessToken = accessTokenService.issue(
                user.getPublicId(), user.getEmailNormalized(), principal.getRoleCodes());
        RefreshSessionService.IssuedRefreshToken refreshToken =
                refreshSessionService.issue(user.getId());
        auditService.record(user, "AUTH_LOGIN", "USER", user.getPublicId(), "SUCCESS");
        return new AuthResult(
                new AuthResponse(
                        accessToken.value(),
                        "Bearer",
                        accessToken.expiresInSeconds(),
                        new AuthenticatedUser(
                                user.getPublicId(),
                                user.getEmailNormalized(),
                                principal.getRoleCodes())),
                refreshToken.value(),
                refreshToken.expiresInSeconds());
    }

    public record AuthResult(
            AuthResponse response,
            String refreshToken,
            long refreshExpiresInSeconds) {
    }

    public static final class InvalidCredentialsException extends RuntimeException {
    }

    public static final class InvalidRefreshTokenException extends RuntimeException {
    }
}
