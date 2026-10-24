import 'package:flutter_test/flutter_test.dart';
import 'package:traxia_web/auth/auth_models.dart';

void main() {
  test('lee el usuario de la respuesta de autenticación del backend', () {
    final response = AuthResponse.fromJson({
      'accessToken': 'token-de-prueba',
      'tokenType': 'Bearer',
      'expiresInSeconds': 600,
      'user': {
        'id': '0ef38afd-04d8-4bdd-b67e-8fc6830d36e0',
        'email': 'persona@example.test',
        'roles': ['ADMIN'],
      },
    });

    expect(response.accessToken, 'token-de-prueba');
    expect(response.user.email, 'persona@example.test');
    expect(response.user.roles, ['ADMIN']);
  });

  test('no admite roles mal formados en la respuesta de sesión', () {
    expect(
      () => MeResponse.fromJson({
        'id': '0ef38afd-04d8-4bdd-b67e-8fc6830d36e0',
        'email': 'persona@example.test',
        'roles': 'ADMIN',
      }),
      throwsFormatException,
    );
  });
}
