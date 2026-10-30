package com.traxia.identity.api;

import com.traxia.identity.application.AuthService.InvalidCredentialsException;
import com.traxia.identity.application.AuthService.InvalidRefreshTokenException;
import com.traxia.identity.application.RegistrationService.InvalidRegistrationException;
import com.traxia.identity.application.RegistrationService.InvalidVerificationTokenException;
import com.traxia.identity.application.RegistrationService.RegistrationDisabledException;
import com.traxia.identity.application.RegistrationService.EmailAlreadyRegisteredException;
import com.traxia.identity.application.RegistrationEmailSender.RegistrationEmailDeliveryException;
import com.traxia.common.security.LoginAttemptLimiter.LoginRateLimitExceededException;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.converter.HttpMessageNotReadableException;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

@RestControllerAdvice
public class AuthExceptionHandler {

    @ExceptionHandler(InvalidCredentialsException.class)
    public ResponseEntity<AuthDtos.ApiProblem> invalidCredentials() {
        return problem(HttpStatus.UNAUTHORIZED, "No autorizado", "Correo o contraseña incorrectos.");
    }

    @ExceptionHandler(InvalidRefreshTokenException.class)
    public ResponseEntity<AuthDtos.ApiProblem> invalidRefreshToken() {
        return problem(
                HttpStatus.UNAUTHORIZED,
                "No autorizado",
                "La sesión expiró o ya no es válida. Inicia sesión de nuevo.");
    }

    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<AuthDtos.ApiProblem> invalidRequest() {
        return problem(
                HttpStatus.BAD_REQUEST,
                "Solicitud no válida",
                "Revisa los datos enviados e inténtalo de nuevo.");
    }

    @ExceptionHandler(InvalidRegistrationException.class)
    public ResponseEntity<AuthDtos.ApiProblem> invalidRegistration() {
        return problem(
                HttpStatus.BAD_REQUEST,
                "Registro no válido",
                "Revisa el perfil y los requisitos de la contraseña.");
    }

    @ExceptionHandler(EmailAlreadyRegisteredException.class)
    public ResponseEntity<AuthDtos.ApiProblem> emailAlreadyRegistered() {
        return problem(
                HttpStatus.CONFLICT,
                "Correo ya registrado",
                "Este correo ya tiene una cuenta en TRAXIA. Inicia sesión directamente.");
    }

    @ExceptionHandler(IllegalArgumentException.class)
    public ResponseEntity<AuthDtos.ApiProblem> illegalArgument(IllegalArgumentException ex) {
        return problem(
                HttpStatus.BAD_REQUEST,
                "Solicitud no válida",
                ex.getMessage() != null ? ex.getMessage() : "Parámetros no válidos.");
    }

    @ExceptionHandler(InvalidVerificationTokenException.class)
    public ResponseEntity<AuthDtos.ApiProblem> invalidVerificationToken() {
        return problem(
                HttpStatus.BAD_REQUEST,
                "Enlace no válido",
                "El enlace de verificación venció o ya fue utilizado. Solicita un nuevo registro.");
    }

    @ExceptionHandler(RegistrationDisabledException.class)
    public ResponseEntity<AuthDtos.ApiProblem> registrationDisabled() {
        return problem(
                HttpStatus.SERVICE_UNAVAILABLE,
                "Registro no disponible",
                "El registro no está habilitado en este entorno.");
    }

    @ExceptionHandler(RegistrationEmailDeliveryException.class)
    public ResponseEntity<AuthDtos.ApiProblem> registrationEmailUnavailable() {
        return problem(
                HttpStatus.SERVICE_UNAVAILABLE,
                "Servicio de correo no disponible",
                "No se pudo enviar el correo de verificación. Inténtalo de nuevo más tarde.");
    }

    @ExceptionHandler(HttpMessageNotReadableException.class)
    public ResponseEntity<AuthDtos.ApiProblem> unreadableRequest() {
        return problem(
                HttpStatus.BAD_REQUEST,
                "Solicitud no válida",
                "La solicitud no tiene un formato válido.");
    }

    @ExceptionHandler(LoginRateLimitExceededException.class)
    public ResponseEntity<AuthDtos.ApiProblem> loginRateLimited(
            LoginRateLimitExceededException exception) {
        return ResponseEntity.status(HttpStatus.TOO_MANY_REQUESTS)
                .header(HttpHeaders.RETRY_AFTER, Long.toString(exception.getRetryAfterSeconds()))
                .body(new AuthDtos.ApiProblem(
                        "Demasiados intentos",
                        HttpStatus.TOO_MANY_REQUESTS.value(),
                        "Espera antes de volver a intentar iniciar sesión."));
    }

    private static ResponseEntity<AuthDtos.ApiProblem> problem(
            HttpStatus status, String title, String detail) {
        return ResponseEntity.status(status)
                .body(new AuthDtos.ApiProblem(title, status.value(), detail));
    }
}
