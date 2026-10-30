import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../loads/bids_trips_models.dart';
import '../loads/trips_api.dart';
import '../state/app_providers.dart';
import '../theme/app_colors.dart';
import '../widgets/app_nav_bar.dart';

class TripsScreen extends ConsumerStatefulWidget {
  const TripsScreen({super.key});

  @override
  ConsumerState<TripsScreen> createState() => _TripsScreenState();
}

class _TripsScreenState extends ConsumerState<TripsScreen> {
  List<TripModel> _trips = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchTrips();
  }

  Future<void> _fetchTrips() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final auth = ref.read(authControllerProvider);
    final token = auth.accessToken;
    if (token == null) {
      setState(() {
        _isLoading = false;
        _error = 'Debes iniciar sesión para ver tus viajes.';
      });
      return;
    }

    try {
      final api = TripsApi.fromEnvironment();
      final results = await api.getMyTrips(accessToken: token);
      if (!mounted) return;
      setState(() {
        _trips = results;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = 'Error al cargar viajes: $e';
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
      _fetchTrips();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
      );
    }
  }

  Future<void> _deliverTrip(TripModel trip) async {
    final notesController = TextEditingController(text: 'Carga entregada en perfecto estado con acta firmada.');

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
        _fetchTrips();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al entregar: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppNavBar(
        currentSection: AppNavSection.trips,
        title: 'Mis Viajes',
        extraActions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _fetchTrips,
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
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.tertiary.withValues(alpha: isDark ? 0.2 : 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.route_rounded, color: AppColors.tertiary, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Monitoreo de Viajes y Envíos',
                          style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        Text(
                          'Trazabilidad en tiempo real de fletes asignados, ejecución de ruta y legalización.',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),
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
                                  FilledButton(onPressed: _fetchTrips, child: const Text('Reintentar')),
                                ],
                              ),
                            )
                          : _trips.isEmpty
                              ? _buildEmptyState(isDark)
                              : ListView.separated(
                                  itemCount: _trips.length,
                                  separatorBuilder: (ctx, i) => const SizedBox(height: 16),
                                  itemBuilder: (ctx, i) {
                                    final trip = _trips[i];
                                    return _TripCard(
                                      trip: trip,
                                      onStart: () => _startTrip(trip),
                                      onDeliver: () => _deliverTrip(trip),
                                      isDark: isDark,
                                    );
                                  },
                                ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
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
            'Explora las cargas disponibles en el tablero y postula tu oferta comercial.',
            style: TextStyle(
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: () => context.go('/cargas'),
            icon: const Icon(Icons.explore_rounded, size: 18),
            label: const Text('Ver Cargas Disponibles'),
          ),
        ],
      ),
    );
  }
}

class _TripCard extends StatelessWidget {
  const _TripCard({
    required this.trip,
    required this.onStart,
    required this.onDeliver,
    required this.isDark,
  });

  final TripModel trip;
  final VoidCallback onStart;
  final VoidCallback onDeliver;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final isDelivered = trip.status == 'DELIVERED';
    final isInTransit = trip.status == 'IN_TRANSIT';

    Color statusColor = AppColors.warning;
    if (isDelivered) statusColor = AppColors.success;
    if (isInTransit) statusColor = AppColors.primary;

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
                  trip.status,
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
          Row(
            children: [
              const Icon(Icons.location_on_rounded, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Carga asociada: ${trip.loadId}',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                ),
              ),
            ],
          ),
          if (trip.deliveryProofNotes != null) ...[
            const SizedBox(height: 8),
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
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
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
