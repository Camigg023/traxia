package com.traxia.identity.domain;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;
import java.time.Instant;

@Entity
@Table(name = "registration_notice_acceptances")
public class RegistrationNoticeAcceptanceEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "user_id", nullable = false)
    private UserEntity user;

    @Column(name = "notice_version", nullable = false, length = 64)
    private String noticeVersion;

    @Column(name = "accepted_at_utc", nullable = false)
    private Instant acceptedAtUtc;

    protected RegistrationNoticeAcceptanceEntity() {
    }

    public RegistrationNoticeAcceptanceEntity(
            UserEntity user, String noticeVersion, Instant acceptedAtUtc) {
        this.user = user;
        this.noticeVersion = noticeVersion;
        this.acceptedAtUtc = acceptedAtUtc;
    }
}
