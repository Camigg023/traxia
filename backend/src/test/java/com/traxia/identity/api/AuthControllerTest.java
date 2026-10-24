package com.traxia.identity.api;

import static org.assertj.core.api.Assertions.assertThatCode;
import static org.assertj.core.api.Assertions.assertThatIllegalStateException;
import static org.mockito.Mockito.mock;

import com.traxia.identity.application.AuthService;
import com.traxia.identity.application.RegistrationService;
import org.junit.jupiter.api.Test;

class AuthControllerTest {

    @Test
    void rejectsInsecureRefreshCookieOutsideLocalAndTestEnvironments() {
        assertThatIllegalStateException().isThrownBy(() ->
                new AuthController(
                        null, null,
                        "TRAXIA_REFRESH",
                        false,
                        "production"))
                .withMessageContaining("debe usar Secure");
    }

    @Test
    void permitsInsecureRefreshCookieInLocalDevelopment() {
        assertThatCode(() ->
                new AuthController(
                        null, null,
                        "TRAXIA_REFRESH",
                        false,
                        "local"))
                .doesNotThrowAnyException();
    }
}
