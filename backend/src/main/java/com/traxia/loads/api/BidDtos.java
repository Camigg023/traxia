package com.traxia.loads.api;

import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotNull;
import java.math.BigDecimal;
import java.time.Instant;
import java.util.UUID;

public final class BidDtos {

    private BidDtos() {
    }

    public record CreateBidRequest(
            @NotNull(message = "El monto de la oferta es obligatorio.")
            @DecimalMin(value = "1000.00", message = "El monto debe ser de al menos $1,000 COP.")
            BigDecimal offeredAmount,

            Instant proposedPickupDateUtc,

            String notes
    ) {
    }

    public record BidResponse(
            UUID id,
            UUID loadId,
            String bidderEmail,
            String bidderName,
            BigDecimal offeredAmount,
            String status,
            Instant proposedPickupDateUtc,
            String notes,
            Instant createdAtUtc
    ) {
    }

    public record DeliverTripRequest(
            String proofNotes
    ) {
    }

    public record TripResponse(
            UUID id,
            UUID loadId,
            UUID bidId,
            String driverEmail,
            String driverName,
            BigDecimal agreedAmount,
            String status,
            Instant startedAtUtc,
            Instant deliveredAtUtc,
            String deliveryProofNotes,
            Instant createdAtUtc
    ) {
    }
}
