import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_api.dart';
import '../auth/auth_controller.dart';

final authApiProvider = Provider<AuthApi>((ref) => AuthApi.fromEnvironment());

final authControllerProvider = ChangeNotifierProvider<AuthController>(
  (ref) => AuthController(ref.watch(authApiProvider)),
);

final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.system);
