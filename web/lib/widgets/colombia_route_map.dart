import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../theme/app_colors.dart';

/// Mapa interactivo de Colombia para trazado de rutas troncales punto a punto (Punto A -> Punto B).
/// Utiliza OpenStreetMap de forma 100% abierta y gratuita, sin requerir API keys ni cobros.
class ColombiaRouteMap extends StatefulWidget {
  const ColombiaRouteMap({
    super.key,
    required this.originCity,
    required this.destinationCity,
    this.originDepartment,
    this.destinationDepartment,
    this.height = 360,
    this.distanceKm,
    this.estimatedTolls,
  });

  final String originCity;
  final String destinationCity;
  final String? originDepartment;
  final String? destinationDepartment;
  final double height;
  final String? distanceKm;
  final int? estimatedTolls;

  @override
  State<ColombiaRouteMap> createState() => _ColombiaRouteMapState();
}

class _ColombiaRouteMapState extends State<ColombiaRouteMap> {
  late final MapController _mapController;

  static const LatLng _colombiaCenter = LatLng(4.570868, -74.297333);
  static const double _colombiaZoom = 5.5;

  late LatLng _pointA;
  late LatLng _pointB;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _resolvePoints();
  }

  @override
  void didUpdateWidget(covariant ColombiaRouteMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.originCity != widget.originCity ||
        oldWidget.destinationCity != widget.destinationCity) {
      _resolvePoints();
      _fitRoute();
    }
  }

  void _resolvePoints() {
    _pointA = _getCoordinates(widget.originCity, widget.originDepartment);
    _pointB = _getCoordinates(widget.destinationCity, widget.destinationDepartment);
  }

  void _fitRoute() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      try {
        final bounds = LatLngBounds.fromPoints([_pointA, _pointB]);
        _mapController.fitCamera(
          CameraFit.bounds(
            bounds: bounds,
            padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 60),
          ),
        );
      } catch (_) {}
    });
  }

  void _resetToColombia() {
    _mapController.move(_colombiaCenter, _colombiaZoom);
  }

  /// Diccionario de coordenadas de las principales ciudades y cabeceras de Colombia
  static LatLng _getCoordinates(String city, String? department) {
    final cleanCity = city.trim().toLowerCase();
    final cleanDept = (department ?? '').trim().toLowerCase();

    // Antioquia y Valle de Aburrá
    if (cleanCity.contains('medellin') || cleanCity.contains('medellín')) return const LatLng(6.2442, -75.5812);
    if (cleanCity.contains('sabaneta')) return const LatLng(6.1513, -75.6166);
    if (cleanCity.contains('envigado')) return const LatLng(6.1759, -75.5917);
    if (cleanCity.contains('bello')) return const LatLng(6.3373, -75.5579);
    if (cleanCity.contains('rionegro')) return const LatLng(6.1539, -75.3742);

    // Cundinamarca y Bogotá D.C.
    if (cleanCity.contains('bogota') || cleanCity.contains('bogotá') || cleanCity.contains('cundinamarca')) {
      return const LatLng(4.7110, -74.0721);
    }
    if (cleanCity.contains('soacha')) return const LatLng(4.5794, -74.2169);
    if (cleanCity.contains('facatativa') || cleanCity.contains('facatativá')) return const LatLng(4.8144, -74.3547);
    if (cleanCity.contains('zipaquira') || cleanCity.contains('zipaquirá')) return const LatLng(5.0267, -74.0039);

    // Valle del Cauca y Pacífico
    if (cleanCity.contains('cali')) return const LatLng(3.4516, -76.5320);
    if (cleanCity.contains('buenaventura')) return const LatLng(3.8833, -77.0333);
    if (cleanCity.contains('palmira')) return const LatLng(3.5394, -76.3036);
    if (cleanCity.contains('tuluá') || cleanCity.contains('tulua')) return const LatLng(4.0847, -76.1954);

    // Caribe Colombiano
    if (cleanCity.contains('barranquilla') || cleanCity.contains('atlantico') || cleanCity.contains('atlántico')) {
      return const LatLng(10.9685, -74.7813);
    }
    if (cleanCity.contains('cartagena') || cleanCity.contains('bolivar') || cleanCity.contains('bolívar')) {
      return const LatLng(10.3910, -75.4794);
    }
    if (cleanCity.contains('santa marta') || cleanCity.contains('magdalena')) return const LatLng(11.2408, -74.1990);
    if (cleanCity.contains('valledupar') || cleanCity.contains('cesar')) return const LatLng(10.4631, -73.2532);
    if (cleanCity.contains('monteria') || cleanCity.contains('montería') || cleanCity.contains('cordoba')) {
      return const LatLng(8.7479, -75.8814);
    }
    if (cleanCity.contains('sincelejo') || cleanCity.contains('sucre')) return const LatLng(9.3047, -75.3978);
    if (cleanCity.contains('riohacha') || cleanCity.contains('guajira')) return const LatLng(11.5444, -72.9072);

    // Santanderes
    if (cleanCity.contains('bucaramanga') || cleanCity.contains('santander')) return const LatLng(7.1254, -73.1198);
    if (cleanCity.contains('cucuta') || cleanCity.contains('cúcuta')) return const LatLng(7.8939, -72.5078);
    if (cleanCity.contains('barrancabermeja')) return const LatLng(7.0653, -73.8547);

    // Eje Cafetero y Tolima
    if (cleanCity.contains('pereira') || cleanCity.contains('risaralda')) return const LatLng(4.8133, -75.6961);
    if (cleanCity.contains('manizales') || cleanCity.contains('caldas')) return const LatLng(5.0689, -75.5174);
    if (cleanCity.contains('armenia') || cleanCity.contains('quindio') || cleanCity.contains('quindío')) {
      return const LatLng(4.5339, -75.6811);
    }
    if (cleanCity.contains('ibague') || cleanCity.contains('ibagué') || cleanCity.contains('tolima')) {
      return const LatLng(4.4389, -75.2322);
    }

    // Llanos Orientales y Amazonía / Orinoquía
    if (cleanCity.contains('villavicencio') || cleanCity.contains('meta')) return const LatLng(4.1420, -73.6266);
    // Amazonia y Fronteras (Leticia, Mocoa, San Jose, etc.)
    if (cleanCity.contains('leticia') || cleanCity.contains('amazonas') || cleanDept.contains('amazonas')) {
      return const LatLng(-4.2153, -69.9406);
    }
    if (cleanCity.contains('mitu') || cleanDept.contains('vaupes')) return const LatLng(1.2519, -70.2333);
    if (cleanCity.contains('inirida') || cleanDept.contains('guainia')) return const LatLng(3.8653, -67.9239);
    if (cleanCity.contains('guaviare')) return const LatLng(2.5729, -72.6459);
    if (cleanCity.contains('carreno') || cleanDept.contains('vichada')) return const LatLng(6.1890, -67.4859);
    if (cleanCity.contains('arauca')) return const LatLng(7.0847, -70.7591);
    if (cleanCity.contains('mocoa') || cleanCity.contains('putumayo') || cleanDept.contains('putumayo')) {
      return const LatLng(1.1528, -76.6521);
    }

    if (cleanCity.contains('yopal') || cleanCity.contains('casanare')) return const LatLng(5.3378, -72.3959);
    if (cleanCity.contains('florencia') || cleanCity.contains('caqueta') || cleanCity.contains('caquetá')) {
      return const LatLng(1.6144, -75.6062);
    }

    // Sur (Huila, Nariño, Cauca)
    if (cleanCity.contains('neiva') || cleanCity.contains('huila')) return const LatLng(2.9273, -75.2819);
    if (cleanCity.contains('pasto') || cleanCity.contains('nariño')) return const LatLng(1.2136, -77.2811);
    if (cleanCity.contains('popayan') || cleanCity.contains('popayán') || cleanCity.contains('cauca')) {
      return const LatLng(2.4448, -76.6147);
    }
    if (cleanCity.contains('tunja') || cleanCity.contains('boyaca') || cleanCity.contains('boyacá')) {
      return const LatLng(5.5353, -73.3678);
    }
    if (cleanCity.contains('quibdo') || cleanCity.contains('quibdó') || cleanCity.contains('choco')) {
      return const LatLng(5.6919, -76.6583);
    }

    // Fallback por departamento
    if (cleanDept.contains('antioquia')) return const LatLng(6.2442, -75.5812);
    if (cleanDept.contains('cundinamarca')) return const LatLng(4.7110, -74.0721);
    if (cleanDept.contains('valle')) return const LatLng(3.4516, -76.5320);

    return const LatLng(4.7110, -74.0721);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final hasSamePoints = (_pointA.latitude == _pointB.latitude && _pointA.longitude == _pointB.longitude);

    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            // Mapa base con OpenStreetMap
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _pointA,
                initialZoom: 7.0,
                onMapReady: _fitRoute,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.traxia.web',
                ),
                // Línea de ruta (Punto A -> Punto B) al estilo trazado táctico rojo
                if (!hasSamePoints)
                  PolylineLayer(
                    polylines: [
                      // Línea base con sombra negra suave
                      Polyline(
                        points: [_pointA, _pointB],
                        strokeWidth: 6.0,
                        color: Colors.black.withValues(alpha: 0.35),
                      ),
                      // Línea de ruta roja visible tipo GPS
                      Polyline(
                        points: [_pointA, _pointB],
                        strokeWidth: 4.5,
                        color: const Color(0xFFE53935),
                        pattern: StrokePattern.dashed(segments: const [12, 6]),
                      ),
                    ],
                  ),
                // Marcadores Punto A (Origen) y Punto B (Destino)
                MarkerLayer(
                  markers: [
                    // PIN ORIGEN (A)
                    Marker(
                      point: _pointA,
                      width: 50,
                      height: 56,
                      alignment: Alignment.topCenter,
                      child: _PinMarker(
                        label: 'A',
                        cityName: widget.originCity,
                        color: const Color(0xFFD32F2F), // Rojo intenso estilo GTA/Google
                      ),
                    ),
                    // PIN DESTINO (B)
                    if (!hasSamePoints)
                      Marker(
                        point: _pointB,
                        width: 50,
                        height: 56,
                        alignment: Alignment.topCenter,
                        child: _PinMarker(
                          label: 'B',
                          cityName: widget.destinationCity,
                          color: const Color(0xFFB71C1C), // Rojo oscuro
                        ),
                      ),
                  ],
                ),
              ],
            ),

            // Encabezado flotante sobre el mapa con detalles de la ruta
            Positioned(
              top: 14,
              left: 14,
              right: 14,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: (isDark ? const Color(0xFF0F172A) : Colors.white).withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE53935).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.alt_route_rounded,
                        color: Color(0xFFE53935),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Text(
                                widget.originCity.toUpperCase(),
                                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                              ),
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 6),
                                child: Icon(Icons.arrow_forward_rounded, size: 14, color: Color(0xFFE53935)),
                              ),
                              Text(
                                widget.destinationCity.toUpperCase(),
                                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                              ),
                            ],
                          ),
                          Text(
                            widget.distanceKm != null
                                ? 'Troncal Nacional • ${widget.distanceKm} ${widget.estimatedTolls != null ? '• ${widget.estimatedTolls} Peajes' : ''}'
                                : 'Corredor Logístico Nacional (OpenStreetMap)',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Botón para centrar en la ruta
                    IconButton(
                      tooltip: 'Centrar en la ruta (A ➔ B)',
                      icon: const Icon(Icons.center_focus_strong_rounded, size: 20),
                      onPressed: _fitRoute,
                    ),
                    // Botón para ver toda Colombia
                    IconButton(
                      tooltip: 'Ver toda Colombia',
                      icon: const Icon(Icons.public_rounded, size: 20),
                      onPressed: _resetToColombia,
                    ),
                  ],
                ),
              ),
            ),

            // Controles de zoom abajo a la derecha
            Positioned(
              bottom: 14,
              right: 14,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _MapControlButton(
                    icon: Icons.add_rounded,
                    tooltip: 'Acercar',
                    onTap: () {
                      _mapController.move(_mapController.camera.center, _mapController.camera.zoom + 0.8);
                    },
                  ),
                  const SizedBox(height: 6),
                  _MapControlButton(
                    icon: Icons.remove_rounded,
                    tooltip: 'Alejar',
                    onTap: () {
                      _mapController.move(_mapController.camera.center, _mapController.camera.zoom - 0.8);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Pin rojo clásico con círculo interior blanco (como en GTA / Google Maps)
class _PinMarker extends StatelessWidget {
  const _PinMarker({
    required this.label,
    required this.cityName,
    required this.color,
  });

  final String label;
  final String cityName;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            Icon(
              Icons.location_on_rounded,
              size: 44,
              color: color,
              shadows: const [
                Shadow(
                  color: Colors.black45,
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            Positioned(
              top: 7,
              child: Container(
                width: 14,
                height: 14,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w900,
                    fontSize: 9,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _MapControlButton extends StatelessWidget {
  const _MapControlButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: (isDark ? const Color(0xFF1E293B) : Colors.white).withValues(alpha: 0.9),
      borderRadius: BorderRadius.circular(8),
      elevation: 3,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Tooltip(
          message: tooltip,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Icon(icon, size: 20),
          ),
        ),
      ),
    );
  }
}
