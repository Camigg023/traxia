package com.traxia.common.security;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatIllegalArgumentException;

import java.util.Base64;
import java.util.List;
import java.util.UUID;
import javax.crypto.SecretKey;
import org.junit.jupiter.api.Test;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.security.oauth2.jwt.JwtDecoder;
import org.springframework.security.oauth2.jwt.JwtEncoder;

class AccessTokenServiceTest {

    @Test
    void rejectsAccessTokenLifetimeAboveApprovedTenMinutes() {
        assertThatIllegalArgumentException().isThrownBy(() ->
                new AccessTokenService(null, "traxia-test", "traxia-web-test", 601))
                .withMessageContaining("60 y 600");
    }

    @Test
    void issuesSignedTokenWithExpectedIdentityAndClaims() {
        String encodedKey = Base64.getEncoder().encodeToString(new byte[32]);
        JwtConfiguration configuration = new JwtConfiguration();
        SecretKey key = configuration.jwtSecretKey(encodedKey);
        JwtEncoder encoder = configuration.jwtEncoder(key);
        JwtDecoder decoder = configuration.jwtDecoder(key, "traxia-test", "traxia-web-test");
        AccessTokenService service = new AccessTokenService(
                encoder, "traxia-test", "traxia-web-test", 600);
        UUID userId = UUID.randomUUID();

        AccessTokenService.IssuedAccessToken issued =
                service.issue(userId, "user@example.test", List.of("DRIVER"));
        Jwt decoded = decoder.decode(issued.value());

        assertThat(issued.expiresInSeconds()).isEqualTo(600);
        assertThat(decoded.getSubject()).isEqualTo(userId.toString());
        assertThat(decoded.getClaimAsString("iss")).isEqualTo("traxia-test");
        assertThat(decoded.getAudience()).containsExactly("traxia-web-test");
        assertThat(decoded.getClaimAsString("email")).isEqualTo("user@example.test");
        assertThat(decoded.getClaimAsStringList("roles")).containsExactly("DRIVER");
    }
}
