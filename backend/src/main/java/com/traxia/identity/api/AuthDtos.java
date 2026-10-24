package com.traxia.identity.api;

import jakarta.validation.constraints.AssertTrue;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
import java.nio.charset.StandardCharsets;
import java.util.List;
import java.util.UUID;

public final class AuthDtos {

    private AuthDtos() {
    }

    public record LoginRequest(
            @NotBlank @Email @Size(max = 254) String email,
            @NotBlank @Size(max = 72) String password) {

        @AssertTrue(message = "La contraseña supera el límite permitido.")
        public boolean isPasswordWithinBcryptLimit() {
            return password == null || password.getBytes(StandardCharsets.UTF_8).length <= 72;
        }
    }

    public record RegisterRequest(
            @NotBlank @Size(min = 2, max = 120) String displayName,
            @NotBlank @Email @Size(max = 254) String email,
            @NotBlank @Size(min = 16, max = 72) String password,
            @NotBlank @Pattern(regexp = "SHIPPER|DRIVER|LEGALIZER") String profile,
            @AssertTrue(message = "Debes aceptar el aviso local de prueba.")
            boolean testNoticeAccepted) {

        @AssertTrue(message = "La contraseña supera el límite permitido.")
        public boolean isPasswordWithinBcryptLimit() {
            return password == null || password.getBytes(StandardCharsets.UTF_8).length <= 72;
        }
    }

    public record RegisterResponse(String message) {
    }

    public record VerifyEmailRequest(@NotBlank @Size(max = 128) String token) {
    }

    public record VerifyEmailResponse(String message) {
    }

    public record AuthenticatedUser(UUID id, String email, List<String> roles) {
    }

    public record AuthResponse(
            String accessToken,
            String tokenType,
            long expiresInSeconds,
            AuthenticatedUser user) {
    }

    public record MeResponse(UUID id, String email, List<String> roles) {
    }

    public record ApiProblem(String title, int status, String detail) {
    }
}
