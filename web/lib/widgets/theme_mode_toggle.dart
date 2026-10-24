import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/app_providers.dart';

class ThemeModeToggle extends ConsumerWidget {
  const ThemeModeToggle({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeModeProvider);
    final icon = switch (mode) {
      ThemeMode.light => Icons.light_mode_outlined,
      ThemeMode.dark => Icons.dark_mode_outlined,
      ThemeMode.system => Icons.brightness_auto_outlined,
    };
    final label = switch (mode) {
      ThemeMode.light => 'Cambiar a modo oscuro',
      ThemeMode.dark => 'Cambiar a modo claro',
      ThemeMode.system => 'Usar modo claro',
    };

    return IconButton(
      tooltip: label,
      onPressed: () {
        final nextMode = switch (mode) {
          ThemeMode.light => ThemeMode.dark,
          ThemeMode.dark => ThemeMode.light,
          ThemeMode.system => ThemeMode.light,
        };
        ref.read(themeModeProvider.notifier).state = nextMode;
      },
      icon: Icon(icon),
    );
  }
}
