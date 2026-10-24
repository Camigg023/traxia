CREATE TABLE auth_attempt_limits (
    bucket_hash BINARY(32) NOT NULL,
    window_started_at_utc DATETIME(6) NOT NULL,
    failure_count INT UNSIGNED NOT NULL,
    blocked_until_utc DATETIME(6) NULL,
    updated_at_utc DATETIME(6) NOT NULL,
    PRIMARY KEY (bucket_hash),
    INDEX ix_auth_attempt_limits_window (window_started_at_utc),
    INDEX ix_auth_attempt_limits_blocked (blocked_until_utc)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
