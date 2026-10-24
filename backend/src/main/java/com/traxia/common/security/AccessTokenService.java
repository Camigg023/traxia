package com.traxia.common.security;

import java.time.Instant;
import java.util.List;
import java.util.UUID;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.oauth2.jose.jws.MacAlgorithm;
import org.springframework.security.oauth2.jwt.JwtClaimsSet;
import org.springframework.security.oauth2.jwt.JwtEncoder;
import org.springframework.security.oauth2.jwt.JwtEncoderParameters;
import org.springframework.security.oauth2.jwt.JwsHeader;
import org.springframework.stereotype.Service;

@Service
public class AccessTokenService {

    private final JwtEncoder jwtEncoder;
    private final String issuer;
    private final String audience;
    private final long lifetimeSeconds;

    public AccessTokenService(
            JwtEncoder jwtEncoder,
            @Value("${traxia.security.jwt.issuer}") String issuer,
            @Value("${traxia.security.jwt.audience}") String audience,
            @Value("${traxia.security.jwt.access-ttl-seconds}") long lifetimeSeconds) {
        if (lifetimeSeconds < 60 || lifetimeSeconds > 600) {
            throw new IllegalArgumentException("La vigencia del token de acceso debe estar entre 60 y 600 segundos.");
        }
        this.jwtEncoder = jwtEncoder;
        this.issuer = issuer;
        this.audience = audience;
        this.lifetimeSeconds = lifetimeSeconds;
    }

    public IssuedAccessToken issue(UUID userPublicId, List<String> roles) {
        return issue(userPublicId, null, roles);
    }

    public IssuedAccessToken issue(UUID userPublicId, String email, List<String> roles) {
        Instant issuedAt = Instant.now();
        Instant expiresAt = issuedAt.plusSeconds(lifetimeSeconds);
        JwtClaimsSet.Builder claimsBuilder = JwtClaimsSet.builder()
                .issuer(issuer)
                .audience(List.of(audience))
                .subject(userPublicId.toString())
                .issuedAt(issuedAt)
                .expiresAt(expiresAt)
                .id(UUID.randomUUID().toString())
                .claim("roles", List.copyOf(roles));
        if (email != null && !email.isBlank()) {
            claimsBuilder.claim("email", email);
        }
        JwtClaimsSet claims = claimsBuilder.build();

        String token = jwtEncoder.encode(JwtEncoderParameters.from(
                JwsHeader.with(MacAlgorithm.HS256).build(), claims)).getTokenValue();
        return new IssuedAccessToken(token, lifetimeSeconds);
    }

    public record IssuedAccessToken(String value, long expiresInSeconds) {
    }
}
