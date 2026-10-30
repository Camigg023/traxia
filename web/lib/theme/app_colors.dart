import 'package:flutter/material.dart';

/// Paleta de colores de diseño SaaS Premium para TRAXIA.
/// Basada en Material Design 3 con tonos Violeta, Índigo y Púrpura de alta gama.
class AppColors {
  AppColors._();

  // --- Primarios y Marca (Violeta, Índigo, Púrpura) ---
  static const primary = Color(0xFF6366F1); // Indigo 500
  static const primaryDark = Color(0xFF818CF8); // Indigo 400
  static const primaryLight = Color(0xFF4F46E5); // Indigo 600
  static const primaryHover = Color(0xFF4338CA); // Indigo 700

  static const secondary = Color(0xFF8B5CF6); // Violet 500
  static const secondaryLight = Color(0xFFA78BFA); // Violet 400
  static const secondaryDark = Color(0xFF7C3AED); // Violet 600

  static const tertiary = Color(0xFF06B6D4); // Cyan 500 (acento tecnológico moderno)

  // --- Estados funcionales SaaS ---
  static const success = Color(0xFF10B981);
  static const successContainer = Color(0xFFD1FAE5);
  static const successDark = Color(0xFF34D399);

  static const warning = Color(0xFFF59E0B);
  static const warningContainer = Color(0xFFFEF3C7);

  static const error = Color(0xFFEF4444);
  static const errorContainer = Color(0xFFFEE2E2);

  // --- Modo Claro (Fondos suaves, superficies contrastadas) ---
  static const lightBg = Color(0xFFF8FAFC); // Slate 50
  static const lightSurface = Colors.white;
  static const lightSurfaceSubtle = Color(0xFFF1F5F9); // Slate 100
  static const lightBorder = Color(0xFFE2E8F0); // Slate 200
  static const lightBorderSubtle = Color(0xFFEDF2F7);
  static const lightTextPrimary = Color(0xFF0F172A); // Slate 900
  static const lightTextSecondary = Color(0xFF64748B); // Slate 500
  static const lightTextMuted = Color(0xFF94A3B8); // Slate 400

  // --- Modo Oscuro Profundo (Elegante, contrastado, no gris deslavado) ---
  static const darkBg = Color(0xFF0B0F17); // Negro azulado profundo
  static const darkSurface = Color(0xFF131B2E); // Indigo-slate oscuro
  static const darkSurfaceSubtle = Color(0xFF1E293B); // Slate 800
  static const darkBorder = Color(0xFF2E3A52); // Borde delicado índigo
  static const darkBorderSubtle = Color(0xFF1F293D);
  static const darkTextPrimary = Color(0xFFF8FAFC); // Slate 50
  static const darkTextSecondary = Color(0xFF94A3B8); // Slate 400
  static const darkTextMuted = Color(0xFF64748B); // Slate 500
}

/// Decoraciones y utilidades de estilo visual SaaS Premium (Glassmorphism, sombras sutiles).
class SaasDecoration {
  SaasDecoration._();

  /// Sombra suave moderna para tarjetas e interfaces SaaS (no sombras toscas).
  static List<BoxShadow> softShadow(bool isDark) {
    if (isDark) {
      return [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.35),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
        BoxShadow(
          color: AppColors.primary.withValues(alpha: 0.05),
          blurRadius: 30,
          offset: const Offset(0, 0),
        ),
      ];
    }
    return [
      BoxShadow(
        color: const Color(0xFF0F172A).withValues(alpha: 0.04),
        blurRadius: 16,
        offset: const Offset(0, 4),
      ),
      BoxShadow(
        color: const Color(0xFF0F172A).withValues(alpha: 0.02),
        blurRadius: 4,
        offset: const Offset(0, 1),
      ),
    ];
  }

  /// Sombra más pronunciada para modales, flyouts y paneles elevados.
  static List<BoxShadow> elevatedShadow(bool isDark) {
    if (isDark) {
      return [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.5),
          blurRadius: 32,
          offset: const Offset(0, 16),
        ),
        BoxShadow(
          color: AppColors.primary.withValues(alpha: 0.1),
          blurRadius: 48,
          offset: const Offset(0, 0),
        ),
      ];
    }
    return [
      BoxShadow(
        color: const Color(0xFF0F172A).withValues(alpha: 0.08),
        blurRadius: 28,
        offset: const Offset(0, 12),
      ),
      BoxShadow(
        color: const Color(0xFF0F172A).withValues(alpha: 0.04),
        blurRadius: 8,
        offset: const Offset(0, 2),
      ),
    ];
  }

  /// Contenedor con efecto glassmorphism sutil.
  static BoxDecoration glassmorphic({
    required bool isDark,
    double borderRadius = 16,
    Color? customColor,
    Border? border,
  }) {
    final bgColor = customColor ??
        (isDark
            ? AppColors.darkSurface.withValues(alpha: 0.75)
            : Colors.white.withValues(alpha: 0.8));
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : AppColors.primary.withValues(alpha: 0.12);

    return BoxDecoration(
      color: bgColor,
      borderRadius: BorderRadius.circular(borderRadius),
      border: border ?? Border.all(color: borderColor, width: 1),
      boxShadow: softShadow(isDark),
    );
  }

  /// Gradiente de acento para botones de acción destacados o cabeceras.
  static const brandGradient = LinearGradient(
    colors: [AppColors.primary, AppColors.secondary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Gradiente sutil para fondos de bienvenida o banners.
  static LinearGradient subtleHeroGradient(bool isDark) {
    if (isDark) {
      return LinearGradient(
        colors: [
          const Color(0xFF131B2E),
          const Color(0xFF1A1F36).withValues(alpha: 0.8),
          AppColors.darkBg,
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    }
    return LinearGradient(
      colors: [
        const Color(0xFFEEF2FF), // Indigo 50
        const Color(0xFFF5F3FF), // Violet 50
        AppColors.lightBg,
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }
}
