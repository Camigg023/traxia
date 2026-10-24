package com.traxia.loads.application;

import com.traxia.loads.domain.LoadEntity;
import java.math.BigDecimal;
import java.math.RoundingMode;
import java.util.Locale;
import java.util.Map;
import org.springframework.stereotype.Service;

@Service
public class SimulationService {

    private static final BigDecimal FUEL_PRICE_PER_GALLON_COP = new BigDecimal("10500.00");
    private static final BigDecimal TOLL_AVG_COST_COP = new BigDecimal("14500.00");

    private static final Map<String, Integer> ROUTE_DISTANCES_KM = Map.ofEntries(
            Map.entry("bogota-medellin", 420),
            Map.entry("medellin-bogota", 420),
            Map.entry("bogota-cali", 460),
            Map.entry("cali-bogota", 460),
            Map.entry("bogota-barranquilla", 980),
            Map.entry("barranquilla-bogota", 980),
            Map.entry("bogota-bucaramanga", 390),
            Map.entry("bucaramanga-bogota", 390),
            Map.entry("medellin-cali", 420),
            Map.entry("cali-medellin", 420),
            Map.entry("medellin-barranquilla", 710),
            Map.entry("barranquilla-medellin", 710),
            Map.entry("cali-buenaventura", 120),
            Map.entry("buenaventura-cali", 120)
    );

    public record RouteSimulationResponse(
            String originCity,
            String destinationCity,
            String vehicleType,
            int estimatedDistanceKm,
            int estimatedTollsCount,
            BigDecimal estimatedTollsCostCop,
            BigDecimal estimatedFuelGallons,
            BigDecimal estimatedFuelCostCop,
            BigDecimal estimatedDirectCostCop,
            BigDecimal suggestedBaseFreightCop,
            String dataSource,
            String disclaimer
    ) {
    }

    public RouteSimulationResponse simulate(LoadEntity load) {
        String originKey = normalizeCity(load.getOriginCity());
        String destKey = normalizeCity(load.getDestinationCity());
        String routeKey = originKey + "-" + destKey;

        int distanceKm = ROUTE_DISTANCES_KM.getOrDefault(routeKey, 380);
        int tollsCount = Math.max(1, distanceKm / 75);

        BigDecimal tollsCost = TOLL_AVG_COST_COP.multiply(BigDecimal.valueOf(tollsCount));

        double kmPerGallon = getKmPerGallon(load.getVehicleType());
        BigDecimal gallons = BigDecimal.valueOf(distanceKm / kmPerGallon)
                .setScale(2, RoundingMode.HALF_UP);
        BigDecimal fuelCost = gallons.multiply(FUEL_PRICE_PER_GALLON_COP)
                .setScale(2, RoundingMode.HALF_UP);

        BigDecimal directCost = fuelCost.add(tollsCost);
        // Margen operativo recomendado del 45% sobre costos directos
        BigDecimal suggestedFreight = directCost.multiply(new BigDecimal("1.45"))
                .setScale(2, RoundingMode.HALF_UP);

        return new RouteSimulationResponse(
                load.getOriginCity(),
                load.getDestinationCity(),
                load.getVehicleType(),
                distanceKm,
                tollsCount,
                tollsCost,
                gallons,
                fuelCost,
                directCost,
                suggestedFreight,
                "Simulador Logístico TRAXIA - Parámetros Colombia 2026",
                "Estimación referencial no vinculante basada en promedios de rutas nacionales. Los costos reales pueden variar según condiciones viales y paradas intermedias."
        );
    }

    private String normalizeCity(String city) {
        if (city == null) return "";
        return city.trim().toLowerCase(Locale.ROOT)
                .replace("á", "a")
                .replace("é", "e")
                .replace("í", "i")
                .replace("ó", "o")
                .replace("ú", "u")
                .replace(" ", "");
    }

    private double getKmPerGallon(String vehicleType) {
        if (vehicleType == null) return 12.0;
        String lower = vehicleType.toLowerCase(Locale.ROOT);
        if (lower.contains("camioneta")) return 30.0;
        if (lower.contains("turbo")) return 18.0;
        if (lower.contains("sencillo")) return 12.0;
        if (lower.contains("doble")) return 8.0;
        if (lower.contains("tractomula")) return 5.5;
        return 12.0;
    }
}
