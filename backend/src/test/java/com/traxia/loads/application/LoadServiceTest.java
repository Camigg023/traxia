package com.traxia.loads.application;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import com.traxia.common.audit.AuditService;
import com.traxia.identity.domain.UserEntity;
import com.traxia.identity.persistence.UserRepository;
import com.traxia.loads.api.LoadDtos.CreateLoadRequest;
import com.traxia.loads.api.LoadDtos.LoadResponse;
import com.traxia.loads.domain.LoadEntity;
import com.traxia.loads.persistence.LoadRepository;
import java.math.BigDecimal;
import java.time.Instant;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

class LoadServiceTest {

    private LoadRepository loadRepository;
    private UserRepository userRepository;
    private AuditService auditService;
    private LoadService loadService;

    @BeforeEach
    void setUp() {
        loadRepository = mock(LoadRepository.class);
        userRepository = mock(UserRepository.class);
        auditService = mock(AuditService.class);
        loadService = new LoadService(loadRepository, userRepository, auditService);
    }

    private UserEntity createActiveUser(String email, String name, String profile) {
        Instant now = Instant.now();
        UserEntity user = UserEntity.pendingRegistration(email, name, profile, now);
        user.verifyEmail(now);
        return user;
    }

    @Test
    void createsLoadSuccessfullyForActivePublisher() {
        UUID publisherPublicId = UUID.randomUUID();
        UserEntity publisher = createActiveUser("empresa@traxia.co", "Logística SAS", "SHIPPER");
        when(userRepository.findWithAuthenticationDataByPublicId(publisherPublicId))
                .thenReturn(Optional.of(publisher));

        when(loadRepository.save(any(LoadEntity.class))).thenAnswer(invocation -> invocation.getArgument(0));

        CreateLoadRequest request = new CreateLoadRequest(
                "Cundinamarca",
                "Bogotá",
                "Calle 100 # 15-20",
                Instant.now().plusSeconds(3600),
                "Antioquia",
                "Medellín",
                "Carrera 50 # 10-10",
                Instant.now().plusSeconds(86400),
                "Alimentos perecederos",
                new BigDecimal("5000.00"),
                new BigDecimal("25.50"),
                "Estibas",
                true,
                "Camión Sencillo",
                "Furgón refrigerado",
                "OFFERED",
                new BigDecimal("2500000.00"),
                "REMITTENT",
                "Entregar en muelle 3 con factura original."
        );

        LoadResponse response = loadService.createLoad(request, publisherPublicId);

        assertThat(response).isNotNull();
        assertThat(response.originCity()).isEqualTo("Bogotá");
        assertThat(response.destinationCity()).isEqualTo("Medellín");
        assertThat(response.productType()).isEqualTo("Alimentos perecederos");
        assertThat(response.weightKg()).isEqualByComparingTo("5000.00");
        assertThat(response.requiresRefrigeration()).isTrue();
        assertThat(response.status()).isEqualTo("PUBLISHED");
        verify(auditService).record(any(UserEntity.class), any(), any(), any(), any());
    }

    @Test
    void rejectsLoadCreationWhenPublisherIsNotActive() {
        UUID publisherPublicId = UUID.randomUUID();
        UserEntity publisher = UserEntity.pendingRegistration("inactivo@traxia.co", "Prueba", "SHIPPER", Instant.now());
        when(userRepository.findWithAuthenticationDataByPublicId(publisherPublicId))
                .thenReturn(Optional.of(publisher));

        CreateLoadRequest request = new CreateLoadRequest(
                "Cundinamarca", "Bogotá", null, Instant.now(),
                "Antioquia", "Medellín", null, Instant.now().plusSeconds(3600),
                "Cajas", new BigDecimal("100"), null, null, false,
                "Turbo", "Estacas", "OFFERED", null, "REMITTENT", null
        );

        assertThatThrownBy(() -> loadService.createLoad(request, publisherPublicId))
                .isInstanceOf(IllegalStateException.class)
                .hasMessageContaining("debe estar activa");
    }

    @Test
    void searchesAvailableLoadsUsingFilters() {
        LoadEntity load = LoadEntity.create(
                createActiveUser("test@traxia.co", "Test", "SHIPPER"),
                "Cundinamarca", "Bogotá", null, Instant.now(),
                "Valle del Cauca", "Cali", null, Instant.now().plusSeconds(7200),
                "Textiles", new BigDecimal("3000"), null, null, false,
                "Turbo", "Furgón", "OFFERED", new BigDecimal("1800000"), "REMITTENT", null,
                Instant.now()
        );

        when(loadRepository.searchAvailableLoads("Bogotá", "Cali", "Turbo"))
                .thenReturn(List.of(load));

        List<LoadResponse> results = loadService.searchLoads("Bogotá", "Cali", "Turbo");

        assertThat(results).hasSize(1);
        assertThat(results.get(0).originCity()).isEqualTo("Bogotá");
        assertThat(results.get(0).destinationCity()).isEqualTo("Cali");
    }
}
