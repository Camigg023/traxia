import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'auth_api.dart';
import 'auth_models.dart';

enum AuthStatus { restoring, signedOut, signedIn, unavailable }

class AuthController extends ChangeNotifier {
  AuthController(this._api);

  final AuthApi _api;

  AuthStatus status = AuthStatus.restoring;
  AuthUser? user;
  String? accessToken;
  String? message;
  bool isSubmitting = false;

  Future<void> restoreSession() async {
    try {
      final refreshed = await _api.refresh();
      final currentUser = await _api.me(refreshed.accessToken);
      _setAuthenticated(refreshed.accessToken, currentUser.user);
    } on DioException catch (exception) {
      if (exception.response?.statusCode == 401) {
        _setSignedOut();
      } else {
        _setUnavailable(_api.messageFor(exception));
      }
    } on FormatException {
      _setUnavailable('El servidor devolvió una respuesta de sesión no válida.');
    }
  }

  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    isSubmitting = true;
    message = null;
    notifyListeners();

    try {
      final response = await _api.login(email: email, password: password);
      _setAuthenticated(response.accessToken, response.user);
      return true;
    } on DioException catch (exception) {
      message = _api.messageFor(exception);
      return false;
    } on FormatException {
      message = 'El servidor devolvió una respuesta de inicio de sesión no válida.';
      return false;
    } finally {
      isSubmitting = false;
      notifyListeners();
    }
  }

  Future<bool> signOut() async {
    if (accessToken == null) {
      return false;
    }

    isSubmitting = true;
    message = null;
    notifyListeners();
    try {
      await _api.logout();
      _setSignedOut();
      return true;
    } on DioException catch (exception) {
      message = _api.messageFor(exception);
      return false;
    } finally {
      isSubmitting = false;
      notifyListeners();
    }
  }

  void clearMessage() {
    message = null;
    notifyListeners();
  }

  void _setAuthenticated(String token, AuthUser authenticatedUser) {
    accessToken = token;
    user = authenticatedUser;
    status = AuthStatus.signedIn;
    message = null;
    notifyListeners();
  }

  void _setSignedOut() {
    accessToken = null;
    user = null;
    status = AuthStatus.signedOut;
    message = null;
    notifyListeners();
  }

  void _setUnavailable(String errorMessage) {
    status = AuthStatus.unavailable;
    message = errorMessage;
    notifyListeners();
  }
}
