ALTER TABLE users
    ADD COLUMN display_name VARCHAR(120) NULL,
    ADD COLUMN registration_profile_code VARCHAR(32) NULL;

CREATE TABLE registration_notice_acceptances (
    id BIGINT NOT NULL AUTO_INCREMENT,
    user_id BIGINT NOT NULL,
    notice_version VARCHAR(64) NOT NULL,
    accepted_at_utc DATETIME(6) NOT NULL,
    PRIMARY KEY (id),
    CONSTRAINT fk_registration_notice_acceptances_user
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE RESTRICT,
    CONSTRAINT uk_registration_notice_acceptances_user_version
        UNIQUE (user_id, notice_version)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE email_verification_tokens (
    id BIGINT NOT NULL AUTO_INCREMENT,
    public_id BINARY(16) NOT NULL,
    user_id BIGINT NOT NULL,
    token_hash CHAR(64) CHARACTER SET ascii COLLATE ascii_bin NOT NULL,
    expires_at_utc DATETIME(6) NOT NULL,
    consumed_at_utc DATETIME(6) NULL,
    created_at_utc DATETIME(6) NOT NULL,
    PRIMARY KEY (id),
    CONSTRAINT uk_email_verification_tokens_public_id UNIQUE (public_id),
    CONSTRAINT uk_email_verification_tokens_token_hash UNIQUE (token_hash),
    CONSTRAINT fk_email_verification_tokens_user
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE RESTRICT,
    INDEX ix_email_verification_tokens_user_expiry (user_id, expires_at_utc)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
