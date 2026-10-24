package com.traxia.loads.api;

import com.traxia.loads.api.BidDtos.BidResponse;
import com.traxia.loads.api.BidDtos.DeliverTripRequest;
import com.traxia.loads.api.BidDtos.TripResponse;
import com.traxia.loads.application.BidAndTripService;
import java.util.List;
import java.util.UUID;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1")
public class TripController {

    private final BidAndTripService bidAndTripService;

    public TripController(BidAndTripService bidAndTripService) {
        this.bidAndTripService = bidAndTripService;
    }

    @GetMapping("/bids/my")
    public List<BidResponse> getMyBids(@AuthenticationPrincipal Jwt jwt) {
        UUID userPublicId = UUID.fromString(jwt.getSubject());
        return bidAndTripService.getMyBids(userPublicId);
    }

    @PostMapping("/bids/{id}/accept")
    public TripResponse acceptBid(
            @PathVariable UUID id,
            @AuthenticationPrincipal Jwt jwt) {
        UUID userPublicId = UUID.fromString(jwt.getSubject());
        return bidAndTripService.acceptBid(id, userPublicId);
    }

    @GetMapping("/trips/my")
    public List<TripResponse> getMyTrips(@AuthenticationPrincipal Jwt jwt) {
        UUID userPublicId = UUID.fromString(jwt.getSubject());
        return bidAndTripService.getMyTrips(userPublicId);
    }

    @PostMapping("/trips/{id}/start")
    public TripResponse startTrip(
            @PathVariable UUID id,
            @AuthenticationPrincipal Jwt jwt) {
        UUID userPublicId = UUID.fromString(jwt.getSubject());
        return bidAndTripService.startTrip(id, userPublicId);
    }

    @PostMapping("/trips/{id}/deliver")
    public TripResponse deliverTrip(
            @PathVariable UUID id,
            @RequestBody(required = false) DeliverTripRequest request,
            @AuthenticationPrincipal Jwt jwt) {
        UUID userPublicId = UUID.fromString(jwt.getSubject());
        DeliverTripRequest req = request != null ? request : new DeliverTripRequest("Entrega reportada satisfactoriamente.");
        return bidAndTripService.deliverTrip(id, req, userPublicId);
    }
}
