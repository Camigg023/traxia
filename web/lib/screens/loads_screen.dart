import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../loads/bids_trips_models.dart';
import '../loads/load_api.dart';
import '../loads/load_models.dart';
import '../loads/trips_api.dart';
import '../state/app_providers.dart';
import '../theme/app_colors.dart';
import '../widgets/app_nav_bar.dart';

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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppNavBar(
        currentSection: AppNavSection.loads,
        title: 'Cargas Disponibles',
        extraActions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _fetchLoads,
            tooltip: 'Actualizar listado',
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1080),
          child: Column(
            children: [
              _buildFilterBar(isDark),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _error != null
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(_error!, style: const TextStyle(color: AppColors.error)),
                                const SizedBox(height: 12),
                                FilledButton.icon(
                                  onPressed: _fetchLoads,
                                  icon: const Icon(Icons.refresh_rounded, size: 18),
                                  label: const Text('Reintentar'),
                                ),
                              ],
                            ),
                          )
                        : _loads.isEmpty
                            ? _buildEmptyState(isDark)
                            : ListView.separated(
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                                itemCount: _loads.length,
                                separatorBuilder: (ctx, i) => const SizedBox(height: 16),
                                itemBuilder: (ctx, i) {
                                  final load = _loads[i];
                                  return _LoadCard(
                                    load: load,
                                    onSimulate: () => _openSimulationAndBidModal(load),
                                    isDark: isDark,
                                  );
                                },
                              ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterBar(bool isDark) {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 20, 24, 8),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
        boxShadow: SaasDecoration.softShadow(isDark),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _originFilter,
              decoration: const InputDecoration(
                hintText: 'Ciudad origen (ej: Bogotá)',
                prefixIcon: Icon(Icons.location_on_outlined, size: 20),
                contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
              onSubmitted: (_) => _fetchLoads(),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _destFilter,
              decoration: const InputDecoration(
                hintText: 'Ciudad destino (ej: Medellín)',
                prefixIcon: Icon(Icons.flag_outlined, size: 20),
                contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
              onSubmitted: (_) => _fetchLoads(),
            ),
          ),
          const SizedBox(width: 12),
          FilledButton.icon(
            onPressed: _fetchLoads,
            icon: const Icon(Icons.search_rounded, size: 18),
            label: const Text('Filtrar'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.local_shipping_outlined, size: 48, color: AppColors.primary),
            ),
            const SizedBox(height: 18),
            const Text(
              'No hay cargas con estos criterios',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'Prueba borrando los filtros de búsqueda o publica una nueva carga para verla aquí.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadCard extends StatelessWidget {
  const _LoadCard({
    required this.load,
    required this.onSimulate,
    required this.isDark,
  });

  final LoadModel load;
  final VoidCallback onSimulate;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
        boxShadow: SaasDecoration.softShadow(isDark),
      ),
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  load.status,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 11.5,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${load.vehicleType} • ${load.bodyType}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                ),
              ),
              const Spacer(),
              Text(
                load.offeredPrice != null
                    ? '\$ ${load.offeredPrice!.toStringAsFixed(0)} COP'
                    : 'A convenir',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.trip_origin_rounded, size: 16, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Text(
                          '${load.originCity}, ${load.originDepartment}',
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                        ),
                      ],
                    ),
                    const Padding(
                      padding: EdgeInsets.only(left: 7),
                      child: SizedBox(
                        height: 16,
                        child: VerticalDivider(thickness: 1.5),
                      ),
                    ),
                    Row(
                      children: [
                        const Icon(Icons.location_on_rounded, size: 16, color: AppColors.secondary),
                        const SizedBox(width: 8),
                        Text(
                          '${load.destinationCity}, ${load.destinationDepartment}',
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${load.weightKg.toStringAsFixed(0)} Kg',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                  Text(
                    load.productType,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Divider(),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton.icon(
                onPressed: onSimulate,
                icon: const Icon(Icons.calculate_rounded, size: 18),
                label: const Text('Simular Gemelo Digital y Ofertar'),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.primary),
                  foregroundColor: AppColors.primary,
                ),
              ),
            ],
          ),
        ],
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
  final _commentController = TextEditingController();
  bool _isSubmittingBid = false;

  @override
  void initState() {
    super.initState();
    _loadSimulation();
  }

  @override
  void dispose() {
    _bidAmountController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadSimulation() async {
    try {
      final api = TripsApi.fromEnvironment();
      final sim = await api.simulateRoute(widget.load.id);
      setState(() {
        _simulation = sim;
        _isLoadingSim = false;
        _bidAmountController.text = sim.suggestedBaseFreightCop.toStringAsFixed(0);
      });
    } catch (e) {
      setState(() {
        _simError = 'Error simulando ruta: $e';
        _isLoadingSim = false;
      });
    }
  }

  Future<void> _submitBid() async {
    final token = ref.read(authControllerProvider).accessToken;
    if (token == null) return;

    setState(() => _isSubmittingBid = true);
    try {
      final api = TripsApi.fromEnvironment();
      await api.createBid(
        loadId: widget.load.id,
        offeredAmount: double.tryParse(_bidAmountController.text) ?? (widget.load.offeredPrice ?? 0.0),
        notes: _commentController.text.trim().isEmpty ? null : _commentController.text.trim(),
        accessToken: token,
      );
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Oferta enviada exitosamente al generador de carga!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al ofertar: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmittingBid = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.calculate_rounded, color: AppColors.primary, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Gemelo Digital & Oferta de Flete',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                          ),
                          Text(
                            '${widget.load.originCity} → ${widget.load.destinationCity}',
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 16),
                if (_isLoadingSim)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else if (_simError != null)
                  Text(_simError!, style: const TextStyle(color: AppColors.error))
                else if (_simulation != null) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF162035) : AppColors.lightSurfaceSubtle,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Análisis Predictivo de Costos',
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                        ),
                        const SizedBox(height: 12),
                        _SimRow('Distancia estimada:', '${_simulation!.estimatedDistanceKm} km'),
                        _SimRow('Consumo combustible:', '${_simulation!.estimatedFuelGallons.toStringAsFixed(1)} Galones'),
                        _SimRow('Costo ACPM (\$10.500 COP):', '\$ ${_simulation!.estimatedFuelCostCop.toStringAsFixed(0)} COP'),
                        _SimRow('Peajes en ruta (${_simulation!.estimatedTollsCount}):', '\$ ${_simulation!.estimatedTollsCostCop.toStringAsFixed(0)} COP'),
                        const Divider(),
                        _SimRow('Flete mínimo sugerido:', '\$ ${_simulation!.suggestedBaseFreightCop.toStringAsFixed(0)} COP', highlight: true),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text('Tu Oferta Comercial', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _bidAmountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Valor postulado de tu flete (COP)',
                      prefixText: '\$ ',
                      prefixIcon: Icon(Icons.attach_money_rounded),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _commentController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Comentarios o condiciones de tu oferta',
                      hintText: 'Ej: Vehículo disponible de inmediato para cargue.',
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancelar'),
                      ),
                      const SizedBox(width: 12),
                      FilledButton(
                        onPressed: _isSubmittingBid ? null : _submitBid,
                        child: _isSubmittingBid
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Text('Enviar Oferta'),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SimRow extends StatelessWidget {
  const _SimRow(this.label, this.value, {this.highlight = false});

  final String label;
  final String value;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontWeight: highlight ? FontWeight.w700 : FontWeight.w500, fontSize: 13)),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: highlight ? 14.5 : 13,
              color: highlight ? AppColors.primary : null,
            ),
          ),
        ],
      ),
    );
  }
}
