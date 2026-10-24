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
import jakarta.persistence.Table;
import java.math.BigDecimal;
import java.time.Instant;
import java.util.UUID;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;

@Entity
@Table(name = "bids")
public class BidEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @JdbcTypeCode(SqlTypes.BINARY)
    @Column(name = "public_id", nullable = false, unique = true, columnDefinition = "BINARY(16)")
    private UUID publicId;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "load_id", nullable = false)
    private LoadEntity load;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "bidder_user_id", nullable = false)
    private UserEntity bidder;

    @Column(name = "offered_amount", nullable = false, precision = 12, scale = 2)
    private BigDecimal offeredAmount;

    @Column(nullable = false, length = 32)
    private String status;

    @Column(name = "proposed_pickup_date_utc")
    private Instant proposedPickupDateUtc;

    @Column(columnDefinition = "TEXT")
    private String notes;

    @Column(name = "created_at_utc", nullable = false)
    private Instant createdAtUtc;

    @Column(name = "updated_at_utc", nullable = false)
    private Instant updatedAtUtc;

    protected BidEntity() {
    }

    public static BidEntity create(
            LoadEntity load,
            UserEntity bidder,
            BigDecimal offeredAmount,
            Instant proposedPickupDateUtc,
            String notes,
            Instant now) {
        BidEntity bid = new BidEntity();
        bid.publicId = UUID.randomUUID();
        bid.load = load;
        bid.bidder = bidder;
        bid.offeredAmount = offeredAmount;
        bid.status = "PENDING";
        bid.proposedPickupDateUtc = proposedPickupDateUtc;
        bid.notes = notes;
        bid.createdAtUtc = now;
        bid.updatedAtUtc = now;
        return bid;
    }

    public void accept(Instant now) {
        this.status = "ACCEPTED";
        this.updatedAtUtc = now;
    }

    public void reject(Instant now) {
        this.status = "REJECTED";
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

    public UserEntity getBidder() {
        return bidder;
    }

    public BigDecimal getOfferedAmount() {
        return offeredAmount;
    }

    public String getStatus() {
        return status;
    }

    public Instant getProposedPickupDateUtc() {
        return proposedPickupDateUtc;
    }

    public String getNotes() {
        return notes;
    }

    public Instant getCreatedAtUtc() {
        return createdAtUtc;
    }

    public Instant getUpdatedAtUtc() {
        return updatedAtUtc;
    }
}
