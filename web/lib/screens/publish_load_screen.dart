import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../loads/load_api.dart';
import '../loads/load_models.dart';
import '../state/app_providers.dart';

class PublishLoadScreen extends ConsumerStatefulWidget {
  const PublishLoadScreen({super.key});

  @override
  ConsumerState<PublishLoadScreen> createState() => _PublishLoadScreenState();
}

class _PublishLoadScreenState extends ConsumerState<PublishLoadScreen> {
  int _currentStep = 0;
  bool _isSubmitting = false;
  String? _errorMessage;

  // Paso 1: Origen y destino
  final _originDeptController = TextEditingController(text: 'Cundinamarca');
  final _originCityController = TextEditingController(text: 'Bogotá');
  final _originAddressController = TextEditingController();
  DateTime _pickupDate = DateTime.now().add(const Duration(hours: 4));

  final _destDeptController = TextEditingController(text: 'Antioquia');
  final _destCityController = TextEditingController(text: 'Medellín');
  final _destAddressController = TextEditingController();
  DateTime _deliveryDate = DateTime.now().add(const Duration(days: 1, hours: 4));

  // Paso 2: Mercancía
  final _productTypeController = TextEditingController(text: 'Mercancía seca');
  final _weightController = TextEditingController(text: '4500');
  final _volumeController = TextEditingController(text: '18');
  final _packagingController = TextEditingController(text: 'Estibas / Cajas');
  bool _requiresRefrigeration = false;

  // Paso 3: Vehículo
  String _selectedVehicleType = 'Camión Sencillo';
  String _selectedBodyType = 'Furgón';

  final List<String> _vehicleTypes = [
    'Camioneta',
    'Turbo',
    'Camión Sencillo',
    'Doble Troque',
    'Cuatro Manos',
    'Tractomula (2 ejes)',
    'Tractomula (3 ejes)',
  ];

  final List<String> _bodyTypes = [
    'Furgón',
    'Estacas',
    'Planchón',
    'Refrigerado',
    'Tanque',
    'Tolva',
    'Portacontenedor',
  ];

  // Paso 4: Condiciones
  String _pricingType = 'OFFERED';
  final _priceController = TextEditingController(text: '2800000');
  String _payer = 'REMITTENT';
  final _instructionsController = TextEditingController();

  final List<String> _payers = ['REMITTENT', 'DESTINATARY', 'SPLIT'];

  @override
  void dispose() {
    _originDeptController.dispose();
    _originCityController.dispose();
    _originAddressController.dispose();
    _destDeptController.dispose();
    _destCityController.dispose();
    _destAddressController.dispose();
    _productTypeController.dispose();
    _weightController.dispose();
    _volumeController.dispose();
    _packagingController.dispose();
    _priceController.dispose();
    _instructionsController.dispose();
    super.dispose();
  }

