import 'package:dio/dio.dart';
import '../auth/auth_client_adapter_stub.dart'
    if (dart.library.js_interop) '../auth/auth_client_adapter_web.dart';
import 'bids_trips_models.dart';

class TripsApi {
  TripsApi(this._dio);

  factory TripsApi.fromEnvironment() {
    const configuredBaseUrl = String.fromEnvironment(
      'TRAXIA_API_BASE_URL',
      defaultValue: 'http://localhost:8080',
    );
    final baseUrl = configuredBaseUrl.replaceFirst(RegExp(r'/+$'), '');
    final adapter = createAuthHttpClientAdapter();

    return TripsApi(
      Dio(
        BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 15),
          headers: const {'Content-Type': 'application/json'},
        ),
      )..httpClientAdapter = adapter,
    );
  }

  final Dio _dio;

  Future<RouteSimulationModel> simulateRoute(String loadId) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/v1/loads/$loadId/simulate',
    );
    return RouteSimulationModel.fromJson(response.data!);
  }

  Future<BidModel> createBid({
    required String loadId,
    required double offeredAmount,
    DateTime? proposedPickupDate,
    String? notes,
    required String accessToken,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/v1/loads/$loadId/bids',
      data: {
        'offeredAmount': offeredAmount,
        if (proposedPickupDate != null)
          'proposedPickupDateUtc': proposedPickupDate.toUtc().toIso8601String(),
        if (notes != null && notes.isNotEmpty) 'notes': notes,
      },
      options: Options(
        headers: {'Authorization': 'Bearer $accessToken'},
      ),
    );
    return BidModel.fromJson(response.data!);
  }

  Future<List<BidModel>> getBidsForLoad({
    required String loadId,
    required String accessToken,
  }) async {
    final response = await _dio.get<List<dynamic>>(
      '/api/v1/loads/$loadId/bids',
      options: Options(
        headers: {'Authorization': 'Bearer $accessToken'},
      ),
    );
    return (response.data ?? [])
        .map((item) => BidModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<TripModel> acceptBid({
    required String bidId,
    required String accessToken,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/v1/bids/$bidId/accept',
      options: Options(
        headers: {'Authorization': 'Bearer $accessToken'},
      ),
    );
    return TripModel.fromJson(response.data!);
  }

  Future<List<TripModel>> getMyTrips({required String accessToken}) async {
    final response = await _dio.get<List<dynamic>>(
      '/api/v1/trips/my',
      options: Options(
        headers: {'Authorization': 'Bearer $accessToken'},
      ),
    );
    return (response.data ?? [])
        .map((item) => TripModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<TripModel> startTrip({
    required String tripId,
    required String accessToken,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/v1/trips/$tripId/start',
      options: Options(
        headers: {'Authorization': 'Bearer $accessToken'},
      ),
    );
    return TripModel.fromJson(response.data!);
  }

  Future<TripModel> deliverTrip({
    required String tripId,
    String? proofNotes,
    required String accessToken,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/v1/trips/$tripId/deliver',
      data: {
        'proofNotes': proofNotes ?? 'Entrega completada y verificada.',
      },
      options: Options(
        headers: {'Authorization': 'Bearer $accessToken'},
      ),
    );
    return TripModel.fromJson(response.data!);
  }
}
