package com.traxia.identity.api;

import static org.assertj.core.api.Assertions.assertThat;

import jakarta.validation.Validation;
import jakarta.validation.Validator;
import org.junit.jupiter.api.Test;

class AuthDtosTest {

    @Test
    void validatesBcryptUtf8ByteLimitRatherThanOnlyCharacterCount() {
        AuthDtos.LoginRequest request = new AuthDtos.LoginRequest(
                "user@example.test",
                "é".repeat(37));

        assertThat(request.password()).hasSize(37);
        assertThat(request.isPasswordWithinBcryptLimit()).isFalse();

        try (var validatorFactory = Validation.buildDefaultValidatorFactory()) {
            Validator validator = validatorFactory.getValidator();
            assertThat(validator.validate(request))
                    .anySatisfy(violation -> assertThat(violation.getPropertyPath().toString())
                            .isEqualTo("passwordWithinBcryptLimit"));
        }
    }

    @Test
    void rejectsRegistrationPasswordsOverBcryptByteLimit() {
        AuthDtos.RegisterRequest request = new AuthDtos.RegisterRequest(
                "Persona de prueba",
                "user@example.test",
                "á".repeat(37),
                "DRIVER",
                true);

        try (var validatorFactory = Validation.buildDefaultValidatorFactory()) {
            Validator validator = validatorFactory.getValidator();
            assertThat(validator.validate(request))
                    .anySatisfy(violation -> assertThat(violation.getPropertyPath().toString())
                            .isEqualTo("passwordWithinBcryptLimit"));
        }
    }

    @Test
    void rejectsRegistrationProfilesThatAreNotSupported() {
        AuthDtos.RegisterRequest request = new AuthDtos.RegisterRequest(
                "Persona de prueba",
                "user@example.test",
                "Una-clave-de-prueba-de-16",
                "ADMIN",
                true);

        try (var validatorFactory = Validation.buildDefaultValidatorFactory()) {
            Validator validator = validatorFactory.getValidator();
            assertThat(validator.validate(request))
                    .anySatisfy(violation -> assertThat(violation.getPropertyPath().toString())
                            .isEqualTo("profile"));
        }
    }
}
