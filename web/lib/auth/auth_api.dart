import 'auth_client_adapter_stub.dart'
    if (dart.library.js_interop) 'auth_client_adapter_web.dart';
import 'package:dio/dio.dart';

import 'auth_models.dart';

class AuthApi {
  AuthApi(this._dio);

  factory AuthApi.fromEnvironment() {
    const configuredBaseUrl = String.fromEnvironment(
      'TRAXIA_API_BASE_URL',
      defaultValue: 'http://localhost:8080',
    );
    final baseUrl = configuredBaseUrl.replaceFirst(RegExp(r'/+$'), '');
    final adapter = createAuthHttpClientAdapter();

    return AuthApi(
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

  static const _authPath = '/api/v1/auth';
  static const _refreshRequestHeader = 'X-TRAXIA-Refresh-Request';

  final Dio _dio;

  Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '$_authPath/login',
      data: {'email': email.trim(), 'password': password},
    );
    return AuthResponse.fromJson(_requiredBody(response.data));
  }

  Future<String> register({
    required String displayName,
    required String email,
    required String password,
    required String profile,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '$_authPath/register',
      data: {
        'displayName': displayName.trim(),
        'email': email.trim(),
        'password': password,
        'profile': profile,
        'testNoticeAccepted': true,
      },
    );
    return _requiredMessage(response.data);
  }

  Future<String> verifyEmail(String token) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '$_authPath/verify-email',
      data: {'token': token},
    );
    return _requiredMessage(response.data);
  }

  Future<AuthResponse> refresh() async {
    final response = await _dio.post<Map<String, dynamic>>(
      '$_authPath/refresh',
      options: Options(
        headers: const {_refreshRequestHeader: 'true'},
      ),
    );
    return AuthResponse.fromJson(_requiredBody(response.data));
  }

  Future<MeResponse> me(String accessToken) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '$_authPath/me',
      options: Options(
        headers: {'Authorization': 'Bearer $accessToken'},
      ),
    );
    return MeResponse.fromJson(_requiredBody(response.data));
  }

  Future<void> logout() async {
    await _dio.post<void>(
      '$_authPath/logout',
      options: Options(
        headers: const {_refreshRequestHeader: 'true'},
      ),
    );
  }

  String messageFor(DioException exception) {
    final responseData = exception.response?.data;
    if (responseData is Map<String, dynamic>) {
      final detail = responseData['detail'];
      if (detail is String && detail.isNotEmpty) {
        return detail;
      }
    }

    if (exception.response == null) {
      return 'No fue posible conectar con TRAXIA. Verifica que el backend esté iniciado.';
    }
    return 'No fue posible completar la solicitud. Inténtalo de nuevo.';
  }

  Map<String, dynamic> _requiredBody(Map<String, dynamic>? body) {
    if (body == null) {
      throw const FormatException('El servidor devolvió una respuesta vacía.');
    }
    return body;
  }

  String _requiredMessage(Map<String, dynamic>? body) {
    final message = _requiredBody(body)['message'];
    if (message is! String || message.isEmpty) {
      throw const FormatException(
          'El servidor devolvió una respuesta no válida.');
    }
    return message;
  }
}
