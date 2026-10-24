package com.traxia.identity.application;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import com.traxia.identity.domain.RefreshSessionEntity;
import com.traxia.identity.domain.UserEntity;
import com.traxia.identity.persistence.RefreshSessionRepository;
import com.traxia.identity.persistence.UserRepository;
import java.time.Instant;
import java.util.Optional;
import java.util.UUID;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;

class RefreshSessionServiceTest {

    @Test
    void persistsOnlyHashOfRefreshToken() {
        RefreshSessionRepository sessions = mock(RefreshSessionRepository.class);
        UserRepository users = mock(UserRepository.class);
        UserEntity user = mock(UserEntity.class);
        when(user.getId()).thenReturn(42L);
        when(users.findById(42L)).thenReturn(Optional.of(user));
        RefreshSessionService service = new RefreshSessionService(sessions, users, 604_800);

        RefreshSessionService.IssuedRefreshToken issued = service.issue(42L);

        ArgumentCaptor<RefreshSessionEntity> saved = ArgumentCaptor.forClass(RefreshSessionEntity.class);
        verify(sessions).save(saved.capture());
        assertThat(issued.value()).isNotBlank();
        assertThat(saved.getValue().getTokenHash())
                .isEqualTo(RefreshSessionService.hashToken(issued.value()))
                .isNotEqualTo(issued.value());
        assertThat(issued.expiresInSeconds()).isEqualTo(604_800);
    }

    @Test
    void reuseOfRevokedTokenRevokesItsWholeFamily() {
        RefreshSessionRepository sessions = mock(RefreshSessionRepository.class);
        UserRepository users = mock(UserRepository.class);
        RefreshSessionEntity revokedSession = mock(RefreshSessionEntity.class);
        UUID familyId = UUID.randomUUID();
        when(revokedSession.getRevokedAtUtc()).thenReturn(Instant.now());
        when(revokedSession.getFamilyId()).thenReturn(familyId);
        when(sessions.findByTokenHashForUpdate(any())).thenReturn(Optional.of(revokedSession));
        RefreshSessionService service = new RefreshSessionService(sessions, users, 604_800);

        RefreshSessionService.RotationResult result = service.rotate("replayed-token");

        assertThat(result.successful()).isFalse();
        assertThat(result.failure()).isEqualTo(RefreshSessionService.RotationFailure.REUSE_DETECTED);
        verify(sessions).revokeFamily(eq(familyId), any(Instant.class));
        verify(sessions, never()).saveAndFlush(any());
    }

    @Test
    void rejectsTokenNotFoundInSessionStore() {
        RefreshSessionRepository sessions = mock(RefreshSessionRepository.class);
        UserRepository users = mock(UserRepository.class);
        when(sessions.findByTokenHashForUpdate(any())).thenReturn(Optional.empty());
        RefreshSessionService service = new RefreshSessionService(sessions, users, 604_800);

        RefreshSessionService.RotationResult result = service.rotate("unknown-token");

        assertThat(result.successful()).isFalse();
        assertThat(result.failure()).isEqualTo(RefreshSessionService.RotationFailure.NOT_FOUND);
        verify(sessions, never()).saveAndFlush(any());
    }
}
