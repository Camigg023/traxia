CREATE TABLE users (
    id BIGINT NOT NULL AUTO_INCREMENT,
    public_id BINARY(16) NOT NULL,
    email_normalized VARCHAR(254) NOT NULL,
    phone_e164 VARCHAR(32) NULL,
    status VARCHAR(32) NOT NULL,
    email_verified_at_utc DATETIME(6) NULL,
    version BIGINT NOT NULL DEFAULT 0,
    created_at_utc DATETIME(6) NOT NULL,
    updated_at_utc DATETIME(6) NOT NULL,
    PRIMARY KEY (id),
    CONSTRAINT uk_users_public_id UNIQUE (public_id),
    CONSTRAINT uk_users_email_normalized UNIQUE (email_normalized)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE roles (
    id BIGINT NOT NULL AUTO_INCREMENT,
    code VARCHAR(32) NOT NULL,
    name_es VARCHAR(100) NOT NULL,
    description VARCHAR(255) NULL,
    PRIMARY KEY (id),
    CONSTRAINT uk_roles_code UNIQUE (code)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE permissions (
    id BIGINT NOT NULL AUTO_INCREMENT,
    code VARCHAR(64) NOT NULL,
    description VARCHAR(255) NULL,
    PRIMARY KEY (id),
    CONSTRAINT uk_permissions_code UNIQUE (code)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE user_roles (
    id BIGINT NOT NULL AUTO_INCREMENT,
    user_id BIGINT NOT NULL,
    role_id BIGINT NOT NULL,
    assigned_at_utc DATETIME(6) NOT NULL,
    revoked_at_utc DATETIME(6) NULL,
    PRIMARY KEY (id),
    CONSTRAINT fk_user_roles_user FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE RESTRICT,
    CONSTRAINT fk_user_roles_role FOREIGN KEY (role_id) REFERENCES roles (id) ON DELETE RESTRICT,
    CONSTRAINT uk_user_roles_assignment UNIQUE (user_id, role_id),
    INDEX ix_user_roles_user_active (user_id, revoked_at_utc, role_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE role_permissions (
    role_id BIGINT NOT NULL,
    permission_id BIGINT NOT NULL,
    PRIMARY KEY (role_id, permission_id),
    CONSTRAINT fk_role_permissions_role FOREIGN KEY (role_id) REFERENCES roles (id) ON DELETE RESTRICT,
    CONSTRAINT fk_role_permissions_permission FOREIGN KEY (permission_id) REFERENCES permissions (id) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE auth_methods (
    id BIGINT NOT NULL AUTO_INCREMENT,
    public_id BINARY(16) NOT NULL,
    user_id BIGINT NOT NULL,
    provider_code VARCHAR(32) NOT NULL,
    provider_subject VARCHAR(255) NULL,
    credential_hash VARCHAR(255) NULL,
    status VARCHAR(32) NOT NULL,
    verified_at_utc DATETIME(6) NULL,
    created_at_utc DATETIME(6) NOT NULL,
    PRIMARY KEY (id),
    CONSTRAINT uk_auth_methods_public_id UNIQUE (public_id),
    CONSTRAINT uk_auth_provider_subject UNIQUE (provider_code, provider_subject),
    CONSTRAINT fk_auth_methods_user FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE RESTRICT,
    INDEX ix_auth_methods_user_provider (user_id, provider_code, status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE refresh_sessions (
    id BIGINT NOT NULL AUTO_INCREMENT,
    public_id BINARY(16) NOT NULL,
    family_id BINARY(16) NOT NULL,
    user_id BIGINT NOT NULL,
    token_hash CHAR(64) CHARACTER SET ascii COLLATE ascii_bin NOT NULL,
    created_at_utc DATETIME(6) NOT NULL,
    expires_at_utc DATETIME(6) NOT NULL,
    revoked_at_utc DATETIME(6) NULL,
    replaced_by_id BIGINT NULL,
    PRIMARY KEY (id),
    CONSTRAINT uk_refresh_sessions_public_id UNIQUE (public_id),
    CONSTRAINT uk_refresh_sessions_token_hash UNIQUE (token_hash),
    CONSTRAINT fk_refresh_sessions_user FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE RESTRICT,
    CONSTRAINT fk_refresh_sessions_replaced_by FOREIGN KEY (replaced_by_id) REFERENCES refresh_sessions (id) ON DELETE RESTRICT,
    INDEX ix_refresh_sessions_family (family_id, revoked_at_utc),
    INDEX ix_refresh_sessions_user_expiry (user_id, expires_at_utc)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE audit_events (
    id BIGINT NOT NULL AUTO_INCREMENT,
    actor_user_id BIGINT NULL,
    action_code VARCHAR(64) NOT NULL,
    entity_type VARCHAR(64) NULL,
    entity_public_id BINARY(16) NULL,
    outcome VARCHAR(32) NOT NULL,
    correlation_id VARCHAR(64) NULL,
    occurred_at_utc DATETIME(6) NOT NULL,
    PRIMARY KEY (id),
    CONSTRAINT fk_audit_events_actor FOREIGN KEY (actor_user_id) REFERENCES users (id) ON DELETE RESTRICT,
    INDEX ix_audit_events_actor_time (actor_user_id, occurred_at_utc),
    INDEX ix_audit_events_entity_time (entity_type, entity_public_id, occurred_at_utc),
    INDEX ix_audit_events_correlation (correlation_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

INSERT INTO roles (code, name_es, description) VALUES
    ('SHIPPER', 'Empresa generadora de carga', 'Publica cargas y gestiona viajes'),
    ('DRIVER', 'Conductor', 'Consulta cargas y gestiona viajes asignados'),
    ('CARRIER', 'Empresa transportadora', 'Gestiona flotas, conductores y viajes'),
    ('ADMIN', 'Administrador', 'Acceso administrativo autorizado');
