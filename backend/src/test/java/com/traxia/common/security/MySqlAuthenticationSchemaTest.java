package com.traxia.common.security;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.hamcrest.Matchers.allOf;
import static org.hamcrest.Matchers.containsString;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.header;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.traxia.common.security.LoginAttemptLimiter;
import com.traxia.identity.application.AdminBootstrapService;
import java.util.Base64;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import org.springframework.test.web.servlet.MockMvc;
import org.testcontainers.containers.MySQLContainer;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;

@Testcontainers(disabledWithoutDocker = true)
@SpringBootTest
@AutoConfigureMockMvc
class MySqlAuthenticationSchemaTest {

    @Container
    private static final MySQLContainer<?> MYSQL =
            new MySQLContainer<>("mysql:8.4")
                    .withDatabaseName("traxia_test")
                    .withUsername("traxia_test")
                    .withPassword("traxia_test");

    @Autowired
    private JdbcTemplate jdbcTemplate;

    @Autowired
    private LoginAttemptLimiter loginAttemptLimiter;

    @Autowired
    private AdminBootstrapService adminBootstrapService;

    @Autowired
    private MockMvc mockMvc;

    @DynamicPropertySource
    static void configureMysql(DynamicPropertyRegistry registry) {
        registry.add("spring.datasource.url", MYSQL::getJdbcUrl);
        registry.add("spring.datasource.username", MYSQL::getUsername);
        registry.add("spring.datasource.password", MYSQL::getPassword);
        registry.add("traxia.security.jwt.secret-base64",
                () -> Base64.getEncoder().encodeToString(new byte[32]));
        registry.add("traxia.security.login-limit.hashing-secret-base64",
                () -> Base64.getEncoder().encodeToString(new byte[32]));
        registry.add("traxia.web.allowed-origins", () -> "http://localhost:5000");
        registry.add("APP_ENV", () -> "test");
    }

    @Test
    void appliesIdentityMigrationAndCreatesExpectedMysqlTypes() {
        Integer roleCount = jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM roles WHERE code IN ('SHIPPER', 'DRIVER', 'CARRIER', 'ADMIN')",
                Integer.class);
        String tokenHashType = jdbcTemplate.queryForObject(
                """
                        SELECT COLUMN_TYPE FROM information_schema.columns
                        WHERE table_schema = DATABASE()
                          AND table_name = 'refresh_sessions'
                          AND column_name = 'token_hash'
                        """,
                String.class);
        String bucketHashType = jdbcTemplate.queryForObject(
                """
                        SELECT COLUMN_TYPE FROM information_schema.columns
                        WHERE table_schema = DATABASE()
                          AND table_name = 'auth_attempt_limits'
                          AND column_name = 'bucket_hash'
                        """,
                String.class);
        Integer noticeAcceptanceTables = jdbcTemplate.queryForObject(
                        """
                                SELECT COUNT(*) FROM information_schema.tables
                                WHERE table_schema = DATABASE()
                                  AND table_name = 'registration_notice_acceptances'
                                """,
                        Integer.class);
        Integer verificationTokenTables = jdbcTemplate.queryForObject(
                        """
                                SELECT COUNT(*) FROM information_schema.tables
                                WHERE table_schema = DATABASE()
                                  AND table_name = 'email_verification_tokens'
                                """,
                        Integer.class);
        String registrationProfileType = jdbcTemplate.queryForObject(
                        """
                                SELECT COLUMN_TYPE FROM information_schema.columns
                                WHERE table_schema = DATABASE()
                                  AND table_name = 'users'
                                  AND column_name = 'registration_profile_code'
                                """,
                        String.class);

        assertThat(roleCount).isEqualTo(4);
        assertThat(tokenHashType).isEqualTo("char(64)");
        assertThat(bucketHashType).isEqualTo("binary(32)");
        assertThat(noticeAcceptanceTables).isEqualTo(1);
        assertThat(verificationTokenTables).isEqualTo(1);
        assertThat(registrationProfileType).isEqualTo("varchar(32)");
    }

    @Test
    void persistsFailureBucketsAndBlocksAfterConfiguredAccountThreshold() {
        for (int attempt = 0; attempt < 5; attempt++) {
            loginAttemptLimiter.recordFailure("limited-user@example.test", "192.0.2.44");
        }

        assertThatThrownBy(() ->
                loginAttemptLimiter.assertAllowed("limited-user@example.test", "192.0.2.44"))
                .isInstanceOf(LoginAttemptLimiter.LoginRateLimitExceededException.class)
                .hasMessageContaining("límite");
    }

    @Test
    void clearsAccountBucketAfterSuccessfulAuthentication() {
        for (int attempt = 0; attempt < 4; attempt++) {
            loginAttemptLimiter.recordFailure("recovered-user@example.test", "192.0.2.45");
        }
        loginAttemptLimiter.clearAccountFailures("recovered-user@example.test");
        for (int attempt = 0; attempt < 4; attempt++) {
            loginAttemptLimiter.recordFailure("recovered-user@example.test", "192.0.2.46");
        }
        loginAttemptLimiter.assertAllowed("recovered-user@example.test", "192.0.2.46");
    }

    @Test
    void returns429AfterFiveFailedHttpLoginsAndPersistsTheLimit() throws Exception {
        for (int attempt = 0; attempt < 5; attempt++) {
            mockMvc.perform(post("/api/v1/auth/login")
                            .with(request -> {
                                request.setRemoteAddr("203.0.113.44");
                                return request;
                            })
                            .contentType("application/json")
                            .content("""
                                    {"email":"limit-check@example.test",
                                     "password":"wrong-password"}
                                    """))
                    .andExpect(status().isUnauthorized());
        }

        mockMvc.perform(post("/api/v1/auth/login")
                        .with(request -> {
                            request.setRemoteAddr("203.0.113.44");
                            return request;
                        })
                        .contentType("application/json")
                        .content("""
                                {"email":"limit-check@example.test",
                                 "password":"wrong-password"}
                                """))
                .andExpect(status().isTooManyRequests())
                .andExpect(header().exists("Retry-After"));
    }

    @Test
    void bootstrapsOneAdministratorAndIssuesWebSessionCookie() throws Exception {
        String email = "bootstrap-admin@example.test";
        String password = "TRAXIA-Admin-Password-2026!";
        adminBootstrapService.provisionFirstAdministrator(email, password);

        assertThatThrownBy(() ->
                adminBootstrapService.provisionFirstAdministrator(email, password))
                .isInstanceOf(IllegalStateException.class)
                .hasMessageContaining("Ya existe un administrador");

        mockMvc.perform(post("/api/v1/auth/login")
                        .header("Origin", "http://localhost:5000")
                        .with(request -> {
                            request.setRemoteAddr("198.51.100.26");
                            return request;
                        })
                        .contentType("application/json")
                        .content("""
                                {"email":"bootstrap-admin@example.test",
                                 "password":"TRAXIA-Admin-Password-2026!"}
                                """))
                .andExpect(status().isOk())
                .andExpect(header().string("Set-Cookie", allOf(
                        containsString("HttpOnly"),
                        containsString("SameSite=Strict"),
                        containsString("Path=/api/v1/auth"),
                        containsString("Max-Age="))))
                .andExpect(header().string("Access-Control-Allow-Origin", "http://localhost:5000"))
                .andExpect(header().string("Access-Control-Allow-Credentials", "true"));
    }
}
