import 'package:google_sign_in/google_sign_in.dart';

/// Cliente de autenticación con Google para Flutter Web.
/// El Client ID se inyecta desde index.html mediante la meta tag
/// "google-signin-client_id", por lo que no se necesita pasar aquí.
class GoogleAuthClient {
  GoogleAuthClient._();

  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );

  /// Lanza el flujo de selección de cuenta de Google y devuelve
  /// el ID Token de Google (JWT firmado por Google) listo para
  /// enviarse al backend TRAXIA para su verificación.
  ///
  /// Devuelve `null` si el usuario cancela el flujo.
  static Future<String?> signIn() async {
    try {
      final account = await _googleSignIn.signIn();
      if (account == null) return null;

      final auth = await account.authentication;
      return auth.idToken;
    } catch (_) {
      return null;
    }
  }

  /// Cierra la sesión de Google (limpia la cuenta seleccionada).
  static Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
  }
}
