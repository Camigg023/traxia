class LoadModel {
  const LoadModel({
    required this.id,
    required this.publisherEmail,
    required this.publisherName,
    required this.status,
    required this.originDepartment,
    required this.originCity,
    this.originAddress,
    required this.pickupDateUtc,
    required this.destinationDepartment,
    required this.destinationCity,
    this.destinationAddress,
    required this.deliveryDateUtc,
    required this.productType,
    required this.weightKg,
    this.volumeM3,
    this.packagingType,
    required this.requiresRefrigeration,
    required this.vehicleType,
    required this.bodyType,
    required this.pricingType,
    this.offeredPrice,
    required this.payer,
    this.specialInstructions,
    required this.createdAtUtc,
  });

  factory LoadModel.fromJson(Map<String, dynamic> json) {
    return LoadModel(
      id: json['id'] as String,
      publisherEmail: json['publisherEmail'] as String? ?? '',
      publisherName: json['publisherName'] as String? ?? 'Empresa',
      status: json['status'] as String? ?? 'PUBLISHED',
      originDepartment: json['originDepartment'] as String? ?? '',
      originCity: json['originCity'] as String? ?? '',
      originAddress: json['originAddress'] as String?,
      pickupDateUtc: DateTime.parse(json['pickupDateUtc'] as String),
      destinationDepartment: json['destinationDepartment'] as String? ?? '',
      destinationCity: json['destinationCity'] as String? ?? '',
      destinationAddress: json['destinationAddress'] as String?,
      deliveryDateUtc: DateTime.parse(json['deliveryDateUtc'] as String),
      productType: json['productType'] as String? ?? '',
      weightKg: (json['weightKg'] as num?)?.toDouble() ?? 0.0,
      volumeM3: (json['volumeM3'] as num?)?.toDouble(),
      packagingType: json['packagingType'] as String?,
      requiresRefrigeration: json['requiresRefrigeration'] as bool? ?? false,
      vehicleType: json['vehicleType'] as String? ?? '',
      bodyType: json['bodyType'] as String? ?? '',
      pricingType: json['pricingType'] as String? ?? 'OFFERED',
      offeredPrice: (json['offeredPrice'] as num?)?.toDouble(),
      payer: json['payer'] as String? ?? 'REMITTENT',
      specialInstructions: json['specialInstructions'] as String?,
      createdAtUtc: DateTime.parse(json['createdAtUtc'] as String),
    );
  }

  final String id;
  final String publisherEmail;
  final String publisherName;
  final String status;
  final String originDepartment;
  final String originCity;
  final String? originAddress;
  final DateTime pickupDateUtc;
  final String destinationDepartment;
  final String destinationCity;
  final String? destinationAddress;
  final DateTime deliveryDateUtc;
  final String productType;
  final double weightKg;
  final double? volumeM3;
  final String? packagingType;
  final bool requiresRefrigeration;
  final String vehicleType;
  final String bodyType;
  final String pricingType;
  final double? offeredPrice;
  final String payer;
  final String? specialInstructions;
  final DateTime createdAtUtc;

  Map<String, dynamic> toJson() => {
    'id': id,
    'publisherEmail': publisherEmail,
    'publisherName': publisherName,
    'status': status,
    'originDepartment': originDepartment,
    'originCity': originCity,
    'originAddress': originAddress,
    'pickupDateUtc': pickupDateUtc.toIso8601String(),
    'destinationDepartment': destinationDepartment,
    'destinationCity': destinationCity,
    'destinationAddress': destinationAddress,
    'deliveryDateUtc': deliveryDateUtc.toIso8601String(),
    'productType': productType,
    'weightKg': weightKg,
    'volumeM3': volumeM3,
    'packagingType': packagingType,
    'requiresRefrigeration': requiresRefrigeration,
    'vehicleType': vehicleType,
    'bodyType': bodyType,
    'pricingType': pricingType,
    'offeredPrice': offeredPrice,
    'payer': payer,
    'specialInstructions': specialInstructions,
    'createdAtUtc': createdAtUtc.toIso8601String(),
  };
}

class CreateLoadDto {
  const CreateLoadDto({
    required this.originDepartment,
    required this.originCity,
    this.originAddress,
    required this.pickupDateUtc,
    required this.destinationDepartment,
    required this.destinationCity,
    this.destinationAddress,
    required this.deliveryDateUtc,
    required this.productType,
    required this.weightKg,
    this.volumeM3,
    this.packagingType,
    required this.requiresRefrigeration,
    required this.vehicleType,
    required this.bodyType,
    required this.pricingType,
    this.offeredPrice,
    required this.payer,
    this.specialInstructions,
  });

  final String originDepartment;
  final String originCity;
  final String? originAddress;
  final DateTime pickupDateUtc;
  final String destinationDepartment;
  final String destinationCity;
  final String? destinationAddress;
  final DateTime deliveryDateUtc;
  final String productType;
  final double weightKg;
  final double? volumeM3;
  final String? packagingType;
  final bool requiresRefrigeration;
  final String vehicleType;
  final String bodyType;
  final String pricingType;
  final double? offeredPrice;
  final String payer;
  final String? specialInstructions;

  Map<String, dynamic> toJson() => {
    'originDepartment': originDepartment,
    'originCity': originCity,
    if (originAddress != null && originAddress!.isNotEmpty) 'originAddress': originAddress,
    'pickupDateUtc': pickupDateUtc.toUtc().toIso8601String(),
    'destinationDepartment': destinationDepartment,
    'destinationCity': destinationCity,
    if (destinationAddress != null && destinationAddress!.isNotEmpty) 'destinationAddress': destinationAddress,
    'deliveryDateUtc': deliveryDateUtc.toUtc().toIso8601String(),
    'productType': productType,
    'weightKg': weightKg,
    if (volumeM3 != null) 'volumeM3': volumeM3,
    if (packagingType != null && packagingType!.isNotEmpty) 'packagingType': packagingType,
    'requiresRefrigeration': requiresRefrigeration,
    'vehicleType': vehicleType,
    'bodyType': bodyType,
    'pricingType': pricingType,
    if (offeredPrice != null) 'offeredPrice': offeredPrice,
    'payer': payer,
    if (specialInstructions != null && specialInstructions!.isNotEmpty) 'specialInstructions': specialInstructions,
  };
}
