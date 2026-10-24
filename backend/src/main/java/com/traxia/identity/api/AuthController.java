package com.traxia.identity.api;

import com.traxia.identity.application.GoogleAuthService;
import com.traxia.identity.api.AuthDtos.GoogleLoginRequest;

import com.traxia.identity.application.AuthService;
import com.traxia.identity.application.AuthService.AuthResult;
import com.traxia.identity.application.RegistrationService;
import com.traxia.identity.api.AuthDtos.LoginRequest;
import com.traxia.identity.api.AuthDtos.MeResponse;
import com.traxia.identity.api.AuthDtos.RegisterRequest;
import com.traxia.identity.api.AuthDtos.RegisterResponse;
import com.traxia.identity.api.AuthDtos.VerifyEmailRequest;
import com.traxia.identity.api.AuthDtos.VerifyEmailResponse;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import java.util.Locale;
import java.util.Set;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpHeaders;
import org.springframework.http.ResponseCookie;
import org.springframework.http.ResponseEntity;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/auth")
public class AuthController {

    private final AuthService authService;
    private final RegistrationService registrationService;
    private final GoogleAuthService googleAuthService;
    private final String cookieName;
    private final boolean cookieSecure;
    private static final Set<String> NON_PRODUCTION_ENVIRONMENTS =
            Set.of("local", "development", "dev", "test");

    public AuthController(
            AuthService authService,
            RegistrationService registrationService,
            GoogleAuthService googleAuthService,
            @Value("${traxia.security.refresh.cookie-name}") String cookieName,
            @Value("${traxia.security.refresh.cookie-secure}") boolean cookieSecure,
            @Value("${APP_ENV:local}") String appEnvironment) {
        if (cookieName == null || !cookieName.matches("[A-Za-z0-9_-]{1,64}")) {
            throw new IllegalArgumentException("El nombre de cookie de refresh no es válido.");
        }
        String normalizedEnvironment = appEnvironment.trim().toLowerCase(Locale.ROOT);
        if (!cookieSecure && !NON_PRODUCTION_ENVIRONMENTS.contains(normalizedEnvironment)) {
            throw new IllegalStateException(
                    "La cookie de sesión debe usar Secure fuera de entornos locales y de prueba.");
        }
        this.authService = authService;
        this.registrationService = registrationService;
        this.googleAuthService = googleAuthService;
        this.cookieName = cookieName;
        this.cookieSecure = cookieSecure;
    }

    @PostMapping("/register")
    public ResponseEntity<RegisterResponse> register(@Valid @RequestBody RegisterRequest request) {
        registrationService.register(request);
        return ResponseEntity.status(HttpStatus.ACCEPTED)
                .body(new RegisterResponse(
                        "Si el correo puede registrarse, recibirás un enlace de verificación en el correo local de pruebas."));
    }

    @PostMapping("/verify-email")
    public VerifyEmailResponse verifyEmail(@Valid @RequestBody VerifyEmailRequest request) {
        registrationService.verifyEmail(request.token());
        return new VerifyEmailResponse("Correo verificado. Ya puedes iniciar sesión.");
    }

    @PostMapping("/google")
    public ResponseEntity<AuthDtos.AuthResponse> googleLogin(
            @Valid @RequestBody GoogleLoginRequest request) {
        return authResponse(googleAuthService.authenticate(request.idToken()));
    }

    @PostMapping("/login")
    public ResponseEntity<AuthDtos.AuthResponse> login(
            @Valid @RequestBody LoginRequest request,
            HttpServletRequest httpRequest) {
        return authResponse(authService.login(
                request.email(), request.password(), httpRequest.getRemoteAddr()));
    }

    @PostMapping("/refresh")
    public ResponseEntity<AuthDtos.AuthResponse> refresh(HttpServletRequest request) {
        String token = readRefreshCookie(request);
        return authResponse(authService.refresh(token));
    }

    @PostMapping("/logout")
    public ResponseEntity<Void> logout(HttpServletRequest request) {
        authService.logout(readRefreshCookie(request));
        return ResponseEntity.noContent()
                .header(HttpHeaders.SET_COOKIE, expiredRefreshCookie().toString())
                .build();
    }

    @GetMapping("/me")
    public MeResponse me(@AuthenticationPrincipal Jwt jwt) {
        return authService.getCurrentUser(jwt);
    }

    private ResponseEntity<AuthDtos.AuthResponse> authResponse(AuthResult result) {
        ResponseCookie cookie = ResponseCookie.from(cookieName, result.refreshToken())
                .httpOnly(true)
                .secure(cookieSecure)
                .sameSite("Strict")
                .path("/api/v1/auth")
                .maxAge(result.refreshExpiresInSeconds())
                .build();
        return ResponseEntity.ok()
                .header(HttpHeaders.SET_COOKIE, cookie.toString())
                .body(result.response());
    }

    private String readRefreshCookie(HttpServletRequest request) {
        if (request.getCookies() == null) {
            return null;
        }
        for (jakarta.servlet.http.Cookie cookie : request.getCookies()) {
            if (cookieName.equals(cookie.getName())) {
                return cookie.getValue();
            }
        }
        return null;
    }

    private ResponseCookie expiredRefreshCookie() {
        return ResponseCookie.from(cookieName, "")
                .httpOnly(true)
                .secure(cookieSecure)
                .sameSite("Strict")
                .path("/api/v1/auth")
                .maxAge(0)
                .build();
    }
}
