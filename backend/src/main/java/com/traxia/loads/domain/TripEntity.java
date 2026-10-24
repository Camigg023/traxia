package com.traxia.loads.domain;

import com.traxia.identity.domain.UserEntity;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.OneToOne;
import jakarta.persistence.Table;
import java.math.BigDecimal;
import java.time.Instant;
import java.util.UUID;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;

@Entity
@Table(name = "trips")
public class TripEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @JdbcTypeCode(SqlTypes.BINARY)
    @Column(name = "public_id", nullable = false, unique = true, columnDefinition = "BINARY(16)")
    private UUID publicId;

    @OneToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "load_id", nullable = false, unique = true)
    private LoadEntity load;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "bid_id")
    private BidEntity bid;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "driver_user_id", nullable = false)
    private UserEntity driver;

    @Column(name = "agreed_amount", nullable = false, precision = 12, scale = 2)
    private BigDecimal agreedAmount;

    @Column(nullable = false, length = 32)
    private String status;

    @Column(name = "started_at_utc")
    private Instant startedAtUtc;

    @Column(name = "delivered_at_utc")
    private Instant deliveredAtUtc;

    @Column(name = "delivery_proof_notes", columnDefinition = "TEXT")
    private String deliveryProofNotes;

    @Column(name = "created_at_utc", nullable = false)
    private Instant createdAtUtc;

    @Column(name = "updated_at_utc", nullable = false)
    private Instant updatedAtUtc;

    protected TripEntity() {
    }

    public static TripEntity createFromBid(LoadEntity load, BidEntity bid, Instant now) {
        TripEntity trip = new TripEntity();
        trip.publicId = UUID.randomUUID();
        trip.load = load;
        trip.bid = bid;
        trip.driver = bid.getBidder();
        trip.agreedAmount = bid.getOfferedAmount();
        trip.status = "ASSIGNED";
        trip.createdAtUtc = now;
        trip.updatedAtUtc = now;
        return trip;
    }

    public void startTrip(Instant now) {
        if (!"ASSIGNED".equals(this.status)) {
            throw new IllegalStateException("Solo se puede iniciar un viaje en estado ASIGNADO.");
        }
        this.status = "IN_TRANSIT";
        this.startedAtUtc = now;
        this.updatedAtUtc = now;
    }

    public void deliverTrip(String proofNotes, Instant now) {
        if (!"IN_TRANSIT".equals(this.status)) {
            throw new IllegalStateException("Solo se puede entregar un viaje que esté EN TRÁNSITO.");
        }
        this.status = "DELIVERED";
        this.deliveredAtUtc = now;
        this.deliveryProofNotes = proofNotes;
        this.updatedAtUtc = now;
    }

    public Long getId() {
        return id;
    }

    public UUID getPublicId() {
        return publicId;
    }

    public LoadEntity getLoad() {
        return load;
    }

    public BidEntity getBid() {
        return bid;
    }

    public UserEntity getDriver() {
        return driver;
    }

    public BigDecimal getAgreedAmount() {
        return agreedAmount;
    }

    public String getStatus() {
        return status;
    }

    public Instant getStartedAtUtc() {
        return startedAtUtc;
    }

    public Instant getDeliveredAtUtc() {
        return deliveredAtUtc;
    }

    public String getDeliveryProofNotes() {
        return deliveryProofNotes;
    }

    public Instant getCreatedAtUtc() {
        return createdAtUtc;
    }

    public Instant getUpdatedAtUtc() {
        return updatedAtUtc;
    }
}
