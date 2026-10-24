class RouteSimulationModel {
  const RouteSimulationModel({
    required this.originCity,
    required this.destinationCity,
    required this.vehicleType,
    required this.estimatedDistanceKm,
    required this.estimatedTollsCount,
    required this.estimatedTollsCostCop,
    required this.estimatedFuelGallons,
    required this.estimatedFuelCostCop,
    required this.estimatedDirectCostCop,
    required this.suggestedBaseFreightCop,
    required this.dataSource,
    required this.disclaimer,
  });

  factory RouteSimulationModel.fromJson(Map<String, dynamic> json) {
    return RouteSimulationModel(
      originCity: json['originCity'] as String? ?? '',
      destinationCity: json['destinationCity'] as String? ?? '',
      vehicleType: json['vehicleType'] as String? ?? '',
      estimatedDistanceKm: json['estimatedDistanceKm'] as int? ?? 0,
      estimatedTollsCount: json['estimatedTollsCount'] as int? ?? 0,
      estimatedTollsCostCop: (json['estimatedTollsCostCop'] as num?)?.toDouble() ?? 0.0,
      estimatedFuelGallons: (json['estimatedFuelGallons'] as num?)?.toDouble() ?? 0.0,
      estimatedFuelCostCop: (json['estimatedFuelCostCop'] as num?)?.toDouble() ?? 0.0,
      estimatedDirectCostCop: (json['estimatedDirectCostCop'] as num?)?.toDouble() ?? 0.0,
      suggestedBaseFreightCop: (json['suggestedBaseFreightCop'] as num?)?.toDouble() ?? 0.0,
      dataSource: json['dataSource'] as String? ?? '',
      disclaimer: json['disclaimer'] as String? ?? '',
    );
  }

  final String originCity;
  final String destinationCity;
  final String vehicleType;
  final int estimatedDistanceKm;
  final int estimatedTollsCount;
  final double estimatedTollsCostCop;
  final double estimatedFuelGallons;
  final double estimatedFuelCostCop;
  final double estimatedDirectCostCop;
  final double suggestedBaseFreightCop;
  final String dataSource;
  final String disclaimer;
}

class BidModel {
  const BidModel({
    required this.id,
    required this.loadId,
    required this.bidderEmail,
    required this.bidderName,
    required this.offeredAmount,
    required this.status,
    this.proposedPickupDateUtc,
    this.notes,
    required this.createdAtUtc,
  });

  factory BidModel.fromJson(Map<String, dynamic> json) {
    return BidModel(
      id: json['id'] as String,
      loadId: json['loadId'] as String,
      bidderEmail: json['bidderEmail'] as String? ?? '',
      bidderName: json['bidderName'] as String? ?? '',
      offeredAmount: (json['offeredAmount'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] as String? ?? 'PENDING',
      proposedPickupDateUtc: json['proposedPickupDateUtc'] != null
          ? DateTime.parse(json['proposedPickupDateUtc'] as String)
          : null,
      notes: json['notes'] as String?,
      createdAtUtc: DateTime.parse(json['createdAtUtc'] as String),
    );
  }

  final String id;
  final String loadId;
  final String bidderEmail;
  final String bidderName;
  final double offeredAmount;
  final String status;
  final DateTime? proposedPickupDateUtc;
  final String? notes;
  final DateTime createdAtUtc;
}

class TripModel {
  const TripModel({
    required this.id,
    required this.loadId,
    this.bidId,
    required this.driverEmail,
    required this.driverName,
    required this.agreedAmount,
    required this.status,
    this.startedAtUtc,
    this.deliveredAtUtc,
    this.deliveryProofNotes,
    required this.createdAtUtc,
  });

  factory TripModel.fromJson(Map<String, dynamic> json) {
    return TripModel(
      id: json['id'] as String,
      loadId: json['loadId'] as String,
      bidId: json['bidId'] as String?,
      driverEmail: json['driverEmail'] as String? ?? '',
      driverName: json['driverName'] as String? ?? '',
      agreedAmount: (json['agreedAmount'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] as String? ?? 'ASSIGNED',
      startedAtUtc: json['startedAtUtc'] != null
          ? DateTime.parse(json['startedAtUtc'] as String)
          : null,
      deliveredAtUtc: json['deliveredAtUtc'] != null
          ? DateTime.parse(json['deliveredAtUtc'] as String)
          : null,
      deliveryProofNotes: json['deliveryProofNotes'] as String?,
      createdAtUtc: DateTime.parse(json['createdAtUtc'] as String),
    );
  }

  final String id;
  final String loadId;
  final String? bidId;
  final String driverEmail;
  final String driverName;
  final double agreedAmount;
  final String status;
  final DateTime? startedAtUtc;
  final DateTime? deliveredAtUtc;
  final String? deliveryProofNotes;
  final DateTime createdAtUtc;
}
