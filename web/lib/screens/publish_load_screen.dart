import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../loads/load_api.dart';
import '../loads/load_models.dart';
import '../state/app_providers.dart';
import '../theme/app_colors.dart';
import '../widgets/app_nav_bar.dart';

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
  final DateTime _pickupDate = DateTime.now().add(const Duration(hours: 4));

  final _destDeptController = TextEditingController(text: 'Antioquia');
  final _destCityController = TextEditingController(text: 'Medellín');
  final _destAddressController = TextEditingController();
  final DateTime _deliveryDate = DateTime.now().add(const Duration(days: 1, hours: 4));

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

    try {
      final token = ref.read(authControllerProvider).accessToken;
      if (token == null) {
        throw Exception('Debes iniciar sesión para publicar una carga.');
      }

      final dto = CreateLoadDto(
        originDepartment: _originDeptController.text.trim(),
        originCity: _originCityController.text.trim(),
        originAddress: _originAddressController.text.trim().isEmpty ? null : _originAddressController.text.trim(),
        pickupDateUtc: _pickupDate,
        destinationDepartment: _destDeptController.text.trim(),
        destinationCity: _destCityController.text.trim(),
        destinationAddress: _destAddressController.text.trim().isEmpty ? null : _destAddressController.text.trim(),
        deliveryDateUtc: _deliveryDate,
        productType: _productTypeController.text.trim(),
        packagingType: _packagingController.text.trim().isEmpty ? null : _packagingController.text.trim(),
        weightKg: double.tryParse(_weightController.text) ?? 1000.0,
        volumeM3: double.tryParse(_volumeController.text),
        requiresRefrigeration: _requiresRefrigeration,
        vehicleType: _selectedVehicleType,
        bodyType: _selectedBodyType,
        pricingType: _pricingType,
        offeredPrice: double.tryParse(_priceController.text) ?? 1000000.0,
        payer: _payer,
        specialInstructions: _instructionsController.text.trim().isEmpty ? null : _instructionsController.text.trim(),
      );

      final api = LoadApi.fromEnvironment();
      await api.createLoad(load: dto, accessToken: token);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Carga publicada exitosamente en el tablero!'),
            backgroundColor: AppColors.success,
          ),
        );
        context.go('/cargas');
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error al publicar carga: $e';
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: const AppNavBar(
        currentSection: AppNavSection.publishLoad,
        title: 'Publicar Carga',
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 880),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
                boxShadow: SaasDecoration.elevatedShadow(isDark),
              ),
              padding: const EdgeInsets.all(32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: isDark ? 0.2 : 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.add_box_rounded, color: AppColors.primary, size: 24),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Nueva Publicación de Carga',
                              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Define el trayecto, las especificaciones de carga y el flete en COP para recibir postulaciones de conductores.',
                              style: theme.textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),
                  if (_errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(14),
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: AppColors.errorContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline_rounded, color: AppColors.error),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(color: Color(0xFF991B1B), fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  Stepper(
                    physics: const NeverScrollableScrollPhysics(),
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
                        context.go('/panel');
                      }
                    },
                    controlsBuilder: (context, details) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 24),
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
                                  : Text(_currentStep == 4 ? 'Publicar Carga en Tablero' : 'Siguiente Paso'),
                            ),
                            const SizedBox(width: 12),
                            if (_currentStep > 0)
                              OutlinedButton(
                                onPressed: _isSubmitting ? null : details.onStepCancel,
                                child: const Text('Anterior'),
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Step _buildStep1() {
    return Step(
      title: const Text('Origen y Destino', style: TextStyle(fontWeight: FontWeight.w700)),
      subtitle: const Text('Ruta de transporte y ventanas horarias estimadas'),
      isActive: _currentStep >= 0,
      state: _currentStep > 0 ? StepState.complete : StepState.indexed,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          const Text('Ubicación de Origen', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _originDeptController,
                  decoration: const InputDecoration(labelText: 'Departamento origen *'),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: TextFormField(
                  controller: _originCityController,
                  decoration: const InputDecoration(labelText: 'Ciudad origen *'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _originAddressController,
            decoration: const InputDecoration(
              labelText: 'Dirección o punto de cargue',
              prefixIcon: Icon(Icons.location_on_outlined),
            ),
          ),
          const SizedBox(height: 24),
          const Text('Ubicación de Destino', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _destDeptController,
                  decoration: const InputDecoration(labelText: 'Departamento destino *'),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: TextFormField(
                  controller: _destCityController,
                  decoration: const InputDecoration(labelText: 'Ciudad destino *'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _destAddressController,
            decoration: const InputDecoration(
              labelText: 'Dirección o punto de entrega',
              prefixIcon: Icon(Icons.flag_outlined),
            ),
          ),
        ],
      ),
    );
  }

  Step _buildStep2() {
    return Step(
      title: const Text('Detalles de la Mercancía', style: TextStyle(fontWeight: FontWeight.w700)),
      subtitle: const Text('Tipo de producto, peso, empaque y refrigeración'),
      isActive: _currentStep >= 1,
      state: _currentStep > 1 ? StepState.complete : StepState.indexed,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          TextFormField(
            controller: _productTypeController,
            decoration: const InputDecoration(
              labelText: 'Tipo de producto / Descripción *',
              prefixIcon: Icon(Icons.inventory_2_outlined),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _weightController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Peso total en Kg *',
                    prefixIcon: Icon(Icons.scale_outlined),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: TextFormField(
                  controller: _volumeController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Volumen estimado en m³',
                    prefixIcon: Icon(Icons.view_in_ar_outlined),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _packagingController,
            decoration: const InputDecoration(
              labelText: 'Tipo de embalaje (Estibas, Cajas, A granel)',
              prefixIcon: Icon(Icons.all_inbox_outlined),
            ),
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            title: const Text('¿Requiere cadena de frío / refrigeración?', style: TextStyle(fontSize: 13.5)),
            value: _requiresRefrigeration,
            onChanged: (val) => setState(() => _requiresRefrigeration = val),
            activeThumbColor: AppColors.primary,
            contentPadding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }

  Step _buildStep3() {
    return Step(
      title: const Text('Configuración del Vehículo', style: TextStyle(fontWeight: FontWeight.w700)),
      subtitle: const Text('Tipología vehicular y carrocería requerida'),
      isActive: _currentStep >= 2,
      state: _currentStep > 2 ? StepState.complete : StepState.indexed,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: _selectedVehicleType,
            decoration: const InputDecoration(
              labelText: 'Tipo de vehículo requerido *',
              prefixIcon: Icon(Icons.local_shipping_outlined),
            ),
            items: _vehicleTypes.map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
            onChanged: (val) => setState(() => _selectedVehicleType = val!),
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<String>(
            initialValue: _selectedBodyType,
            decoration: const InputDecoration(
              labelText: 'Tipo de carrocería requerida *',
              prefixIcon: Icon(Icons.directions_bus_outlined),
            ),
            items: _bodyTypes.map((b) => DropdownMenuItem(value: b, child: Text(b))).toList(),
            onChanged: (val) => setState(() => _selectedBodyType = val!),
          ),
        ],
      ),
    );
  }

  Step _buildStep4() {
    return Step(
      title: const Text('Condiciones Comerciales', style: TextStyle(fontWeight: FontWeight.w700)),
      subtitle: const Text('Flete ofertado, pagador e instrucciones especiales'),
      isActive: _currentStep >= 3,
      state: _currentStep > 3 ? StepState.complete : StepState.indexed,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _pricingType,
                  decoration: const InputDecoration(labelText: 'Modalidad de precio *'),
                  items: const [
                    DropdownMenuItem(value: 'OFFERED', child: Text('Precio Ofertado')),
                    DropdownMenuItem(value: 'NEGOTIABLE', child: Text('A Convenir')),
                  ],
                  onChanged: (val) => setState(() => _pricingType = val!),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: TextFormField(
                  controller: _priceController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Valor flete (COP) *',
                    prefixText: '\$ ',
                    prefixIcon: Icon(Icons.attach_money_rounded),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<String>(
            initialValue: _payer,
            decoration: const InputDecoration(labelText: 'Responsable del pago del flete *'),
            items: const [
              DropdownMenuItem(value: 'REMITTENT', child: Text('Remitente (Al cargar)')),
              DropdownMenuItem(value: 'CONSIGNEE', child: Text('Destinatario (Contra entrega)')),
            ],
            onChanged: (val) => setState(() => _payer = val!),
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _instructionsController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Instrucciones especiales para el conductor',
              hintText: 'Ej: Presentar planilla ARL, uso obligatorio de botas y chaleco reflectivo.',
            ),
          ),
        ],
      ),
    );
  }

  Step _buildStep5() {
    return Step(
      title: const Text('Resumen y Confirmación', style: TextStyle(fontWeight: FontWeight.w700)),
      subtitle: const Text('Verificación final antes de publicar en la plataforma'),
      isActive: _currentStep >= 4,
      state: StepState.indexed,
      content: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Resumen del Flete a Publicar',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
            const SizedBox(height: 12),
            _SummaryRow('Trayecto:', '${_originCityController.text} → ${_destCityController.text}'),
            _SummaryRow('Mercancía:', '${_productTypeController.text} (${_weightController.text} Kg)'),
            _SummaryRow('Vehículo:', '$_selectedVehicleType ($_selectedBodyType)'),
            _SummaryRow('Flete Estimado:', '\$ ${_priceController.text} COP'),
            _SummaryRow('Pagador:', _payer == 'REMITTENT' ? 'Remitente' : 'Destinatario'),
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5, color: AppColors.primary)),
        ],
      ),
    );
  }
}
