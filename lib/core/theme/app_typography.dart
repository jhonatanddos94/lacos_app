import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Tipografia oficial do Laços — Plus Jakarta Sans.
///
/// Hierarquia: Display → Headline → Title → Subtitle → Body → Label → Caption.
abstract final class AppTypography {
  static const String fontFamily = 'Plus Jakarta Sans';

  static const FontWeight regular = FontWeight.w400;
  static const FontWeight medium = FontWeight.w500;
  static const FontWeight semiBold = FontWeight.w600;
  static const FontWeight bold = FontWeight.w700;

  static TextTheme textTheme({Brightness brightness = Brightness.light}) {
    final onSurface = brightness == Brightness.light
        ? AppColors.graphite
        : const Color(0xFFE8E8EC);
    final onSurfaceVariant = brightness == Brightness.light
        ? AppColors.textSecondary
        : const Color(0xFFA1A1AA);

    final base = GoogleFonts.plusJakartaSansTextTheme();

    return base.copyWith(
      // Display — uso extremamente raro (splash, boas-vindas).
      displayLarge: _style(
        base.displayLarge,
        size: 57,
        height: 64,
        weight: bold,
        color: onSurface,
        letterSpacing: -0.25,
      ),
      displayMedium: _style(
        base.displayMedium,
        size: 45,
        height: 52,
        weight: bold,
        color: onSurface,
      ),
      displaySmall: _style(
        base.displaySmall,
        size: 36,
        height: 44,
        weight: bold,
        color: onSurface,
      ),

      // Headline — títulos principais das telas.
      headlineLarge: _style(
        base.headlineLarge,
        size: 32,
        height: 40,
        weight: semiBold,
        color: onSurface,
      ),
      headlineMedium: _style(
        base.headlineMedium,
        size: 28,
        height: 36,
        weight: semiBold,
        color: onSurface,
      ),
      headlineSmall: _style(
        base.headlineSmall,
        size: 24,
        height: 32,
        weight: semiBold,
        color: onSurface,
      ),

      // Title — cards, bottom sheets, seções e dialogs.
      titleLarge: _style(
        base.titleLarge,
        size: 22,
        height: 28,
        weight: semiBold,
        color: onSurface,
      ),
      titleMedium: _style(
        base.titleMedium,
        size: 16,
        height: 24,
        weight: semiBold,
        color: onSurface,
      ),
      titleSmall: _style(
        base.titleSmall,
        size: 14,
        height: 20,
        weight: semiBold,
        color: onSurface,
      ),

      // Body — texto principal da aplicação.
      bodyLarge: _style(
        base.bodyLarge,
        size: 16,
        height: 24,
        weight: regular,
        color: onSurface,
      ),
      bodyMedium: _style(
        base.bodyMedium,
        size: 14,
        height: 20,
        weight: regular,
        color: onSurface,
      ),
      bodySmall: _style(
        base.bodySmall,
        size: 12,
        height: 16,
        weight: regular,
        color: onSurfaceVariant,
      ),

      // Label — botões, chips, badges e campos.
      labelLarge: _style(
        base.labelLarge,
        size: 14,
        height: 20,
        weight: medium,
        color: onSurface,
        letterSpacing: 0.1,
      ),
      labelMedium: _style(
        base.labelMedium,
        size: 12,
        height: 16,
        weight: medium,
        color: onSurface,
        letterSpacing: 0.5,
      ),
      labelSmall: _style(
        base.labelSmall,
        size: 11,
        height: 16,
        weight: medium,
        color: onSurface,
        letterSpacing: 0.5,
      ),
    );
  }

  /// Subtitle — complementa títulos (ex.: "Hoje você possui 5 atendimentos.").
  static TextStyle subtitle({Brightness brightness = Brightness.light}) {
    return GoogleFonts.plusJakartaSans(
      fontSize: 18,
      height: 26 / 18,
      fontWeight: medium,
      color: brightness == Brightness.light
          ? AppColors.graphite
          : const Color(0xFFE8E8EC),
    );
  }

  /// Caption — datas, horários e informações auxiliares.
  static TextStyle caption({Brightness brightness = Brightness.light}) {
    return GoogleFonts.plusJakartaSans(
      fontSize: 12,
      height: 16 / 12,
      fontWeight: regular,
      color: brightness == Brightness.light
          ? AppColors.textSecondary
          : const Color(0xFFA1A1AA),
    );
  }

  static TextStyle _style(
    TextStyle? base, {
    required double size,
    required double height,
    required FontWeight weight,
    required Color color,
    double? letterSpacing,
  }) {
    return GoogleFonts.plusJakartaSans(
      fontSize: size,
      height: height / size,
      fontWeight: weight,
      color: color,
      letterSpacing: letterSpacing,
    );
  }
}
