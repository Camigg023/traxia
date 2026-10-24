import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../loads/bids_trips_models.dart';
import '../loads/trips_api.dart';
import '../state/app_providers.dart';
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
        const SnackBar(content: Text('¡Viaje iniciado! Estado: EN TRÁNSITO.'), backgroundColor: Colors.blue),
      );
      _fetchTrips();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
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
            const Text('Ingresa las notas o evidencia de entrega:'),
            const SizedBox(height: 12),
            TextField(
              controller: notesController,
              maxLines: 3,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Detalles del recibo o persona que recibe',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Confirmar Entrega')),
        ],
      ),
    );

    if (confirmed == true && mounted) {
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
          const SnackBar(content: Text('¡Carga entregada y finalizada con éxito!'), backgroundColor: Colors.green),
        );
        _fetchTrips();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppNavBar(
        currentSection: AppNavSection.trips,
        title: 'Mis Viajes',
        extraActions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchTrips,
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 960),
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? Center(child: Text(_error!, style: const TextStyle(color: Colors.red)))
                  : _trips.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.route_outlined, size: 64, color: Colors.grey),
                              const SizedBox(height: 16),
                              const Text('No tienes viajes activos o finalizados todavía.',
                                  style: TextStyle(fontSize: 16, color: Colors.grey)),
                              const SizedBox(height: 16),
                              FilledButton.icon(
                                onPressed: () => context.go('/cargas'),
                                icon: const Icon(Icons.search),
                                label: const Text('Buscar cargas para postularme'),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _trips.length,
                          itemBuilder: (context, index) {
                            return _buildTripCard(_trips[index]);
                          },
                        ),
        ),
      ),
    );
  }

  Widget _buildTripCard(TripModel trip) {
    Color statusColor;
    String statusLabel;
    IconData statusIcon;

    switch (trip.status) {
      case 'ASSIGNED':
        statusColor = Colors.orange;
        statusLabel = 'Asignado (Pendiente de inicio)';
        statusIcon = Icons.assignment_turned_in_outlined;
        break;
      case 'IN_TRANSIT':
        statusColor = Colors.blue;
        statusLabel = 'En Tránsito (En ruta)';
        statusIcon = Icons.local_shipping;
        break;
      case 'DELIVERED':
        statusColor = Colors.green;
        statusLabel = 'Entregado (Completado)';
        statusIcon = Icons.check_circle_outline;
        break;
      default:
        statusColor = Colors.grey;
        statusLabel = trip.status;
        statusIcon = Icons.info_outline;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(statusIcon, color: statusColor),
                    const SizedBox(width: 8),
                    Text(
                      statusLabel,
                      style: TextStyle(fontWeight: FontWeight.bold, color: statusColor, fontSize: 16),
                    ),
                  ],
                ),
                Text(
                  '\$ ${trip.agreedAmount.toStringAsFixed(0)} COP',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text('Conductor: ${trip.driverName} (${trip.driverEmail})'),
            Text('Referencia Carga: #${trip.loadId.substring(0, 8)}'),
            if (trip.deliveryProofNotes != null && trip.deliveryProofNotes!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('Soporte de entrega: ${trip.deliveryProofNotes}',
                    style: TextStyle(color: Colors.green.shade900)),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (trip.status == 'ASSIGNED')
                  FilledButton.icon(
                    onPressed: () => _startTrip(trip),
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Iniciar Viaje'),
                  ),
                if (trip.status == 'IN_TRANSIT')
                  FilledButton.icon(
                    style: FilledButton.styleFrom(backgroundColor: Colors.green),
                    onPressed: () => _deliverTrip(trip),
                    icon: const Icon(Icons.done_all),
                    label: const Text('Confirmar Entrega'),
                  ),
                if (trip.status == 'DELIVERED')
                  const Text('✅ Operación cerrada con éxito',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
