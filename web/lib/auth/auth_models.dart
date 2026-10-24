class AuthUser {
  const AuthUser({
    required this.id,
    required this.email,
    required this.roles,
  });

  final String id;
  final String email;
  final List<String> roles;

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    final roles = json['roles'];
    if (roles is! List<dynamic> || roles.any((role) => role is! String)) {
      throw const FormatException('La respuesta del servidor no incluye roles válidos.');
    }

    return AuthUser(
      id: _requiredString(json, 'id'),
      email: _requiredString(json, 'email'),
      roles: List.unmodifiable(roles.cast<String>()),
    );
  }
}

class AuthResponse {
  const AuthResponse({
    required this.accessToken,
    required this.tokenType,
    required this.expiresInSeconds,
    required this.user,
  });

  final String accessToken;
  final String tokenType;
  final int expiresInSeconds;
  final AuthUser user;

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      accessToken: _requiredString(json, 'accessToken'),
      tokenType: _requiredString(json, 'tokenType'),
      expiresInSeconds: _requiredInt(json, 'expiresInSeconds'),
      user: AuthUser.fromJson(_requiredMap(json, 'user')),
    );
  }
}

class MeResponse {
  const MeResponse._(this.user);

  final AuthUser user;

  factory MeResponse.fromJson(Map<String, dynamic> json) {
    return MeResponse._(AuthUser.fromJson(json));
  }
}

String _requiredString(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! String || value.isEmpty) {
    throw FormatException('La respuesta del servidor no incluye "$key" válido.');
  }
  return value;
}

int _requiredInt(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! int || value < 1) {
    throw FormatException('La respuesta del servidor no incluye "$key" válido.');
  }
  return value;
}

Map<String, dynamic> _requiredMap(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! Map<String, dynamic>) {
    throw FormatException('La respuesta del servidor no incluye "$key" válido.');
  }
  return value;
}
