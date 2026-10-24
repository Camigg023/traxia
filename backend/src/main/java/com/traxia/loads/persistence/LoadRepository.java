package com.traxia.loads.persistence;

import com.traxia.loads.domain.LoadEntity;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface LoadRepository extends JpaRepository<LoadEntity, Long> {

    Optional<LoadEntity> findByPublicId(UUID publicId);

    List<LoadEntity> findByPublisherIdOrderByCreatedAtUtcDesc(Long publisherId);

    List<LoadEntity> findByStatusOrderByCreatedAtUtcDesc(String status);

    @Query("SELECT l FROM LoadEntity l WHERE l.status = 'PUBLISHED' " +
           "AND (:originCity IS NULL OR LOWER(l.originCity) LIKE LOWER(CONCAT('%', :originCity, '%'))) " +
           "AND (:destCity IS NULL OR LOWER(l.destinationCity) LIKE LOWER(CONCAT('%', :destCity, '%'))) " +
           "AND (:vehicleType IS NULL OR LOWER(l.vehicleType) LIKE LOWER(CONCAT('%', :vehicleType, '%'))) " +
           "ORDER BY l.createdAtUtc DESC")
    List<LoadEntity> searchAvailableLoads(
            @Param("originCity") String originCity,
            @Param("destCity") String destCity,
            @Param("vehicleType") String vehicleType);
}
