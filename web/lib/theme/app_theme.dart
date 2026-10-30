import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get light => _build(
        brightness: Brightness.light,
        primary: AppColors.primary,
        primaryContainer: const Color(0xFFEEF2FF),
        onPrimaryContainer: const Color(0xFF312E81),
        secondary: AppColors.secondary,
        background: AppColors.lightBg,
        surface: AppColors.lightSurface,
        surfaceSubtle: AppColors.lightSurfaceSubtle,
        border: AppColors.lightBorder,
        foreground: AppColors.lightTextPrimary,
        foregroundMuted: AppColors.lightTextSecondary,
      );

  static ThemeData get dark => _build(
        brightness: Brightness.dark,
        primary: AppColors.primaryDark,
        primaryContainer: const Color(0xFF1E1B4B),
        onPrimaryContainer: const Color(0xFFC7D2FE),
        secondary: AppColors.secondaryLight,
        background: AppColors.darkBg,
        surface: AppColors.darkSurface,
        surfaceSubtle: AppColors.darkSurfaceSubtle,
        border: AppColors.darkBorder,
        foreground: AppColors.darkTextPrimary,
        foregroundMuted: AppColors.darkTextSecondary,
      );

  static ThemeData _build({
    required Brightness brightness,
    required Color primary,
    required Color primaryContainer,
    required Color onPrimaryContainer,
    required Color secondary,
    required Color background,
    required Color surface,
    required Color surfaceSubtle,
    required Color border,
    required Color foreground,
    required Color foregroundMuted,
  }) {
    final isDark = brightness == Brightness.dark;

    final scheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: brightness,
      primary: primary,
      secondary: secondary,
      primaryContainer: primaryContainer,
      onPrimaryContainer: onPrimaryContainer,
      surface: surface,
      onSurface: foreground,
      surfaceContainerHighest: surfaceSubtle,
      outline: border,
      outlineVariant: isDark ? AppColors.darkBorderSubtle : AppColors.lightBorderSubtle,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      fontFamily: 'Inter',
      appBarTheme: AppBarTheme(
        backgroundColor: background.withValues(alpha: 0.92),
        foregroundColor: foreground,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          color: foreground,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: border,
            width: 1,
          ),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: border.withValues(alpha: isDark ? 0.6 : 0.8),
        thickness: 1,
        space: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? const Color(0xFF162035) : surface,
        hintStyle: TextStyle(
          color: foregroundMuted.withValues(alpha: 0.8),
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        labelStyle: TextStyle(
          color: foregroundMuted,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primary, width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error, width: 1.8),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          minimumSize: const Size(0, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.1,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: foreground,
          side: BorderSide(color: border),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          minimumSize: const Size(0, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: surface,
        elevation: 0,
        indicatorColor: primaryContainer,
        selectedIconTheme: IconThemeData(color: primary, size: 22),
        unselectedIconTheme: IconThemeData(color: foregroundMuted, size: 22),
        selectedLabelTextStyle: TextStyle(
          color: primary,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
        unselectedLabelTextStyle: TextStyle(
          color: foregroundMuted,
          fontWeight: FontWeight.w500,
          fontSize: 12,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surfaceSubtle,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: border),
        ),
        labelStyle: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: foreground,
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: border),
        ),
      ),
      textTheme: TextTheme(
        headlineLarge: TextStyle(
          color: foreground,
          fontSize: 32,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.8,
        ),
        headlineMedium: TextStyle(
          color: foreground,
          fontSize: 26,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
        headlineSmall: TextStyle(
          color: foreground,
          fontSize: 22,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
        titleLarge: TextStyle(
          color: foreground,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.2,
        ),
        titleMedium: TextStyle(
          color: foreground,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
        titleSmall: TextStyle(
          color: foregroundMuted,
          fontSize: 13,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
        bodyLarge: TextStyle(
          color: foreground,
          fontSize: 15,
          fontWeight: FontWeight.w400,
          height: 1.5,
        ),
        bodyMedium: TextStyle(
          color: foregroundMuted,
          fontSize: 14,
          fontWeight: FontWeight.w400,
          height: 1.5,
        ),
        bodySmall: TextStyle(
          color: foregroundMuted.withValues(alpha: 0.9),
          fontSize: 12,
          fontWeight: FontWeight.w400,
        ),
      ),
    );
  }
}
