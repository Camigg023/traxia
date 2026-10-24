package com.traxia.loads.application;

import com.traxia.common.audit.AuditService;
import com.traxia.identity.domain.UserEntity;
import com.traxia.identity.persistence.UserRepository;
import com.traxia.loads.api.LoadDtos.CreateLoadRequest;
import com.traxia.loads.api.LoadDtos.LoadResponse;
import com.traxia.loads.domain.LoadEntity;
import com.traxia.loads.persistence.LoadRepository;
import java.time.Instant;
import java.util.List;
import java.util.NoSuchElementException;
import java.util.UUID;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class LoadService {

    private final LoadRepository loadRepository;
    private final UserRepository userRepository;
    private final AuditService auditService;

    public LoadService(
            LoadRepository loadRepository,
            UserRepository userRepository,
            AuditService auditService) {
        this.loadRepository = loadRepository;
        this.userRepository = userRepository;
        this.auditService = auditService;
    }

    @Transactional
    public LoadResponse createLoad(CreateLoadRequest request, UUID publisherPublicId) {
        UserEntity publisher = userRepository.findWithAuthenticationDataByPublicId(publisherPublicId)
                .orElseThrow(() -> new NoSuchElementException("Usuario publicador no encontrado."));

        if (!"ACTIVE".equals(publisher.getStatus())) {
            throw new IllegalStateException("La cuenta debe estar activa para publicar cargas.");
        }

        Instant now = Instant.now();
        LoadEntity load = LoadEntity.create(
                publisher,
                request.originDepartment().trim(),
                request.originCity().trim(),
                request.originAddress() != null ? request.originAddress().trim() : null,
                request.pickupDateUtc(),
                request.destinationDepartment().trim(),
                request.destinationCity().trim(),
                request.destinationAddress() != null ? request.destinationAddress().trim() : null,
                request.deliveryDateUtc(),
                request.productType().trim(),
                request.weightKg(),
                request.volumeM3(),
                request.packagingType() != null ? request.packagingType().trim() : null,
                request.requiresRefrigeration(),
                request.vehicleType().trim(),
                request.bodyType().trim(),
                request.pricingType(),
                request.offeredPrice(),
                request.payer(),
                request.specialInstructions() != null ? request.specialInstructions().trim() : null,
                now
        );

        LoadEntity saved = loadRepository.save(load);
        auditService.record(publisher, "LOAD_PUBLISHED", "LOAD", saved.getPublicId(), "SUCCESS");

        return toResponse(saved);
    }

    @Transactional(readOnly = true)
    public List<LoadResponse> getMyLoads(UUID publisherPublicId) {
        UserEntity publisher = userRepository.findWithAuthenticationDataByPublicId(publisherPublicId)
                .orElseThrow(() -> new NoSuchElementException("Usuario no encontrado."));

        return loadRepository.findByPublisherIdOrderByCreatedAtUtcDesc(publisher.getId())
                .stream()
                .map(this::toResponse)
                .toList();
    }

    @Transactional(readOnly = true)
    public List<LoadResponse> searchLoads(String originCity, String destCity, String vehicleType) {
        String origin = (originCity != null && !originCity.isBlank()) ? originCity.trim() : null;
        String dest = (destCity != null && !destCity.isBlank()) ? destCity.trim() : null;
        String vehicle = (vehicleType != null && !vehicleType.isBlank()) ? vehicleType.trim() : null;

        return loadRepository.searchAvailableLoads(origin, dest, vehicle)
                .stream()
                .map(this::toResponse)
                .toList();
    }

    @Transactional(readOnly = true)
    public LoadResponse getLoadByPublicId(UUID publicId) {
        LoadEntity load = loadRepository.findByPublicId(publicId)
                .orElseThrow(() -> new NoSuchElementException("Carga no encontrada."));
        return toResponse(load);
    }

    private LoadResponse toResponse(LoadEntity entity) {
        return new LoadResponse(
                entity.getPublicId(),
                entity.getPublisher().getEmailNormalized(),
                entity.getPublisher().getDisplayName(),
                entity.getStatus(),
                entity.getOriginDepartment(),
                entity.getOriginCity(),
                entity.getOriginAddress(),
                entity.getPickupDateUtc(),
                entity.getDestinationDepartment(),
                entity.getDestinationCity(),
                entity.getDestinationAddress(),
                entity.getDeliveryDateUtc(),
                entity.getProductType(),
                entity.getWeightKg(),
                entity.getVolumeM3(),
                entity.getPackagingType(),
                entity.isRequiresRefrigeration(),
                entity.getVehicleType(),
                entity.getBodyType(),
                entity.getPricingType(),
                entity.getOfferedPrice(),
                entity.getPayer(),
                entity.getSpecialInstructions(),
                entity.getCreatedAtUtc()
        );
    }
}
