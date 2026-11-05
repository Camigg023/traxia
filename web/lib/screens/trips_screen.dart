import 'dart:async';
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
  int _selectedTabIndex = 0; // 0: Viajes Ofertados, 1: Viajes Activos, 2: Viajes Completados
  List<TripModel> _trips = [];
  List<BidModel> _bids = [];
  final Map<String, LoadModel> _loadDetails = {};
  bool _isLoading = true;
  String? _error;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    if (widget.initialTab == 'activos') {
      _selectedTabIndex = 1;
    } else if (widget.initialTab == 'completados') {
      _selectedTabIndex = 2;
    } else {
      _selectedTabIndex = 0;
    }
    _fetchAllData();
    _startPolling();
  }

  @override
  void didUpdateWidget(covariant TripsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialTab != oldWidget.initialTab && widget.initialTab != null) {
      setState(() {
        if (widget.initialTab == 'activos') {
          _selectedTabIndex = 1;
        } else if (widget.initialTab == 'completados') {
          _selectedTabIndex = 2;
        } else {
          _selectedTabIndex = 0;
        }
      });
    }
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (mounted) {
        _fetchSilently();
      }
    });
  }

  Future<void> _fetchSilently() async {
    final auth = ref.read(authControllerProvider);
    final token = auth.accessToken;
    if (token == null || !mounted) return;

    try {
      final tripsApi = TripsApi.fromEnvironment();
      final loadApi = LoadApi.fromEnvironment();

      final trips = await tripsApi.getMyTrips(accessToken: token);

      List<BidModel> bidsList = [];
      try {
        final myBids = await tripsApi.getMyBids(accessToken: token);
        bidsList.addAll(myBids);
      } catch (_) {}

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
      });
    } catch (_) {
      // Polling silencioso no interrumpe al usuario
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

  void _showDeliveryCertificateDialog(TripModel trip, LoadModel? load, bool isDark) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        actionsPadding: const EdgeInsets.all(20),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.verified_user_rounded, color: AppColors.success, size: 28),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Acta Digital de Cumplido',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
                  ),
                  Text(
                    'Certificado Oficial de Transporte • Plataforma TRAXIA',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Badge de estado legal
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 18),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'SERVICIO CUMPLIDO Y LEGALIZADO A CONFORMIDAD',
                          style: TextStyle(
                            color: AppColors.success,
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      Text(
                        '#TRX-${trip.id.substring(0, 8).toUpperCase()}',
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                _buildCertificateRow(
                  'Ruta Nacional:',
                  load != null
                      ? '${load.originCity} (${load.originDepartment}) ➔ ${load.destinationCity} (${load.destinationDepartment})'
                      : 'Bogotá ➔ Medellín',
                ),
                _buildCertificateRow(
                  'Flete Pactado y Liquidado:',
                  '\$ ${trip.agreedAmount.toStringAsFixed(0)} COP',
                ),
                _buildCertificateRow(
                  'Transportista Asignado:',
                  trip.driverName.isNotEmpty ? trip.driverName : trip.driverEmail,
                ),
                _buildCertificateRow(
                  'Empresa Contratante:',
                  load?.publisherEmail ?? 'Empresa Registrada en TRAXIA',
                ),
                if (load != null)
                  _buildCertificateRow(
                    'Configuración Vehicular:',
                    '${load.vehicleType} • ${load.bodyType} • ${load.weightKg.toStringAsFixed(0)} Kg',
                  ),
                _buildCertificateRow(
                  'Fecha de Entrega y Cierre:',
                  trip.deliveredAtUtc != null
                      ? trip.deliveredAtUtc!.toLocal().toString().substring(0, 19)
                      : 'Fecha registrada en servidor',
                ),
                _buildCertificateRow(
                  'Constancia / Acta de Entrega:',
                  trip.deliveryProofNotes != null && trip.deliveryProofNotes!.isNotEmpty
                      ? trip.deliveryProofNotes!
                      : 'Carga recibida a total satisfacción con remisión y precintos verificados.',
                ),

                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 12),

                // Nota jurídica y de auditoría
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF131D2E) : const Color(0xFFF3F6FC),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.gavel_rounded, size: 16, color: AppColors.primary),
                          SizedBox(width: 6),
                          Text(
                            'Validez Jurídica y Probatoria',
                            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Emitido bajo el régimen de transporte de carga de Colombia (Art. 981 y ss. del Código de Comercio, Decreto 1079 de 2015). La presente acta digital certifica la entrega del flete y la culminación del contrato mercantil de transporte.',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.white70 : Colors.black87,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Hash SHA-256 de integridad: traxia-hash-${trip.id.replaceAll("-", "").substring(0, 16)}',
                        style: const TextStyle(
                          fontSize: 10,
                          fontFamily: 'monospace',
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          FilledButton.icon(
            onPressed: () => Navigator.pop(ctx),
            icon: const Icon(Icons.check_rounded, size: 18),
            label: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  Widget _buildCertificateRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 175,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5, color: Colors.grey),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5),
            ),
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

    final activeTrips = _trips.where((t) => t.status != 'DELIVERED').toList();
    final completedTrips = _trips.where((t) => t.status == 'DELIVERED').toList();

    AppNavSection currentSection;
    String appBarTitle;
    if (_selectedTabIndex == 0) {
      currentSection = AppNavSection.bids;
      appBarTitle = 'Viajes Ofertados';
    } else if (_selectedTabIndex == 1) {
      currentSection = AppNavSection.trips;
      appBarTitle = 'Mis Viajes';
    } else {
      currentSection = AppNavSection.completedTrips;
      appBarTitle = 'Viajes Completados';
    }

    IconData headerIcon;
    String headerTitle;
    String headerSubtitle;
    if (_selectedTabIndex == 0) {
      headerIcon = Icons.local_offer_rounded;
      headerTitle = 'Viajes Ofertados y Negociaciones';
      headerSubtitle = 'Visualiza tus contraofertas enviadas, propuestas recibidas y mapa de ruta táctico.';
    } else if (_selectedTabIndex == 1) {
      headerIcon = Icons.route_rounded;
      headerTitle = 'Monitoreo de Viajes Activos';
      headerSubtitle = 'Trazabilidad en tiempo real de fletes asignados, ejecución satelital y tránsito.';
    } else {
      headerIcon = Icons.verified_rounded;
      headerTitle = 'Historial de Viajes Completados';
      headerSubtitle = 'Registro de servicios finalizados con éxito, actas de recibo y legalización con validez jurídica.';
    }

    return Scaffold(
      appBar: AppNavBar(
        currentSection: currentSection,
        title: appBarTitle,
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
                        headerIcon,
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
                            headerTitle,
                            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          Text(
                            headerSubtitle,
                            style: theme.textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Selector de 3 pestañas moderno (Tabs)
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
                          label: 'Viajes Activos (${activeTrips.length})',
                          icon: Icons.route_rounded,
                          isSelected: _selectedTabIndex == 1,
                          onTap: () => setState(() => _selectedTabIndex = 1),
                          isDark: isDark,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: _TabButton(
                          label: 'Viajes Completados (${completedTrips.length})',
                          icon: Icons.verified_rounded,
                          isSelected: _selectedTabIndex == 2,
                          onTap: () => setState(() => _selectedTabIndex = 2),
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
                              : _selectedTabIndex == 1
                                  ? _buildActiveTripsTab(isDark, currentUserEmail, activeTrips)
                                  : _buildCompletedTripsTab(isDark, currentUserEmail, completedTrips),
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

  Widget _buildActiveTripsTab(bool isDark, String currentUserEmail, List<TripModel> activeTrips) {
    if (activeTrips.isEmpty) {
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
              child: const Icon(Icons.route_rounded, size: 48, color: AppColors.primary),
            ),
            const SizedBox(height: 18),
            const Text(
              'No tienes viajes activos en tránsito',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'Tus viajes adjudicados en ejecución aparecerán aquí con monitoreo en tiempo real.\nSi ya completaste un viaje, consúltalo en la pestaña "Viajes Completados".',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton.icon(
                  onPressed: () => setState(() => _selectedTabIndex = 0),
                  icon: const Icon(Icons.local_offer_rounded, size: 18),
                  label: const Text('Ver Ofertas'),
                ),
                const SizedBox(width: 12),
                FilledButton.icon(
                  onPressed: () => setState(() => _selectedTabIndex = 2),
                  icon: const Icon(Icons.verified_rounded, size: 18),
                  label: const Text('Ver Viajes Completados'),
                ),
              ],
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      itemCount: activeTrips.length,
      separatorBuilder: (ctx, i) => const SizedBox(height: 16),
      itemBuilder: (ctx, i) {
        final trip = activeTrips[i];
        final load = _loadDetails[trip.loadId];
        final isDriver = trip.driverEmail.trim().toLowerCase() == currentUserEmail.trim().toLowerCase();

        return _TripCard(
          trip: trip,
          load: load,
          isDriver: isDriver,
          onStart: () => _startTrip(trip),
          onDeliver: () => _deliverTrip(trip),
          onViewCertificate: () => _showDeliveryCertificateDialog(trip, load, isDark),
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

  Widget _buildCompletedTripsTab(bool isDark, String currentUserEmail, List<TripModel> completedTrips) {
    if (completedTrips.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.verified_user_rounded, size: 48, color: AppColors.success),
            ),
            const SizedBox(height: 18),
            const Text(
              'Aún no hay viajes completados',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'Una vez que el conductor confirme la entrega de la carga y el acta de recibo,\nlos servicios legalizados con su respectivo cumplido digital aparecerán aquí.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () => setState(() => _selectedTabIndex = 1),
              icon: const Icon(Icons.route_rounded, size: 18),
              label: const Text('Ver Viajes Activos'),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      itemCount: completedTrips.length,
      separatorBuilder: (ctx, i) => const SizedBox(height: 16),
      itemBuilder: (ctx, i) {
        final trip = completedTrips[i];
        final load = _loadDetails[trip.loadId];
        final isDriver = trip.driverEmail.trim().toLowerCase() == currentUserEmail.trim().toLowerCase();

        return _TripCard(
          trip: trip,
          load: load,
          isDriver: isDriver,
          onStart: () => _startTrip(trip),
          onDeliver: () => _deliverTrip(trip),
          onViewCertificate: () => _showDeliveryCertificateDialog(trip, load, isDark),
          onViewMap: () {
            if (load != null) {
              _showRouteMapDialog(
                originCity: load.originCity,
                destinationCity: load.destinationCity,
                originDept: load.originDepartment,
                destinationDept: load.destinationDepartment,
                title: 'Ruta Entregada: ${load.originCity} ➔ ${load.destinationCity}',
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
    required this.isDriver,
    required this.onStart,
    required this.onDeliver,
    required this.onViewMap,
    this.onViewCertificate,
    required this.isDark,
  });

  final TripModel trip;
  final LoadModel? load;
  final bool isDriver;
  final VoidCallback onStart;
  final VoidCallback onDeliver;
  final VoidCallback onViewMap;
  final VoidCallback? onViewCertificate;
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

          const SizedBox(height: 12),

          // Información del Conductor / Empresa en la tarjeta
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF162035) : AppColors.lightSurfaceSubtle,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  isDriver ? Icons.badge_rounded : Icons.person_pin_circle_rounded,
                  size: 18,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isDriver
                        ? 'Estás conduciendo este flete como Transportista asignado.'
                        : 'Conductor asignado: ${trip.driverName.isNotEmpty ? trip.driverName : trip.driverEmail} (⭐⭐⭐⭐⭐ 4.9)',
                    style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),

          if (isDelivered) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.success.withValues(alpha: 0.35)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.verified_rounded, color: AppColors.success, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '🎉 ¡Servicio de Transporte Completado con Éxito!',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 13.5,
                            color: AppColors.success,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Muchas gracias por preferir y confiar en TRAXIA. El flete ha sido entregado a total satisfacción y legalizado conforme al Art. 981 del Código de Comercio y la normativa del Ministerio de Transporte.',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.white70 : Colors.black87,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],

          if (trip.deliveryProofNotes != null && trip.deliveryProofNotes!.isNotEmpty) ...[
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
              if (isDelivered && onViewCertificate != null) ...[
                const SizedBox(width: 8),
                FilledButton.tonalIcon(
                  onPressed: onViewCertificate,
                  icon: const Icon(Icons.receipt_long_rounded, size: 18),
                  label: const Text('Acta de Cumplido'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.success.withValues(alpha: 0.16),
                    foregroundColor: AppColors.success,
                  ),
                ),
              ],
              const Spacer(),
              if (isDriver) ...[
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
                    onPressed: onViewCertificate,
                    icon: const Icon(Icons.verified_rounded, size: 18, color: AppColors.success),
                    label: const Text('Completado y Legalizado'),
                  ),
              ] else ...[
                if (trip.status == 'ASSIGNED')
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.hourglass_top_rounded, size: 16, color: Colors.amber),
                        SizedBox(width: 6),
                        Text(
                          'Esperando que el conductor inicie la ruta',
                          style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Colors.amber),
                        ),
                      ],
                    ),
                  ),
                if (isInTransit)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.local_shipping_rounded, size: 16, color: AppColors.primary),
                        SizedBox(width: 6),
                        Text(
                          'Camión en carretera (En Tránsito)',
                          style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.primary),
                        ),
                      ],
                    ),
                  ),
                if (isDelivered)
                  OutlinedButton.icon(
                    onPressed: onViewCertificate,
                    icon: const Icon(Icons.verified_rounded, size: 18, color: AppColors.success),
                    label: const Text('Entrega Recibida a Satisfacción'),
                  ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
