import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

class GoogleAuthResult {
  const GoogleAuthResult({
    this.idToken,
    this.errorMessage,
    this.wasCancelled = false,
  });

  final String? idToken;
  final String? errorMessage;
  final bool wasCancelled;

  bool get isSuccess => idToken != null && idToken!.isNotEmpty;
}

/// Cliente de autenticación con Google para Flutter Web.
class GoogleAuthClient {
  GoogleAuthClient._();

  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );

  /// Lanza el flujo de selección de cuenta de Google.
  static Future<GoogleAuthResult> signIn() async {
    try {
      final account = await _googleSignIn.signIn();
      if (account == null) {
        return const GoogleAuthResult(wasCancelled: true);
      }

      final auth = await account.authentication;
      if (auth.idToken == null || auth.idToken!.isEmpty) {
        return const GoogleAuthResult(
          errorMessage: 'Google no devolvió el token de acceso. Intenta de nuevo.',
        );
      }

      return GoogleAuthResult(idToken: auth.idToken);
    } catch (e) {
      debugPrint('Error en Google Sign-In: $e');
      final errorStr = e.toString();
      if (errorStr.contains('popup_closed_by_user')) {
        return const GoogleAuthResult(wasCancelled: true);
      }
      return const GoogleAuthResult(
        errorMessage:
            'Para usar Google debes autorizar https://traxia-one.vercel.app en Google Cloud Console. Por favor ingresa o regístrate con tu correo y contraseña.',
      );
    }
  }

  /// Cierra la sesión de Google (limpia la cuenta seleccionada).
  static Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
  }
}
