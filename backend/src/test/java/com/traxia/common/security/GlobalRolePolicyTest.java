package com.traxia.common.security;

import static org.assertj.core.api.Assertions.assertThat;

import java.time.Instant;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import org.junit.jupiter.api.Test;
import org.springframework.security.oauth2.jwt.Jwt;

class GlobalRolePolicyTest {

    @Test
    void filtersLegacyBusinessRolesFromJwtAuthorities() {
        Jwt jwt = new Jwt(
                "token",
                Instant.now(),
                Instant.now().plusSeconds(60),
                Map.of("alg", "none"),
                Map.of(
                        "sub", UUID.randomUUID().toString(),
                        "roles", List.of("DRIVER", "CARRIER", "ADMIN", "ADMIN")));

        var authentication = new SecurityConfiguration()
                .jwtAuthenticationConverter()
                .convert(jwt);

        assertThat(authentication.getAuthorities())
                .extracting("authority")
                .containsExactly("ROLE_ADMIN");
    }

    @Test
    void omitsBusinessRoleCodesWhenNoGlobalAdministratorRoleExists() {
        assertThat(GlobalRolePolicy.filter(List.of("SHIPPER", "DRIVER", "CARRIER")))
                .isEmpty();
    }
}
