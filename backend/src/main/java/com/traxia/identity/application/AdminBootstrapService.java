package com.traxia.identity.application;

import com.traxia.common.audit.AuditService;
import com.traxia.identity.api.AuthDtos.LoginRequest;
import com.traxia.identity.domain.AuthMethodEntity;
import com.traxia.identity.domain.RoleEntity;
import com.traxia.identity.domain.UserEntity;
import com.traxia.identity.domain.UserRoleEntity;
import com.traxia.identity.persistence.AuthMethodRepository;
import com.traxia.identity.persistence.RoleRepository;
import com.traxia.identity.persistence.UserRepository;
import com.traxia.identity.persistence.UserRoleRepository;
import jakarta.validation.Validator;
import java.nio.charset.StandardCharsets;
import java.time.Instant;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class AdminBootstrapService {

    private final RoleRepository roleRepository;
    private final UserRepository userRepository;
    private final AuthMethodRepository authMethodRepository;
    private final UserRoleRepository userRoleRepository;
    private final PasswordEncoder passwordEncoder;
    private final Validator validator;
    private final AuditService auditService;

    public AdminBootstrapService(
            RoleRepository roleRepository,
            UserRepository userRepository,
            AuthMethodRepository authMethodRepository,
            UserRoleRepository userRoleRepository,
            PasswordEncoder passwordEncoder,
            Validator validator,
            AuditService auditService) {
        this.roleRepository = roleRepository;
        this.userRepository = userRepository;
        this.authMethodRepository = authMethodRepository;
        this.userRoleRepository = userRoleRepository;
        this.passwordEncoder = passwordEncoder;
        this.validator = validator;
        this.auditService = auditService;
    }

    @Transactional
    public void provisionFirstAdministrator(String email, String password) {
        String normalizedEmail = TraxiaUserDetailsService.normalizeEmail(email);
        if (!validator.validate(new LoginRequest(normalizedEmail, password)).isEmpty()
                || password.codePointCount(0, password.length()) < 16) {
            throw new IllegalArgumentException(
                    "El correo o la contraseña no cumplen los requisitos de seguridad.");
        }
        if (password.getBytes(StandardCharsets.UTF_8).length > 72) {
            throw new IllegalArgumentException("La contraseña excede el límite de BCrypt.");
        }

        RoleEntity adminRole = roleRepository.findByCodeForUpdate("ADMIN")
                .orElseThrow(() -> new IllegalStateException(
                        "No existe el rol ADMIN; aplica primero las migraciones autorizadas."));
        if (userRepository.countActiveUsersWithRole("ADMIN") > 0) {
            throw new IllegalStateException(
                    "Ya existe un administrador activo; el aprovisionamiento inicial no se repetirá.");
        }
        if (userRepository.existsByEmailNormalized(normalizedEmail)) {
            throw new IllegalStateException("Ya existe una cuenta con ese correo.");
        }

        Instant now = Instant.now();
        UserEntity administrator = userRepository.save(
                UserEntity.bootstrapAdministrator(normalizedEmail, now));
        AuthMethodEntity authMethod = authMethodRepository.save(
                AuthMethodEntity.emailPassword(
                        administrator, passwordEncoder.encode(password), now));
        UserRoleEntity assignment = userRoleRepository.save(
                UserRoleEntity.assign(administrator, adminRole, now));
        administrator.getAuthMethods().add(authMethod);
        administrator.getUserRoles().add(assignment);
        auditService.record(
                administrator,
                "ADMIN_BOOTSTRAP",
                "USER",
                administrator.getPublicId(),
                "SUCCESS");
    }
}
