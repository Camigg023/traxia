package com.traxia.identity.application;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.context.annotation.Profile;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;

@Component
@Profile("admin-bootstrap")
public class AdminBootstrapRunner implements ApplicationRunner {

    private static final Logger logger = LoggerFactory.getLogger(AdminBootstrapRunner.class);

    private final AdminBootstrapService adminBootstrapService;
    private final String email;
    private final String password;

    public AdminBootstrapRunner(
            AdminBootstrapService adminBootstrapService,
            @Value("${TRAXIA_BOOTSTRAP_ADMIN_EMAIL:}") String email,
            @Value("${TRAXIA_BOOTSTRAP_ADMIN_PASSWORD:}") String password) {
        this.adminBootstrapService = adminBootstrapService;
        this.email = email;
        this.password = password;
    }

    @Override
    public void run(ApplicationArguments arguments) {
        if (email.isBlank() || password.isBlank()) {
            throw new IllegalStateException(
                    "El aprovisionamiento requiere correo y contraseña configurados explícitamente.");
        }
        adminBootstrapService.provisionFirstAdministrator(email, password);
        logger.info("El aprovisionamiento inicial del administrador terminó correctamente.");
    }
}
