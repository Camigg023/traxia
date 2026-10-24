import 'package:dio/dio.dart';
import '../auth/auth_client_adapter_stub.dart'
    if (dart.library.js_interop) '../auth/auth_client_adapter_web.dart';
import 'load_models.dart';

class LoadApi {
  LoadApi(this._dio);

  factory LoadApi.fromEnvironment() {
    const configuredBaseUrl = String.fromEnvironment(
      'TRAXIA_API_BASE_URL',
      defaultValue: 'http://localhost:8080',
    );
    final baseUrl = configuredBaseUrl.replaceFirst(RegExp(r'/+$'), '');
    final adapter = createAuthHttpClientAdapter();

    return LoadApi(
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

  static const _loadsPath = '/api/v1/loads';
  final Dio _dio;

  Future<LoadModel> createLoad({
    required CreateLoadDto load,
    required String accessToken,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      _loadsPath,
      data: load.toJson(),
      options: Options(
        headers: {'Authorization': 'Bearer $accessToken'},
      ),
    );
    return LoadModel.fromJson(response.data!);
  }

  Future<List<LoadModel>> getMyLoads({required String accessToken}) async {
    final response = await _dio.get<List<dynamic>>(
      '$_loadsPath/my',
      options: Options(
        headers: {'Authorization': 'Bearer $accessToken'},
      ),
    );
    return (response.data ?? [])
        .map((item) => LoadModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<LoadModel>> searchLoads({
    String? originCity,
    String? destinationCity,
    String? vehicleType,
  }) async {
    final queryParams = <String, dynamic>{};
    if (originCity != null && originCity.isNotEmpty) {
      queryParams['originCity'] = originCity;
    }
    if (destinationCity != null && destinationCity.isNotEmpty) {
      queryParams['destinationCity'] = destinationCity;
    }
    if (vehicleType != null && vehicleType.isNotEmpty) {
      queryParams['vehicleType'] = vehicleType;
    }

    final response = await _dio.get<List<dynamic>>(
      _loadsPath,
      queryParameters: queryParams,
    );
    return (response.data ?? [])
        .map((item) => LoadModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<LoadModel> getLoadDetails(String publicId) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '$_loadsPath/$publicId',
    );
    return LoadModel.fromJson(response.data!);
  }
}
