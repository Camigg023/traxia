package com.traxia.identity.application;

import com.google.api.client.googleapis.auth.oauth2.GoogleIdToken;
import com.google.api.client.googleapis.auth.oauth2.GoogleIdTokenVerifier;
import com.google.api.client.http.javanet.NetHttpTransport;
import com.google.api.client.json.gson.GsonFactory;
import com.traxia.common.audit.AuditService;
import com.traxia.common.security.AccessTokenService;
import com.traxia.identity.api.AuthDtos.AuthResponse;
import com.traxia.identity.api.AuthDtos.AuthenticatedUser;
import com.traxia.identity.application.AuthService.AuthResult;
import com.traxia.identity.domain.AuthMethodEntity;
import com.traxia.identity.domain.UserEntity;
import com.traxia.identity.persistence.AuthMethodRepository;
import com.traxia.identity.persistence.UserRepository;
import java.time.Instant;
import java.util.Collections;
import java.util.List;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Verifica el ID Token de Google y devuelve (o crea) el usuario TRAXIA correspondiente.
 * Emite la sesión de autenticación nativa de TRAXIA (JWT + Refresh Token en cookie).
 */
@Service
public class GoogleAuthService {

    private final UserRepository userRepository;
    private final AuthMethodRepository authMethodRepository;
    private final AccessTokenService accessTokenService;
    private final RefreshSessionService refreshSessionService;
    private final AuditService auditService;
    private final String googleClientId;

    public GoogleAuthService(
            UserRepository userRepository,
            AuthMethodRepository authMethodRepository,
            AccessTokenService accessTokenService,
            RefreshSessionService refreshSessionService,
            AuditService auditService,
            @Value("${traxia.google.client-id:}") String googleClientId) {
        this.userRepository = userRepository;
        this.authMethodRepository = authMethodRepository;
        this.accessTokenService = accessTokenService;
        this.refreshSessionService = refreshSessionService;
        this.auditService = auditService;
        this.googleClientId = googleClientId;
    }

    /**
     * Autentica al usuario a partir del ID Token de Google.
     *
     * @param rawIdToken JWT firmado por Google
     * @return AuthResult con la respuesta y el refresh token
     */
    @Transactional
    public AuthResult authenticate(String rawIdToken) {
        if (googleClientId == null || googleClientId.isBlank()) {
            throw new IllegalStateException(
                    "GOOGLE_CLIENT_ID no está configurado en el servidor. "
                            + "Agrega GOOGLE_CLIENT_ID al archivo .env.local y reinicia el backend.");
        }

        GoogleIdToken idToken = verifyToken(rawIdToken);
        GoogleIdToken.Payload payload = idToken.getPayload();

        String email = payload.getEmail();
        String googleSub = payload.getSubject();
        String rawName = (String) payload.get("name");
        final String displayName = (rawName != null && !rawName.isBlank()) ? rawName : email.split("@")[0];

        Instant now = Instant.now();
        String normalizedEmail = email.trim().toLowerCase();

        UserEntity user = userRepository.findByEmailNormalized(normalizedEmail)
                .orElseGet(() -> createGoogleUser(normalizedEmail, displayName, googleSub, now));

        List<String> roleCodes = user.getUserRoles().stream()
                .filter(r -> r.getRevokedAtUtc() == null)
                .map(r -> r.getRole().getCode())
                .toList();

        AccessTokenService.IssuedAccessToken accessToken = accessTokenService.issue(
                user.getPublicId(), user.getEmailNormalized(), roleCodes);
        RefreshSessionService.IssuedRefreshToken refreshToken = refreshSessionService.issue(user.getId());

        auditService.record(user, "AUTH_GOOGLE_LOGIN", "USER", user.getPublicId(), "SUCCESS");

        return new AuthResult(
                new AuthResponse(
                        accessToken.value(),
                        "Bearer",
                        accessToken.expiresInSeconds(),
                        new AuthenticatedUser(
                                user.getPublicId(),
                                user.getEmailNormalized(),
                                roleCodes)),
                refreshToken.value(),
                refreshToken.expiresInSeconds());
    }

    // ── Helpers ──────────────────────────────────────────────────────────────

    private GoogleIdToken verifyToken(String rawIdToken) {
        try {
            GoogleIdTokenVerifier verifier = new GoogleIdTokenVerifier.Builder(
                    new NetHttpTransport(),
                    GsonFactory.getDefaultInstance())
                    .setAudience(Collections.singletonList(googleClientId))
                    .build();

            GoogleIdToken token = verifier.verify(rawIdToken);
            if (token == null) {
                throw new IllegalArgumentException(
                        "El token de Google no es válido o ha expirado. Vuelve a iniciar sesión.");
            }
            return token;
        } catch (IllegalArgumentException e) {
            throw e;
        } catch (Exception e) {
            throw new IllegalArgumentException(
                    "No se pudo verificar el token de Google: " + e.getMessage(), e);
        }
    }

    private UserEntity createGoogleUser(String email, String displayName, String googleSub, Instant now) {
        UserEntity user = UserEntity.pendingRegistration(
                email,
                displayName,
                "DRIVER",
                now);
        user.verifyEmail(now);
        UserEntity savedUser = userRepository.save(user);

        AuthMethodEntity googleMethod = AuthMethodEntity.googleMethod(savedUser, googleSub, now);
        authMethodRepository.save(googleMethod);
        savedUser.getAuthMethods().add(googleMethod);

        return savedUser;
    }
}
