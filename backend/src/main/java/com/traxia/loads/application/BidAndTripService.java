package com.traxia.loads.application;

import com.traxia.common.audit.AuditService;
import com.traxia.identity.domain.UserEntity;
import com.traxia.identity.persistence.UserRepository;
import com.traxia.loads.api.BidDtos.BidResponse;
import com.traxia.loads.api.BidDtos.CreateBidRequest;
import com.traxia.loads.api.BidDtos.DeliverTripRequest;
import com.traxia.loads.api.BidDtos.TripResponse;
import com.traxia.loads.domain.BidEntity;
import com.traxia.loads.domain.LoadEntity;
import com.traxia.loads.domain.TripEntity;
import com.traxia.loads.persistence.BidRepository;
import com.traxia.loads.persistence.LoadRepository;
import com.traxia.loads.persistence.TripRepository;
import java.time.Instant;
import java.util.List;
import java.util.NoSuchElementException;
import java.util.UUID;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class BidAndTripService {

    private final BidRepository bidRepository;
    private final TripRepository tripRepository;
    private final LoadRepository loadRepository;
    private final UserRepository userRepository;
    private final AuditService auditService;

    public BidAndTripService(
            BidRepository bidRepository,
            TripRepository tripRepository,
            LoadRepository loadRepository,
            UserRepository userRepository,
            AuditService auditService) {
        this.bidRepository = bidRepository;
        this.tripRepository = tripRepository;
        this.loadRepository = loadRepository;
        this.userRepository = userRepository;
        this.auditService = auditService;
    }

    @Transactional
    public BidResponse createBid(UUID loadPublicId, CreateBidRequest request, UUID bidderPublicId) {
        LoadEntity load = loadRepository.findByPublicId(loadPublicId)
                .orElseThrow(() -> new NoSuchElementException("Carga no encontrada."));

        if (!"PUBLISHED".equals(load.getStatus())) {
            throw new IllegalStateException("Solo se puede postular a cargas en estado PUBLICADA.");
        }

        UserEntity bidder = userRepository.findWithAuthenticationDataByPublicId(bidderPublicId)
                .orElseThrow(() -> new NoSuchElementException("Usuario postor no encontrado."));

        if (load.getPublisher().getPublicId().equals(bidder.getPublicId())) {
            throw new IllegalArgumentException("No puedes postularte a tu propia carga publicada.");
        }

        Instant now = Instant.now();
        BidEntity bid = BidEntity.create(
                load,
                bidder,
                request.offeredAmount(),
                request.proposedPickupDateUtc(),
                request.notes() != null ? request.notes().trim() : null,
                now
        );

        BidEntity saved = bidRepository.save(bid);
        auditService.record(bidder, "BID_SUBMITTED", "BID", saved.getPublicId(), "SUCCESS");

        return toBidResponse(saved);
    }

    @Transactional(readOnly = true)
    public List<BidResponse> getBidsForLoad(UUID loadPublicId, UUID userPublicId) {
        LoadEntity load = loadRepository.findByPublicId(loadPublicId)
                .orElseThrow(() -> new NoSuchElementException("Carga no encontrada."));

        UserEntity user = userRepository.findWithAuthenticationDataByPublicId(userPublicId)
                .orElseThrow(() -> new NoSuchElementException("Usuario no encontrado."));

        boolean isPublisher = load.getPublisher().getPublicId().equals(user.getPublicId());

        return bidRepository.findByLoad_PublicIdOrderByCreatedAtUtcDesc(load.getPublicId())
                .stream()
                .filter(b -> isPublisher || b.getBidder().getPublicId().equals(user.getPublicId()))
                .map(this::toBidResponse)
                .toList();
    }

    @Transactional(readOnly = true)
    public List<BidResponse> getMyBids(UUID bidderPublicId) {
        UserEntity bidder = userRepository.findWithAuthenticationDataByPublicId(bidderPublicId)
                .orElseThrow(() -> new NoSuchElementException("Usuario no encontrado."));

        return bidRepository.findByBidder_PublicIdOrderByCreatedAtUtcDesc(bidder.getPublicId())
                .stream()
                .map(this::toBidResponse)
                .toList();
    }

    @Transactional
    public TripResponse acceptBid(UUID bidPublicId, UUID publisherPublicId) {
        BidEntity bid = bidRepository.findByPublicId(bidPublicId)
                .orElseThrow(() -> new NoSuchElementException("Oferta no encontrada."));

        LoadEntity load = bid.getLoad();
        UserEntity publisher = userRepository.findWithAuthenticationDataByPublicId(publisherPublicId)
                .orElseThrow(() -> new NoSuchElementException("Usuario no encontrado."));

        if (!load.getPublisher().getPublicId().equals(publisher.getPublicId())) {
            throw new IllegalStateException("Solo la empresa que publicó la carga puede aceptar ofertas.");
        }

        if (!"PUBLISHED".equals(load.getStatus())) {
            throw new IllegalStateException("Esta carga ya no está disponible para contratación.");
        }

        Instant now = Instant.now();
        bid.accept(now);
        load.setStatus("ASSIGNED");

        // Rechaza las demás ofertas abiertas
        List<BidEntity> allBids = bidRepository.findByLoad_PublicIdOrderByCreatedAtUtcDesc(load.getPublicId());
        for (BidEntity other : allBids) {
            if (!other.getPublicId().equals(bid.getPublicId()) && "PENDING".equals(other.getStatus())) {
                other.reject(now);
            }
        }

        TripEntity trip = TripEntity.createFromBid(load, bid, now);
        TripEntity savedTrip = tripRepository.save(trip);

        auditService.record(publisher, "BID_ACCEPTED", "LOAD", load.getPublicId(), "SUCCESS");
        auditService.record(publisher, "TRIP_CREATED", "TRIP", savedTrip.getPublicId(), "SUCCESS");

        return toTripResponse(savedTrip);
    }

    @Transactional(readOnly = true)
    public List<TripResponse> getMyTrips(UUID userPublicId) {
        UserEntity user = userRepository.findWithAuthenticationDataByPublicId(userPublicId)
                .orElseThrow(() -> new NoSuchElementException("Usuario no encontrado."));

        List<TripEntity> asDriver = tripRepository.findByDriver_PublicIdOrderByCreatedAtUtcDesc(user.getPublicId());
        List<TripEntity> asPublisher = tripRepository.findByLoad_Publisher_PublicIdOrderByCreatedAtUtcDesc(user.getPublicId());

        return java.util.stream.Stream.concat(asDriver.stream(), asPublisher.stream())
                .distinct()
                .map(this::toTripResponse)
                .toList();
    }

    @Transactional
    public TripResponse startTrip(UUID tripPublicId, UUID driverPublicId) {
        TripEntity trip = tripRepository.findByPublicId(tripPublicId)
                .orElseThrow(() -> new NoSuchElementException("Viaje no encontrado."));

        UserEntity driver = userRepository.findWithAuthenticationDataByPublicId(driverPublicId)
                .orElseThrow(() -> new NoSuchElementException("Usuario no encontrado."));

        if (!trip.getDriver().getPublicId().equals(driver.getPublicId())) {
            throw new IllegalStateException("Solo el conductor asignado puede iniciar el viaje.");
        }

        Instant now = Instant.now();
        trip.startTrip(now);
        trip.getLoad().setStatus("IN_TRANSIT");

        auditService.record(driver, "TRIP_STARTED", "TRIP", trip.getPublicId(), "SUCCESS");
        return toTripResponse(trip);
    }

    @Transactional
    public TripResponse deliverTrip(UUID tripPublicId, DeliverTripRequest request, UUID driverPublicId) {
        TripEntity trip = tripRepository.findByPublicId(tripPublicId)
                .orElseThrow(() -> new NoSuchElementException("Viaje no encontrado."));

        UserEntity driver = userRepository.findWithAuthenticationDataByPublicId(driverPublicId)
                .orElseThrow(() -> new NoSuchElementException("Usuario no encontrado."));

        if (!trip.getDriver().getPublicId().equals(driver.getPublicId())) {
            throw new IllegalStateException("Solo el conductor asignado puede reportar la entrega.");
        }

        Instant now = Instant.now();
        trip.deliverTrip(request.proofNotes(), now);
        trip.getLoad().setStatus("DELIVERED");

        auditService.record(driver, "TRIP_DELIVERED", "TRIP", trip.getPublicId(), "SUCCESS");
        return toTripResponse(trip);
    }

    private BidResponse toBidResponse(BidEntity entity) {
        return new BidResponse(
                entity.getPublicId(),
                entity.getLoad().getPublicId(),
                entity.getBidder().getEmailNormalized(),
                entity.getBidder().getDisplayName(),
                entity.getOfferedAmount(),
                entity.getStatus(),
                entity.getProposedPickupDateUtc(),
                entity.getNotes(),
                entity.getCreatedAtUtc()
        );
    }

    private TripResponse toTripResponse(TripEntity entity) {
        return new TripResponse(
                entity.getPublicId(),
                entity.getLoad().getPublicId(),
                entity.getBid() != null ? entity.getBid().getPublicId() : null,
                entity.getDriver().getEmailNormalized(),
                entity.getDriver().getDisplayName(),
                entity.getAgreedAmount(),
                entity.getStatus(),
                entity.getStartedAtUtc(),
                entity.getDeliveredAtUtc(),
                entity.getDeliveryProofNotes(),
                entity.getCreatedAtUtc()
        );
    }
}
