package com.traxia.identity.application;

import static org.assertj.core.api.Assertions.assertThat;

import java.util.List;
import java.util.UUID;
import org.junit.jupiter.api.Test;

class TraxiaUserDetailsTest {

    @Test
    void mapsProvidedRolesToAuthorities() {
        TraxiaUserDetails details = new TraxiaUserDetails(
                10L,
                UUID.randomUUID(),
                "driver@example.test",
                "$2a$12$hash",
                true,
                List.of("ADMIN"));

        assertThat(details.getAuthorities().stream()
                        .map(authority -> authority.getAuthority())
                        .toList())
                .containsExactly("ROLE_ADMIN");
        assertThat(details.isEnabled()).isTrue();
        assertThat(details.getUsername()).isEqualTo("driver@example.test");
    }
}
