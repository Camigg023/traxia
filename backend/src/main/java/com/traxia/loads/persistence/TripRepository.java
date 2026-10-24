package com.traxia.loads.persistence;

import com.traxia.loads.domain.TripEntity;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface TripRepository extends JpaRepository<TripEntity, Long> {

    Optional<TripEntity> findByPublicId(UUID publicId);

    Optional<TripEntity> findByLoad_PublicId(UUID loadPublicId);

    List<TripEntity> findByDriver_PublicIdOrderByCreatedAtUtcDesc(UUID driverPublicId);

    List<TripEntity> findByLoad_Publisher_PublicIdOrderByCreatedAtUtcDesc(UUID publisherPublicId);
}
