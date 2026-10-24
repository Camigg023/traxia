package com.traxia.loads.api;

import com.traxia.loads.api.BidDtos.BidResponse;
import com.traxia.loads.api.BidDtos.CreateBidRequest;
import com.traxia.loads.api.LoadDtos.CreateLoadRequest;
import com.traxia.loads.api.LoadDtos.LoadResponse;
import com.traxia.loads.application.BidAndTripService;
import com.traxia.loads.application.LoadService;
import com.traxia.loads.application.SimulationService;
import com.traxia.loads.application.SimulationService.RouteSimulationResponse;
import com.traxia.loads.domain.LoadEntity;
import com.traxia.loads.persistence.LoadRepository;
import jakarta.validation.Valid;
import java.util.List;
import java.util.NoSuchElementException;
import java.util.UUID;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/loads")
public class LoadController {

    private final LoadService loadService;
    private final SimulationService simulationService;
    private final BidAndTripService bidAndTripService;
    private final LoadRepository loadRepository;

    public LoadController(
            LoadService loadService,
            SimulationService simulationService,
            BidAndTripService bidAndTripService,
            LoadRepository loadRepository) {
        this.loadService = loadService;
        this.simulationService = simulationService;
        this.bidAndTripService = bidAndTripService;
        this.loadRepository = loadRepository;
    }

    @PostMapping
    public ResponseEntity<LoadResponse> createLoad(
            @Valid @RequestBody CreateLoadRequest request,
            @AuthenticationPrincipal Jwt jwt) {
        UUID userPublicId = UUID.fromString(jwt.getSubject());
        LoadResponse created = loadService.createLoad(request, userPublicId);
        return ResponseEntity.status(HttpStatus.CREATED).body(created);
    }

    @GetMapping("/my")
    public List<LoadResponse> getMyLoads(@AuthenticationPrincipal Jwt jwt) {
        UUID userPublicId = UUID.fromString(jwt.getSubject());
        return loadService.getMyLoads(userPublicId);
    }

    @GetMapping
    public List<LoadResponse> searchLoads(
            @RequestParam(required = false) String originCity,
            @RequestParam(required = false) String destinationCity,
            @RequestParam(required = false) String vehicleType) {
        return loadService.searchLoads(originCity, destinationCity, vehicleType);
    }

    @GetMapping("/{id}")
    public LoadResponse getLoad(@PathVariable UUID id) {
        return loadService.getLoadByPublicId(id);
    }

    @GetMapping("/{id}/simulate")
    public RouteSimulationResponse simulate(@PathVariable UUID id) {
        LoadEntity load = loadRepository.findByPublicId(id)
                .orElseThrow(() -> new NoSuchElementException("Carga no encontrada."));
        return simulationService.simulate(load);
    }

    @PostMapping("/{id}/bids")
    public ResponseEntity<BidResponse> createBid(
            @PathVariable UUID id,
            @Valid @RequestBody CreateBidRequest request,
            @AuthenticationPrincipal Jwt jwt) {
        UUID bidderPublicId = UUID.fromString(jwt.getSubject());
        BidResponse response = bidAndTripService.createBid(id, request, bidderPublicId);
        return ResponseEntity.status(HttpStatus.CREATED).body(response);
    }

    @GetMapping("/{id}/bids")
    public List<BidResponse> getBidsForLoad(
            @PathVariable UUID id,
            @AuthenticationPrincipal Jwt jwt) {
        UUID userPublicId = UUID.fromString(jwt.getSubject());
        return bidAndTripService.getBidsForLoad(id, userPublicId);
    }
}
