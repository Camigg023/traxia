package com.traxia.loads.persistence;

import com.traxia.loads.domain.BidEntity;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface BidRepository extends JpaRepository<BidEntity, Long> {

    Optional<BidEntity> findByPublicId(UUID publicId);

    List<BidEntity> findByLoad_PublicIdOrderByCreatedAtUtcDesc(UUID loadPublicId);

    List<BidEntity> findByBidder_PublicIdOrderByCreatedAtUtcDesc(UUID bidderPublicId);
}
