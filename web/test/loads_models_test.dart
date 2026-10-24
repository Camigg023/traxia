import 'package:flutter_test/flutter_test.dart';
import 'package:traxia_web/loads/load_models.dart';

void main() {
  test('serializa y deserializa LoadModel correctamente', () {
    final now = DateTime.now().toUtc();
    final json = {
      'id': 'a1b2c3d4-e5f6-7a8b-9c0d-1e2f3a4b5c6d',
      'publisherEmail': 'empresa@traxia.co',
      'publisherName': 'Distribuciones Colombia',
      'status': 'PUBLISHED',
      'originDepartment': 'Cundinamarca',
      'originCity': 'Bogotá',
      'originAddress': 'Zona Industrial',
      'pickupDateUtc': now.toIso8601String(),
      'destinationDepartment': 'Antioquia',
      'destinationCity': 'Medellín',
      'destinationAddress': 'Centro Logístico',
      'deliveryDateUtc': now.add(const Duration(days: 1)).toIso8601String(),
      'productType': 'Alimentos perecederos',
      'weightKg': 4500.0,
      'volumeM3': 20.0,
      'packagingType': 'Estibas',
      'requiresRefrigeration': true,
      'vehicleType': 'Camión Sencillo',
      'bodyType': 'Furgón',
      'pricingType': 'OFFERED',
      'offeredPrice': 2500000.0,
      'payer': 'REMITTENT',
      'specialInstructions': 'Revisar sellos de seguridad',
      'createdAtUtc': now.toIso8601String(),
    };

    final model = LoadModel.fromJson(json);

    expect(model.id, 'a1b2c3d4-e5f6-7a8b-9c0d-1e2f3a4b5c6d');
    expect(model.originCity, 'Bogotá');
    expect(model.destinationCity, 'Medellín');
    expect(model.weightKg, 4500.0);
    expect(model.requiresRefrigeration, isTrue);
    expect(model.offeredPrice, 2500000.0);
  });
}
