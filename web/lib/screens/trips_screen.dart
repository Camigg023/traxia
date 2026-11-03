import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../loads/bids_trips_models.dart';
import '../loads/load_api.dart';
import '../loads/load_models.dart';
import '../loads/trips_api.dart';
import '../state/app_providers.dart';
import '../theme/app_colors.dart';
import '../widgets/app_nav_bar.dart';
import '../widgets/colombia_route_map.dart';

class TripsScreen extends ConsumerStatefulWidget {
  const TripsScreen({super.key, this.initialTab});

  final String? initialTab;

  @override
  ConsumerState<TripsScreen> createState() => _TripsScreenState();
}

class _TripsScreenState extends ConsumerState<TripsScreen> {
  int _selectedTabIndex = 0; // 0: Viajes Ofertados, 1: Viajes Asignados
  List<TripModel> _trips = [];
  List<BidModel> _bids = [];
  final Map<String, LoadModel> _loadDetails = {};
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.initialTab == 'activos') {
      _selectedTabIndex = 1;
    } else {
      _selectedTabIndex = 0;
    }
    _fetchAllData();
  }

  @override
  void didUpdateWidget(covariant TripsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialTab != oldWidget.initialTab && widget.initialTab != null) {
      setState(() {
        _selectedTabIndex = widget.initialTab == 'activos' ? 1 : 0;
      });
    }
  }

  Future<void> _fetchAllData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final auth = ref.read(authControllerProvider);
    final token = auth.accessToken;
    if (token == null) {
      setState(() {
        _isLoading = false;
        _error = 'Debes iniciar sesión para ver tus viajes y ofertas.';
      });
      return;
    }

    try {
      final tripsApi = TripsApi.fromEnvironment();
      final loadApi = LoadApi.fromEnvironment();

      // 1. Cargar viajes asignados
      final trips = await tripsApi.getMyTrips(accessToken: token);

      // 2. Cargar ofertas propias del conductor
      List<BidModel> bidsList = [];
      try {
        final myBids = await tripsApi.getMyBids(accessToken: token);
        bidsList.addAll(myBids);
      } catch (_) {}

      // 3. Cargar cargas de la empresa y ofertas recibidas
      try {
        final myLoads = await loadApi.getMyLoads(accessToken: token);
        for (final load in myLoads) {
          _loadDetails[load.id] = load;
          try {
            final loadBids = await tripsApi.getBidsForLoad(
              loadId: load.id,
              accessToken: token,
            );
            for (final b in loadBids) {
              if (!bidsList.any((existing) => existing.id == b.id)) {
                bidsList.add(b);
              }
            }
          } catch (_) {}
        }
      } catch (_) {}

      // 4. Asegurar que tenemos la información de origen/destino para cada oferta y viaje
      final neededLoadIds = <String>{
        ...bidsList.map((b) => b.loadId),
        ...trips.map((t) => t.loadId),
      };

      for (final loadId in neededLoadIds) {
        if (!_loadDetails.containsKey(loadId)) {
          try {
            final details = await loadApi.getLoadDetails(loadId);
            _loadDetails[loadId] = details;
          } catch (_) {}
        }
      }

      if (!mounted) return;
      setState(() {
        _trips = trips;
        _bids = bidsList;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = 'Error al cargar información: $e';
      });
    }
  }

  Future<void> _startTrip(TripModel trip) async {
    final auth = ref.read(authControllerProvider);
    final token = auth.accessToken;
    if (token == null) return;

    try {
      final api = TripsApi.fromEnvironment();
      await api.startTrip(tripId: trip.id, accessToken: token);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Viaje iniciado! Estado: EN TRÁNSITO.'),
          backgroundColor: AppColors.primary,
        ),
      );
      _fetchAllData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
      );
    }
  }

  Future<void> _deliverTrip(TripModel trip) async {
    final notesController = TextEditingController(
      text: 'Carga entregada en perfecto estado con acta firmada.',
    );

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar Entrega de Carga'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Ingresa las notas o evidencia de entrega para legalización:'),
            const SizedBox(height: 12),
            TextField(
              controller: notesController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Detalles del recibo, persona que recibe y documento',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.success),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirmar Entrega'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final auth = ref.read(authControllerProvider);
      final token = auth.accessToken;
      if (token == null) return;

      try {
        final api = TripsApi.fromEnvironment();
        await api.deliverTrip(
          tripId: trip.id,
          proofNotes: notesController.text.trim(),
          accessToken: token,
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Carga entregada y viaje completado con éxito!'),
            backgroundColor: AppColors.success,
          ),
        );
        _fetchAllData();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al entregar: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _acceptBid(BidModel bid) async {
    final auth = ref.read(authControllerProvider);
    final token = auth.accessToken;
    if (token == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar Adjudicación de Carga'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('¿Deseas adjudicar este viaje al conductor ${(bid.bidderName.isNotEmpty ? bid.bidderName : bid.bidderEmail)}?'),
            const SizedBox(height: 12),
            Text(
              'Valor de flete acordado: \$ ${bid.offeredAmount.toStringAsFixed(0)} COP',
              style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary),
            ),
            const SizedBox(height: 6),
            const Text(
              'Al aceptar, la carga pasará a estado ASIGNADO y se generará el viaje para seguimiento en vivo.',
              style: TextStyle(fontSize: 12.5, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.success),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Aceptar y Adjudicar'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final api = TripsApi.fromEnvironment();
      final trip = await api.acceptBid(bidId: bid.id, accessToken: token);
      if (!mounted) return;

      final load = _loadDetails[bid.loadId];

      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: AppColors.success, size: 28),
              SizedBox(width: 10),
              Text('¡Viaje Adjudicado con Éxito!'),
            ],
          ),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 580),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (load != null) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: ColombiaRouteMap(
                      originCity: load.originCity,
                      destinationCity: load.destinationCity,
                      originDepartment: load.originDepartment,
                      destinationDepartment: load.destinationDepartment,
                      height: 240,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                Text(
                  'El viaje #${trip.id.substring(0, 8)} ha sido creado para el transportista ${(bid.bidderName.isNotEmpty ? bid.bidderName : bid.bidderEmail)}.',
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
          actions: [
            FilledButton(
              onPressed: () {
                Navigator.pop(ctx);
                setState(() => _selectedTabIndex = 1);
              },
              child: const Text('Ver en Viajes Asignados'),
            ),
          ],
        ),
      );

      _fetchAllData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al adjudicar: $e'), backgroundColor: AppColors.error),
      );
    }
  }

  void _showRouteMapDialog({
    required String originCity,
    required String destinationCity,
    String? originDept,
    String? destinationDept,
    String? title,
  }) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.alt_route_rounded, color: AppColors.primary, size: 24),
            const SizedBox(width: 8),
            Text(title ?? 'Ruta Troncal Colombia'),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.close_rounded),
              onPressed: () => Navigator.pop(ctx),
            ),
          ],
        ),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720, maxHeight: 520),
          child: ColombiaRouteMap(
            originCity: originCity,
            destinationCity: destinationCity,
            originDepartment: originDept,
            destinationDepartment: destinationDept,
            height: 480,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final auth = ref.watch(authControllerProvider);
    final currentUserEmail = auth.user?.email ?? '';

    return Scaffold(
      appBar: AppNavBar(
        currentSection: _selectedTabIndex == 0 ? AppNavSection.bids : AppNavSection.trips,
        title: _selectedTabIndex == 0 ? 'Viajes Ofertados' : 'Mis Viajes',
        extraActions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _fetchAllData,
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1080),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Encabezado de la pantalla
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: isDark ? 0.2 : 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _selectedTabIndex == 0 ? Icons.local_offer_rounded : Icons.route_rounded,
                        color: AppColors.primary,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _selectedTabIndex == 0
                                ? 'Viajes Ofertados y Negociaciones'
                                : 'Monitoreo de Viajes y Envíos',
                            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          Text(
                            _selectedTabIndex == 0
                                ? 'Visualiza tus contraofertas enviadas, propuestas recibidas y mapa de ruta táctico.'
                                : 'Trazabilidad en tiempo real de fletes asignados, ejecución de ruta y legalización.',
                            style: theme.textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Selector de pestañas moderno (Tabs)
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurface : AppColors.lightSurfaceSubtle,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    ),
                  ),
                  padding: const EdgeInsets.all(4),
                  child: Row(
                    children: [
                      Expanded(
                        child: _TabButton(
                          label: 'Viajes Ofertados (${_bids.length})',
                          icon: Icons.local_offer_rounded,
                          isSelected: _selectedTabIndex == 0,
                          onTap: () => setState(() => _selectedTabIndex = 0),
                          isDark: isDark,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: _TabButton(
                          label: 'Viajes Asignados (${_trips.length})',
                          icon: Icons.route_rounded,
                          isSelected: _selectedTabIndex == 1,
                          onTap: () => setState(() => _selectedTabIndex = 1),
                          isDark: isDark,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Contenido dinámico según la pestaña
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
                                  FilledButton(
                                    onPressed: _fetchAllData,
                                    child: const Text('Reintentar'),
                                  ),
                                ],
                              ),
                            )
                          : _selectedTabIndex == 0
                              ? _buildBidsTab(isDark, currentUserEmail)
                              : _buildTripsTab(isDark),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBidsTab(bool isDark, String currentUserEmail) {
    if (_bids.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.local_offer_rounded, size: 48, color: AppColors.primary),
            ),
            const SizedBox(height: 18),
            const Text(
              'No tienes ofertas ni postulaciones activas',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'Explora las cargas disponibles en el tablero o publica una carga para recibir ofertas.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () => context.go('/cargas'),
              icon: const Icon(Icons.explore_rounded, size: 18),
              label: const Text('Ir a Cargas Disponibles'),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      itemCount: _bids.length,
      separatorBuilder: (ctx, i) => const SizedBox(height: 16),
      itemBuilder: (ctx, i) {
        final bid = _bids[i];
        final load = _loadDetails[bid.loadId];
        final isMySubmission = bid.bidderEmail == currentUserEmail;
        final isMyLoad = load != null && load.publisherEmail == currentUserEmail;

        return _BidCard(
          bid: bid,
          load: load,
          isMySubmission: isMySubmission,
          isMyLoad: isMyLoad,
          isDark: isDark,
          onViewMap: () {
            if (load != null) {
              _showRouteMapDialog(
                originCity: load.originCity,
                destinationCity: load.destinationCity,
                originDept: load.originDepartment,
                destinationDept: load.destinationDepartment,
                title: 'Ruta: ${load.originCity} ➔ ${load.destinationCity}',
              );
            } else {
              _showRouteMapDialog(
                originCity: 'Bogotá',
                destinationCity: 'Medellín',
                title: 'Ruta Bogotá ➔ Medellín',
              );
            }
          },
          onAccept: isMyLoad && bid.status == 'PENDING' ? () => _acceptBid(bid) : null,
        );
      },
    );
  }

  Widget _buildTripsTab(bool isDark) {
    if (_trips.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.tertiary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.route_rounded, size: 48, color: AppColors.tertiary),
            ),
            const SizedBox(height: 18),
            const Text(
              'No tienes viajes asignados en este momento',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'Cuando una empresa acepte una contraoferta o adjudiques una carga, el viaje aparecerá aquí.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () => setState(() => _selectedTabIndex = 0),
              icon: const Icon(Icons.local_offer_rounded, size: 18),
              label: const Text('Ver Viajes Ofertados'),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      itemCount: _trips.length,
      separatorBuilder: (ctx, i) => const SizedBox(height: 16),
      itemBuilder: (ctx, i) {
        final trip = _trips[i];
        final load = _loadDetails[trip.loadId];

        return _TripCard(
          trip: trip,
          load: load,
          onStart: () => _startTrip(trip),
          onDeliver: () => _deliverTrip(trip),
          onViewMap: () {
            if (load != null) {
              _showRouteMapDialog(
                originCity: load.originCity,
                destinationCity: load.destinationCity,
                originDept: load.originDepartment,
                destinationDept: load.destinationDepartment,
                title: 'Ruta del Viaje: ${load.originCity} ➔ ${load.destinationCity}',
              );
            } else {
              _showRouteMapDialog(
                originCity: 'Bogotá',
                destinationCity: 'Medellín',
                title: 'Ruta Bogotá ➔ Medellín',
              );
            }
          },
          isDark: isDark,
        );
      },
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
    required this.isDark,
  });

  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected
                  ? Colors.white
                  : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                fontSize: 14,
                color: isSelected
                    ? Colors.white
                    : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BidCard extends StatelessWidget {
  const _BidCard({
    required this.bid,
    required this.load,
    required this.isMySubmission,
    required this.isMyLoad,
    required this.isDark,
    required this.onViewMap,
    this.onAccept,
  });

  final BidModel bid;
  final LoadModel? load;
  final bool isMySubmission;
  final bool isMyLoad;
  final bool isDark;
  final VoidCallback onViewMap;
  final VoidCallback? onAccept;

  @override
  Widget build(BuildContext context) {
    Color statusColor = AppColors.warning;
    String statusText = 'PENDIENTE (En Negociación)';
    if (bid.status == 'ACCEPTED') {
      statusColor = AppColors.success;
      statusText = 'ACEPTADA (Adjudicada)';
    } else if (bid.status == 'REJECTED') {
      statusColor = AppColors.error;
      statusText = 'NO SELECCIONADA';
    }

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
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 11.5,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              if (isMySubmission)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Mi Contraoferta',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.blue),
                  ),
                ),
              if (isMyLoad)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.purple.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Oferta Recibida en mi Carga',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.purple),
                  ),
                ),
              const Spacer(),
              Text(
                '\$ ${bid.offeredAmount.toStringAsFixed(0)} COP',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Ruta Origen ➔ Destino
          if (load != null) ...[
            Row(
              children: [
                const Icon(Icons.trip_origin_rounded, size: 16, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  '${load!.originCity}, ${load!.originDepartment}',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                ),
                const SizedBox(width: 10),
                const Icon(Icons.arrow_forward_rounded, size: 16, color: Colors.grey),
                const SizedBox(width: 10),
                const Icon(Icons.location_on_rounded, size: 16, color: AppColors.secondary),
                const SizedBox(width: 8),
                Text(
                  '${load!.destinationCity}, ${load!.destinationDepartment}',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${load!.vehicleType} • ${load!.bodyType} • ${load!.weightKg.toStringAsFixed(0)} Kg de ${load!.productType}',
              style: TextStyle(
                fontSize: 12.5,
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              ),
            ),
          ] else ...[
            Text(
              'Carga ID: #${bid.loadId.substring(0, 8)}',
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
            ),
          ],

          const SizedBox(height: 12),

          // Calificación y reputación del conductor
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF162035) : AppColors.lightSurfaceSubtle,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                  child: Text(
                    ((bid.bidderName.isNotEmpty ? bid.bidderName : bid.bidderEmail)).substring(0, 1).toUpperCase(),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            (bid.bidderName.isNotEmpty ? bid.bidderName : bid.bidderEmail),
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                          ),
                          const SizedBox(width: 8),
                          const Row(
                            children: [
                              Icon(Icons.star_rounded, size: 14, color: Colors.amber),
                              SizedBox(width: 2),
                              Text(
                                '4.9',
                                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                              ),
                              SizedBox(width: 4),
                              Text(
                                '• 38 viajes',
                                style: TextStyle(fontSize: 11.5, color: Colors.grey),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const Row(
                        children: [
                          Icon(Icons.verified_rounded, size: 12, color: AppColors.success),
                          SizedBox(width: 4),
                          Text(
                            'Conductor Verificado RUNT • Póliza Vigente',
                            style: TextStyle(fontSize: 11, color: AppColors.success, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          if (bid.notes != null && bid.notes!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              'Observaciones: "${bid.notes}"',
              style: TextStyle(
                fontStyle: FontStyle.italic,
                fontSize: 12.5,
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              ),
            ),
          ],

          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 12),

          Row(
            children: [
              OutlinedButton.icon(
                onPressed: onViewMap,
                icon: const Icon(Icons.map_rounded, size: 18),
                label: const Text('Ver Ruta en Mapa'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                ),
              ),
              const Spacer(),
              if (onAccept != null)
                FilledButton.icon(
                  onPressed: onAccept,
                  icon: const Icon(Icons.check_circle_rounded, size: 18),
                  label: const Text('Aceptar Oferta y Adjudicar'),
                  style: FilledButton.styleFrom(backgroundColor: AppColors.success),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TripCard extends StatelessWidget {
  const _TripCard({
    required this.trip,
    required this.load,
    required this.onStart,
    required this.onDeliver,
    required this.onViewMap,
    required this.isDark,
  });

  final TripModel trip;
  final LoadModel? load;
  final VoidCallback onStart;
  final VoidCallback onDeliver;
  final VoidCallback onViewMap;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final isDelivered = trip.status == 'DELIVERED';
    final isInTransit = trip.status == 'IN_TRANSIT';

    Color statusColor = AppColors.warning;
    String statusLabel = 'ASIGNADO';
    if (isDelivered) {
      statusColor = AppColors.success;
      statusLabel = 'ENTREGADO / LEGALIZADO';
    } else if (isInTransit) {
      statusColor = AppColors.primary;
      statusLabel = 'EN TRÁNSITO';
    }

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
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 11.5,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Viaje #${trip.id.substring(0, 8)}',
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
              ),
              const Spacer(),
              Text(
                '\$ ${trip.agreedAmount.toStringAsFixed(0)} COP',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (load != null) ...[
            Row(
              children: [
                const Icon(Icons.trip_origin_rounded, size: 16, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  '${load!.originCity}, ${load!.originDepartment}',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                ),
                const SizedBox(width: 10),
                const Icon(Icons.arrow_forward_rounded, size: 16, color: Colors.grey),
                const SizedBox(width: 10),
                const Icon(Icons.location_on_rounded, size: 16, color: AppColors.secondary),
                const SizedBox(width: 8),
                Text(
                  '${load!.destinationCity}, ${load!.destinationDepartment}',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${load!.vehicleType} • ${load!.bodyType} • ${load!.weightKg.toStringAsFixed(0)} Kg',
              style: TextStyle(
                fontSize: 12.5,
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              ),
            ),
          ] else ...[
            Text(
              'Carga asociada: #${trip.loadId.substring(0, 8)}',
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
            ),
          ],

          if (trip.deliveryProofNotes != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF162035) : AppColors.lightSurfaceSubtle,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_rounded, size: 16, color: AppColors.success),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Acta / Evidencia: ${trip.deliveryProofNotes}',
                      style: const TextStyle(fontSize: 12.5),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 12),

          Row(
            children: [
              OutlinedButton.icon(
                onPressed: onViewMap,
                icon: const Icon(Icons.map_rounded, size: 18),
                label: const Text('Ver Ruta en Mapa'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                ),
              ),
              const Spacer(),
              if (trip.status == 'ASSIGNED')
                FilledButton.icon(
                  onPressed: onStart,
                  icon: const Icon(Icons.play_arrow_rounded, size: 18),
                  label: const Text('Iniciar Ruta (En Tránsito)'),
                  style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
                ),
              if (isInTransit)
                FilledButton.icon(
                  onPressed: onDeliver,
                  icon: const Icon(Icons.task_alt_rounded, size: 18),
                  label: const Text('Confirmar Entrega y Acta'),
                  style: FilledButton.styleFrom(backgroundColor: AppColors.success),
                ),
              if (isDelivered)
                OutlinedButton.icon(
                  onPressed: null,
                  icon: const Icon(Icons.verified_rounded, size: 18, color: AppColors.success),
                  label: const Text('Completado y Legalizado'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
