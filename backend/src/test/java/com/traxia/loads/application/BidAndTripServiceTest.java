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
import com.traxia.loads.api.BidDtos.BidResponse;
import com.traxia.loads.api.BidDtos.CreateBidRequest;
import com.traxia.loads.api.BidDtos.DeliverTripRequest;
import com.traxia.loads.api.BidDtos.TripResponse;
import com.traxia.loads.application.SimulationService.RouteSimulationResponse;
import com.traxia.loads.domain.BidEntity;
import com.traxia.loads.domain.LoadEntity;
import com.traxia.loads.domain.TripEntity;
import com.traxia.loads.persistence.BidRepository;
import com.traxia.loads.persistence.LoadRepository;
import com.traxia.loads.persistence.TripRepository;
import java.math.BigDecimal;
import java.time.Instant;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

class BidAndTripServiceTest {

    private BidRepository bidRepository;
    private TripRepository tripRepository;
    private LoadRepository loadRepository;
    private UserRepository userRepository;
    private AuditService auditService;
    private BidAndTripService service;
    private SimulationService simulationService;

    @BeforeEach
    void setUp() {
        bidRepository = mock(BidRepository.class);
        tripRepository = mock(TripRepository.class);
        loadRepository = mock(LoadRepository.class);
        userRepository = mock(UserRepository.class);
        auditService = mock(AuditService.class);
        service = new BidAndTripService(bidRepository, tripRepository, loadRepository, userRepository, auditService);
        simulationService = new SimulationService();
    }

    private UserEntity createActiveUser(String email, String name, String profile) {
        Instant now = Instant.now();
        UserEntity user = UserEntity.pendingRegistration(email, name, profile, now);
        user.verifyEmail(now);
        return user;
    }

    private LoadEntity createSampleLoad(UserEntity publisher) {
        return LoadEntity.create(
                publisher,
                "Cundinamarca", "Bogotá", "Cll 100", Instant.now(),
                "Antioquia", "Medellín", "Cra 50", Instant.now().plusSeconds(86400),
                "Mercancía general", new BigDecimal("4500"), new BigDecimal("18"), "Cajas",
                false, "Camión Sencillo", "Furgón", "OFFERED", new BigDecimal("2800000"),
                "REMITTENT", "Cuidado con la carga", Instant.now()
        );
    }

    @Test
    void createsBidSuccessfullyForActiveBidder() {
        UUID loadPublicId = UUID.randomUUID();
        UUID bidderPublicId = UUID.randomUUID();
        UserEntity publisher = createActiveUser("empresa@traxia.co", "Empresa A", "SHIPPER");
        UserEntity bidder = createActiveUser("conductor@traxia.co", "Conductor B", "DRIVER");
        LoadEntity load = createSampleLoad(publisher);

        when(loadRepository.findByPublicId(loadPublicId)).thenReturn(Optional.of(load));
        when(userRepository.findWithAuthenticationDataByPublicId(bidderPublicId)).thenReturn(Optional.of(bidder));
        when(bidRepository.save(any(BidEntity.class))).thenAnswer(inv -> inv.getArgument(0));

        CreateBidRequest req = new CreateBidRequest(
                new BigDecimal("2700000.00"),
                Instant.now().plusSeconds(3600),
                "Listo para cargar a las 8:00 AM"
        );

        BidResponse response = service.createBid(loadPublicId, req, bidderPublicId);

        assertThat(response).isNotNull();
        assertThat(response.offeredAmount()).isEqualByComparingTo("2700000.00");
        assertThat(response.status()).isEqualTo("PENDING");
        verify(auditService).record(any(UserEntity.class), any(), any(), any(), any());
    }

    @Test
    void acceptsBidAssignsLoadAndCreatesTrip() {
        UUID bidPublicId = UUID.randomUUID();
        UUID publisherPublicId = UUID.randomUUID();
        UserEntity publisher = createActiveUser("empresa@traxia.co", "Empresa A", "SHIPPER");
        UserEntity bidder = createActiveUser("conductor@traxia.co", "Conductor B", "DRIVER");
        LoadEntity load = createSampleLoad(publisher);
        BidEntity bid = BidEntity.create(load, bidder, new BigDecimal("2700000"), Instant.now(), "Oferta 1", Instant.now());

        when(bidRepository.findByPublicId(bidPublicId)).thenReturn(Optional.of(bid));
        when(userRepository.findWithAuthenticationDataByPublicId(publisherPublicId)).thenReturn(Optional.of(publisher));
        when(tripRepository.save(any(TripEntity.class))).thenAnswer(inv -> inv.getArgument(0));
        when(bidRepository.findByLoad_PublicIdOrderByCreatedAtUtcDesc(any())).thenReturn(List.of(bid));

        TripResponse trip = service.acceptBid(bidPublicId, publisherPublicId);

        assertThat(trip).isNotNull();
        assertThat(trip.status()).isEqualTo("ASSIGNED");
        assertThat(trip.agreedAmount()).isEqualByComparingTo("2700000");
        assertThat(load.getStatus()).isEqualTo("ASSIGNED");
        assertThat(bid.getStatus()).isEqualTo("ACCEPTED");
    }

    @Test
    void startsAndDeliversTripSuccessfully() {
        UUID tripPublicId = UUID.randomUUID();
        UUID driverPublicId = UUID.randomUUID();
        UserEntity publisher = createActiveUser("empresa@traxia.co", "Empresa A", "SHIPPER");
        UserEntity driver = createActiveUser("conductor@traxia.co", "Conductor B", "DRIVER");
        LoadEntity load = createSampleLoad(publisher);
        BidEntity bid = BidEntity.create(load, driver, new BigDecimal("2700000"), Instant.now(), "Oferta", Instant.now());
        TripEntity trip = TripEntity.createFromBid(load, bid, Instant.now());

        when(tripRepository.findByPublicId(tripPublicId)).thenReturn(Optional.of(trip));
        when(userRepository.findWithAuthenticationDataByPublicId(driverPublicId)).thenReturn(Optional.of(driver));

        TripResponse inTransit = service.startTrip(tripPublicId, driverPublicId);
        assertThat(inTransit.status()).isEqualTo("IN_TRANSIT");
        assertThat(load.getStatus()).isEqualTo("IN_TRANSIT");

        TripResponse delivered = service.deliverTrip(tripPublicId, new DeliverTripRequest("Firmado en muelle."), driverPublicId);
        assertThat(delivered.status()).isEqualTo("DELIVERED");
        assertThat(delivered.deliveryProofNotes()).isEqualTo("Firmado en muelle.");
        assertThat(load.getStatus()).isEqualTo("DELIVERED");
    }

    @Test
    void simulationCalculatesBogotaMedellinRouteConsistently() {
        UserEntity publisher = createActiveUser("empresa@traxia.co", "Empresa A", "SHIPPER");
        LoadEntity load = createSampleLoad(publisher);

        RouteSimulationResponse sim = simulationService.simulate(load);

        assertThat(sim.estimatedDistanceKm()).isEqualTo(420);
        assertThat(sim.estimatedTollsCount()).isGreaterThanOrEqualTo(5);
        assertThat(sim.estimatedFuelCostCop()).isPositive();
        assertThat(sim.suggestedBaseFreightCop()).isGreaterThan(sim.estimatedDirectCostCop());
        assertThat(sim.disclaimer()).isNotBlank();
    }
}
