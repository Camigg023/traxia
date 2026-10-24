package com.traxia.loads.api;

import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import java.math.BigDecimal;
import java.time.Instant;
import java.util.UUID;

public final class LoadDtos {

    private LoadDtos() {
    }

    public record CreateLoadRequest(
            @NotBlank(message = "El departamento de origen es obligatorio.")
            @Size(max = 100)
            String originDepartment,

            @NotBlank(message = "La ciudad de origen es obligatoria.")
            @Size(max = 100)
            String originCity,

            @Size(max = 255)
            String originAddress,

            @NotNull(message = "La fecha de recogida es obligatoria.")
            Instant pickupDateUtc,

            @NotBlank(message = "El departamento de destino es obligatorio.")
            @Size(max = 100)
            String destinationDepartment,

            @NotBlank(message = "La ciudad de destino es obligatoria.")
            @Size(max = 100)
            String destinationCity,

            @Size(max = 255)
            String destinationAddress,

            @NotNull(message = "La fecha de entrega es obligatoria.")
            Instant deliveryDateUtc,

            @NotBlank(message = "El tipo de producto es obligatorio.")
            @Size(max = 100)
            String productType,

            @NotNull(message = "El peso es obligatorio.")
            @DecimalMin(value = "0.01", message = "El peso debe ser mayor a 0.")
            BigDecimal weightKg,

            BigDecimal volumeM3,

            @Size(max = 100)
            String packagingType,

            boolean requiresRefrigeration,

            @NotBlank(message = "El tipo de vehículo es obligatorio.")
            @Size(max = 100)
            String vehicleType,

            @NotBlank(message = "El tipo de carrocería es obligatorio.")
            @Size(max = 100)
            String bodyType,

            String pricingType,

            BigDecimal offeredPrice,

            String payer,

            String specialInstructions
    ) {
    }

    public record LoadResponse(
            UUID id,
            String publisherEmail,
            String publisherName,
            String status,
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
            Instant createdAtUtc
    ) {
    }
}
