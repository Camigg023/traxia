import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../loads/bids_trips_models.dart';
import '../loads/load_api.dart';
import '../loads/load_models.dart';
import '../loads/trips_api.dart';
import '../state/app_providers.dart';

class LoadsScreen extends ConsumerStatefulWidget {
  const LoadsScreen({super.key});

  @override
  ConsumerState<LoadsScreen> createState() => _LoadsScreenState();
}

class _LoadsScreenState extends ConsumerState<LoadsScreen> {
  final _originFilter = TextEditingController();
  final _destFilter = TextEditingController();
  String? _selectedVehicleFilter;

  List<LoadModel> _loads = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchLoads();
  }

  @override
  void dispose() {
    _originFilter.dispose();
    _destFilter.dispose();
    super.dispose();
  }

  Future<void> _fetchLoads() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final api = LoadApi.fromEnvironment();
      final results = await api.searchLoads(
        originCity: _originFilter.text.trim(),
        destinationCity: _destFilter.text.trim(),
        vehicleType: _selectedVehicleFilter,
      );
      setState(() {
        _loads = results;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'No se pudieron cargar las ofertas: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _openSimulationAndBidModal(LoadModel load) async {
    showDialog(
      context: context,
      builder: (ctx) => _SimulationAndBidDialog(load: load),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cargas y Viajes Disponibles'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/dashboard'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchLoads,
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 960),
          child: Column(
            children: [
              _buildFilterBar(),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _error != null
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(_error!, style: const TextStyle(color: Colors.red)),
                                const SizedBox(height: 12),
                                FilledButton(onPressed: _fetchLoads, child: const Text('Reintentar')),
                              ],
                            ),
                          )
                        : _loads.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.local_shipping_outlined, size: 64, color: Colors.grey),
                                    const SizedBox(height: 16),
                                    const Text('No hay cargas disponibles con los filtros actuales.',
                                        style: TextStyle(fontSize: 16, color: Colors.grey)),
                                    const SizedBox(height: 12),
                                    OutlinedButton(
                                      onPressed: () {
                                        _originFilter.clear();
                                        _destFilter.clear();
                                        setState(() => _selectedVehicleFilter = null);
                                        _fetchLoads();
                                      },
                                      child: const Text('Limpiar filtros'),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.all(16),
                                itemCount: _loads.length,
                                itemBuilder: (context, index) {
                                  return _buildLoadCard(_loads[index]);
                                },
                              ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterBar() {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _originFilter,
                decoration: const InputDecoration(
                  labelText: 'Ciudad Origen',
                  prefixIcon: Icon(Icons.trip_origin),
                  isDense: true,
                ),
                onSubmitted: (_) => _fetchLoads(),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _destFilter,
                decoration: const InputDecoration(
                  labelText: 'Ciudad Destino',
                  prefixIcon: Icon(Icons.location_on_outlined),
                  isDense: true,
                ),
                onSubmitted: (_) => _fetchLoads(),
              ),
            ),
            const SizedBox(width: 8),
            FilledButton.icon(
              onPressed: _fetchLoads,
              icon: const Icon(Icons.search),
              label: const Text('Filtrar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadCard(LoadModel load) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Chip(
                  label: Text('${load.vehicleType} • ${load.bodyType}'),
                  backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                ),
                Text(
                  load.pricingType == 'OFFERED'
                      ? '\$ ${load.offeredPrice?.toStringAsFixed(0) ?? "0"} COP'
                      : 'Cotización abierta',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.arrow_circle_right, color: Colors.blue),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${load.originCity} (${load.originDepartment}) ➔ ${load.destinationCity} (${load.destinationDepartment})',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('Producto: ${load.productType} • Peso: ${load.weightKg.toStringAsFixed(0)} Kg'),
            if (load.requiresRefrigeration)
              const Row(
                children: [
                  Icon(Icons.ac_unit, size: 16, color: Colors.cyan),
                  SizedBox(width: 4),
                  Text('Requiere refrigeración', style: TextStyle(color: Colors.cyan, fontSize: 13)),
                ],
              ),
            if (load.specialInstructions != null && load.specialInstructions!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text('Instrucciones: ${load.specialInstructions}',
                  style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.grey)),
            ],
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Publicado por: ${load.publisherName}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey)),
                FilledButton.tonalIcon(
                  onPressed: () => _openSimulationAndBidModal(load),
                  icon: const Icon(Icons.calculate_outlined),
                  label: const Text('Simular y Postularse'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SimulationAndBidDialog extends ConsumerStatefulWidget {
  const _SimulationAndBidDialog({required this.load});
  final LoadModel load;

  @override
  ConsumerState<_SimulationAndBidDialog> createState() => _SimulationAndBidDialogState();
}

class _SimulationAndBidDialogState extends ConsumerState<_SimulationAndBidDialog> {
  RouteSimulationModel? _simulation;
  bool _isLoadingSim = true;
  String? _simError;

  final _bidAmountController = TextEditingController();
  final _notesController = TextEditingController();
  bool _isSubmittingBid = false;

  @override
  void initState() {
    super.initState();
    _loadSimulation();
    if (widget.load.offeredPrice != null) {
      _bidAmountController.text = widget.load.offeredPrice!.toStringAsFixed(0);
    }
  }

  @override
  void dispose() {
    _bidAmountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadSimulation() async {
    try {
      final api = TripsApi.fromEnvironment();
      final sim = await api.simulateRoute(widget.load.id);
      setState(() {
        _simulation = sim;
        _isLoadingSim = false;
        if (_bidAmountController.text.isEmpty) {
          _bidAmountController.text = sim.suggestedBaseFreightCop.toStringAsFixed(0);
        }
      });
    } catch (e) {
      setState(() {
        _simError = 'No se pudo cargar la simulación: $e';
        _isLoadingSim = false;
      });
    }
  }

  Future<void> _submitBid() async {
    final amount = double.tryParse(_bidAmountController.text.trim());
    if (amount == null || amount < 1000) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa un monto válido para tu oferta.'), backgroundColor: Colors.red),
      );
      return;
    }

    final auth = ref.read(authControllerProvider);
    final token = auth.user?.accessToken;
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Inicia sesión para enviar tu postulación.'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isSubmittingBid = true);
    try {
      final api = TripsApi.fromEnvironment();
      await api.createBid(
        loadId: widget.load.id,
        offeredAmount: amount,
        notes: _notesController.text.trim(),
        accessToken: token,
      );
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Oferta enviada exitosamente! La empresa publicadora revisará tu propuesta.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() => _isSubmittingBid = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al enviar oferta: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Simulación de Costos y Oferta - Carga #${widget.load.id.substring(0, 8)}'),
      content: SizedBox(
        width: 600,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${widget.load.originCity} ➔ ${widget.load.destinationCity}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 12),
              if (_isLoadingSim)
                const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
              else if (_simError != null)
                Text(_simError!, style: const TextStyle(color: Colors.red))
              else if (_simulation != null) ...[
                Card(
                  color: Theme.of(context).colorScheme.surfaceVariant,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.hub_outlined, color: Colors.blue),
                            SizedBox(width: 8),
                            Text('Gemelo Digital - Parámetros de Ruta', style: TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const Divider(),
                        Text('• Distancia estimada: ${_simulation!.estimatedDistanceKm} Km'),
                        Text('• Peajes estimados: ${_simulation!.estimatedTollsCount} (~ \$ ${_simulation!.estimatedTollsCostCop.toStringAsFixed(0)} COP)'),
                        Text('• Combustible estimado: ${_simulation!.estimatedFuelGallons.toStringAsFixed(1)} Gal (~ \$ ${_simulation!.estimatedFuelCostCop.toStringAsFixed(0)} COP)'),
                        Text('• Costo directo proyectado: \$ ${_simulation!.estimatedDirectCostCop.toStringAsFixed(0)} COP',
                            style: const TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        Text(
                          '• Flete base sugerido por TRAXIA: \$ ${_simulation!.suggestedBaseFreightCop.toStringAsFixed(0)} COP',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _simulation!.disclaimer,
                          style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Tu Oferta para este Viaje', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                TextField(
                  controller: _bidAmountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Valor propuesto (COP) *',
                    prefixText: '\$ ',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _notesController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Mensaje / Condiciones de recogida',
                    hintText: 'Ej: Vehículo disponible de inmediato en zona norte.',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cerrar')),
        FilledButton(
          onPressed: _isSubmittingBid ? null : _submitBid,
          child: _isSubmittingBid
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Enviar Postulación'),
        ),
      ],
    );
  }
}
