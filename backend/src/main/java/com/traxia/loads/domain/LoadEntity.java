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
@Table(name = "loads")
public class LoadEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @JdbcTypeCode(SqlTypes.BINARY)
    @Column(name = "public_id", nullable = false, unique = true, columnDefinition = "BINARY(16)")
    private UUID publicId;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "publisher_user_id", nullable = false)
    private UserEntity publisher;

    @Column(nullable = false, length = 32)
    private String status;

    @Column(name = "origin_department", nullable = false, length = 100)
    private String originDepartment;

    @Column(name = "origin_city", nullable = false, length = 100)
    private String originCity;

    @Column(name = "origin_address", length = 255)
    private String originAddress;

    @Column(name = "pickup_date_utc", nullable = false)
    private Instant pickupDateUtc;

    @Column(name = "destination_department", nullable = false, length = 100)
    private String destinationDepartment;

    @Column(name = "destination_city", nullable = false, length = 100)
    private String destinationCity;

    @Column(name = "destination_address", length = 255)
    private String destinationAddress;

    @Column(name = "delivery_date_utc", nullable = false)
    private Instant deliveryDateUtc;

    @Column(name = "product_type", nullable = false, length = 100)
    private String productType;

    @Column(name = "weight_kg", nullable = false, precision = 10, scale = 2)
    private BigDecimal weightKg;

    @Column(name = "volume_m3", precision = 10, scale = 2)
    private BigDecimal volumeM3;

    @Column(name = "packaging_type", length = 100)
    private String packagingType;

    @Column(name = "requires_refrigeration", nullable = false)
    private boolean requiresRefrigeration;

    @Column(name = "vehicle_type", nullable = false, length = 100)
    private String vehicleType;

    @Column(name = "body_type", nullable = false, length = 100)
    private String bodyType;

    @Column(name = "pricing_type", nullable = false, length = 32)
    private String pricingType;

    @Column(name = "offered_price", precision = 12, scale = 2)
    private BigDecimal offeredPrice;

    @Column(nullable = false, length = 64)
    private String payer;

    @Column(name = "special_instructions", columnDefinition = "TEXT")
    private String specialInstructions;

    @Column(name = "created_at_utc", nullable = false)
    private Instant createdAtUtc;

    @Column(name = "updated_at_utc", nullable = false)
    private Instant updatedAtUtc;

    protected LoadEntity() {
    }

    public static LoadEntity create(
            UserEntity publisher,
            String originDepartment,
            String originCity,
            String originAddress,
            Instant pickupDateUtc,
            String destinationDepartment,
            String destinationCity,
            String destinationAddress,
            Instant deliveryDateUtc,
            String productType,
            BigDecimal weightKg,
            BigDecimal volumeM3,
            String packagingType,
            boolean requiresRefrigeration,
            String vehicleType,
            String bodyType,
            String pricingType,
            BigDecimal offeredPrice,
            String payer,
            String specialInstructions,
            Instant now) {
        LoadEntity entity = new LoadEntity();
        entity.publicId = UUID.randomUUID();
        entity.publisher = publisher;
        entity.status = "PUBLISHED";
        entity.originDepartment = originDepartment;
        entity.originCity = originCity;
        entity.originAddress = originAddress;
        entity.pickupDateUtc = pickupDateUtc;
        entity.destinationDepartment = destinationDepartment;
        entity.destinationCity = destinationCity;
        entity.destinationAddress = destinationAddress;
        entity.deliveryDateUtc = deliveryDateUtc;
        entity.productType = productType;
        entity.weightKg = weightKg;
        entity.volumeM3 = volumeM3;
        entity.packagingType = packagingType;
        entity.requiresRefrigeration = requiresRefrigeration;
        entity.vehicleType = vehicleType;
        entity.bodyType = bodyType;
        entity.pricingType = pricingType != null ? pricingType : "OFFERED";
        entity.offeredPrice = offeredPrice;
        entity.payer = payer != null ? payer : "REMITTENT";
        entity.specialInstructions = specialInstructions;
        entity.createdAtUtc = now;
        entity.updatedAtUtc = now;
        return entity;
    }

    public Long getId() {
        return id;
    }

    public UUID getPublicId() {
        return publicId;
    }

    public UserEntity getPublisher() {
        return publisher;
    }

    public String getStatus() {
        return status;
    }

    public void setStatus(String status) {
        this.status = status;
    }

    public String getOriginDepartment() {
        return originDepartment;
    }

    public String getOriginCity() {
        return originCity;
    }

    public String getOriginAddress() {
        return originAddress;
    }

    public Instant getPickupDateUtc() {
        return pickupDateUtc;
    }

    public String getDestinationDepartment() {
        return destinationDepartment;
    }

    public String getDestinationCity() {
        return destinationCity;
    }

    public String getDestinationAddress() {
        return destinationAddress;
    }

    public Instant getDeliveryDateUtc() {
        return deliveryDateUtc;
    }

    public String getProductType() {
        return productType;
    }

    public BigDecimal getWeightKg() {
        return weightKg;
    }

    public BigDecimal getVolumeM3() {
        return volumeM3;
    }

    public String getPackagingType() {
        return packagingType;
    }

    public boolean isRequiresRefrigeration() {
        return requiresRefrigeration;
    }

    public String getVehicleType() {
        return vehicleType;
    }

    public String getBodyType() {
        return bodyType;
    }

    public String getPricingType() {
        return pricingType;
    }

    public BigDecimal getOfferedPrice() {
        return offeredPrice;
    }

    public String getPayer() {
        return payer;
    }

    public String getSpecialInstructions() {
        return specialInstructions;
    }

    public Instant getCreatedAtUtc() {
        return createdAtUtc;
    }

    public Instant getUpdatedAtUtc() {
        return updatedAtUtc;
    }
}