  Future<void> _submitLoad() async {
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final authState = ref.read(authControllerProvider);
    final token = authState.user?.accessToken;
    if (token == null) {
      setState(() {
        _isSubmitting = false;
        _errorMessage = 'Sesión no válida. Por favor inicia sesión de nuevo.';
      });
      return;
    }

    final weight = double.tryParse(_weightController.text.trim()) ?? 0.0;
    final volume = double.tryParse(_volumeController.text.trim());
    final price = _pricingType == 'OFFERED' ? double.tryParse(_priceController.text.trim()) : null;

    final dto = CreateLoadDto(
      originDepartment: _originDeptController.text.trim(),
      originCity: _originCityController.text.trim(),
      originAddress: _originAddressController.text.trim(),
      pickupDateUtc: _pickupDate,
      destinationDepartment: _destDeptController.text.trim(),
      destinationCity: _destCityController.text.trim(),
      destinationAddress: _destAddressController.text.trim(),
      deliveryDateUtc: _deliveryDate,
      productType: _productTypeController.text.trim(),
      weightKg: weight,
      volumeM3: volume,
      packagingType: _packagingController.text.trim(),
      requiresRefrigeration: _requiresRefrigeration,
      vehicleType: _selectedVehicleType,
      bodyType: _selectedBodyType,
      pricingType: _pricingType,
      offeredPrice: price,
      payer: _payer,
      specialInstructions: _instructionsController.text.trim(),
    );

    try {
      final api = LoadApi.fromEnvironment();
      await api.createLoad(load: dto, accessToken: token);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Carga publicada exitosamente! Ya es visible para conductores.'),
            backgroundColor: Colors.green,
          ),
        );
        context.go('/loads');
      }
    } catch (e) {
      setState(() {
        _isSubmitting = false;
        _errorMessage = 'Error al publicar carga: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Publicar Nueva Carga'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/dashboard'),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Stepper(
            type: StepperType.vertical,
            currentStep: _currentStep,
            onStepContinue: () {
              if (_currentStep < 4) {
                setState(() => _currentStep++);
              } else {
                _submitLoad();
              }
            },
            onStepCancel: () {
              if (_currentStep > 0) {
                setState(() => _currentStep--);
              } else {
                context.go('/dashboard');
              }
            },
            controlsBuilder: (context, details) {
              return Padding(
                padding: const EdgeInsets.only(top: 20),
                child: Row(
                  children: [
                    FilledButton(
                      onPressed: _isSubmitting ? null : details.onStepContinue,
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : Text(_currentStep == 4 ? 'Publicar Carga' : 'Continuar'),
                    ),
                    const SizedBox(width: 12),
                    if (_currentStep > 0)
                      OutlinedButton(
                        onPressed: _isSubmitting ? null : details.onStepCancel,
                        child: const Text('Atrás'),
                      ),
                  ],
                ),
              );
            },
            steps: [
              _buildStep1(),
              _buildStep2(),
              _buildStep3(),
              _buildStep4(),
              _buildStep5(),
            ],
          ),
        ),
      ),
    );
  }

  Step _buildStep1() {
    return Step(
      title: const Text('Paso 1: Origen y Destino'),
      subtitle: const Text('Ubicaciones y fechas estimadas de recogida y entrega'),
      isActive: _currentStep >= 0,
      state: _currentStep > 0 ? StepState.complete : StepState.indexed,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Origen de Recogida', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _originDeptController,
                  decoration: const InputDecoration(labelText: 'Departamento origen *', border: OutlineInputBorder()),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _originCityController,
                  decoration: const InputDecoration(labelText: 'Ciudad origen *', border: OutlineInputBorder()),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _originAddressController,
            decoration: const InputDecoration(labelText: 'Dirección o punto de carga', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 8),
          const Text('Destino de Entrega', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _destDeptController,
                  decoration: const InputDecoration(labelText: 'Departamento destino *', border: OutlineInputBorder()),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _destCityController,
                  decoration: const InputDecoration(labelText: 'Ciudad destino *', border: OutlineInputBorder()),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _destAddressController,
            decoration: const InputDecoration(labelText: 'Dirección o punto de descarga', border: OutlineInputBorder()),
          ),
        ],
      ),
    );
  }

  Step _buildStep2() {
    return Step(
      title: const Text('Paso 2: Mercancía'),
      subtitle: const Text('Peso, volumen y requerimientos especiales'),
      isActive: _currentStep >= 1,
      state: _currentStep > 1 ? StepState.complete : StepState.indexed,
      content: Column(
        children: [
          TextFormField(
            controller: _productTypeController,
            decoration: const InputDecoration(labelText: 'Tipo de producto *', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _weightController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Peso en kilogramos (Kg) *', border: OutlineInputBorder()),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _volumeController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Volumen aproximado (m³)', border: OutlineInputBorder()),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _packagingController,
            decoration: const InputDecoration(labelText: 'Tipo de embalaje (cajas, estibas, etc.)', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            title: const Text('Requiere refrigeración'),
            subtitle: const Text('Activar si la carga es perecedera o requiere cadena de frío'),
            value: _requiresRefrigeration,
            onChanged: (val) => setState(() => _requiresRefrigeration = val),
          ),
        ],
      ),
    );
  }

  Step _buildStep3() {
    return Step(
      title: const Text('Paso 3: Vehículo Requerido'),
      subtitle: const Text('Clasificación y carrocería apta'),
      isActive: _currentStep >= 2,
      state: _currentStep > 2 ? StepState.complete : StepState.indexed,
      content: Column(
        children: [
          DropdownButtonFormField<String>(
            value: _selectedVehicleType,
            decoration: const InputDecoration(labelText: 'Tipo de vehículo *', border: OutlineInputBorder()),
            items: _vehicleTypes.map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
            onChanged: (val) => setState(() => _selectedVehicleType = val!),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _selectedBodyType,
            decoration: const InputDecoration(labelText: 'Tipo de carrocería *', border: OutlineInputBorder()),
            items: _bodyTypes.map((b) => DropdownMenuItem(value: b, child: Text(b))).toList(),
            onChanged: (val) => setState(() => _selectedBodyType = val!),
          ),
        ],
      ),
    );
  }

  Step _buildStep4() {
    return Step(
      title: const Text('Paso 4: Condiciones Económicas'),
      subtitle: const Text('Flete ofrecido o solicitud de cotización'),
      isActive: _currentStep >= 3,
      state: _currentStep > 3 ? StepState.complete : StepState.indexed,
      content: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: RadioListTile<String>(
                  title: const Text('Valor ofrecido'),
                  value: 'OFFERED',
                  groupValue: _pricingType,
                  onChanged: (val) => setState(() => _pricingType = val!),
                ),
              ),
              Expanded(
                child: RadioListTile<String>(
                  title: const Text('A convenir / Cotización'),
                  value: 'QUOTE_REQUEST',
                  groupValue: _pricingType,
                  onChanged: (val) => setState(() => _pricingType = val!),
                ),
              ),
            ],
          ),
          if (_pricingType == 'OFFERED') ...[
            const SizedBox(height: 8),
            TextFormField(
              controller: _priceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Valor sugerido flete (COP)', prefixText: '\$ ', border: OutlineInputBorder()),
            ),
          ],
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _payer,
            decoration: const InputDecoration(labelText: '¿Quién asume el pago? *', border: OutlineInputBorder()),
            items: const [
              DropdownMenuItem(value: 'REMITTENT', child: Text('Remitente (Empresa origen)')),
              DropdownMenuItem(value: 'DESTINATARY', child: Text('Destinatario (Cliente entrega)')),
              DropdownMenuItem(value: 'SPLIT', child: Text('Compartido / Mixto')),
            ],
            onChanged: (val) => setState(() => _payer = val!),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _instructionsController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Instrucciones especiales para el conductor',
              hintText: 'Ej: Presentarse con EPP completos, carné de vacunas, sellos de seguridad.',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
    );
  }

  Step _buildStep5() {
    return Step(
      title: const Text('Paso 5: Revisar y Publicar'),
      subtitle: const Text('Verifica los datos antes de emitir la publicación'),
      isActive: _currentStep >= 4,
      state: StepState.indexed,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_errorMessage != null)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(color: Colors.red.shade100, borderRadius: BorderRadius.circular(8)),
              child: Text(_errorMessage!, style: TextStyle(color: Colors.red.shade900)),
            ),
          Card(
            elevation: 0,
            color: Theme.of(context).colorScheme.surfaceVariant,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Ruta: ${_originCityController.text} (${_originDeptController.text}) ➔ ${_destCityController.text} (${_destDeptController.text})',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  Text('Producto: ${_productTypeController.text} (${_weightController.text} Kg)'),
                  Text('Vehículo: $_selectedVehicleType - $_selectedBodyType'),
                  Text('Refrigeración: ${_requiresRefrigeration ? "Sí" : "No"}'),
                  Text('Condición: ${_pricingType == "OFFERED" ? "Flete \$ ${_priceController.text} COP" : "Cotización abierta"}'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
