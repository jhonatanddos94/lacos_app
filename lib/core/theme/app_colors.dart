import 'package:flutter/material.dart';

/// Paleta oficial de cores do Laços.
///
/// Tonalidades organizadas conforme Material Design 3 (50–900),
/// conforme Documento 06 — Design System & Experiência.
abstract final class AppColors {
  // ── Marca ────────────────────────────────────────────────────────────────

  /// Laços Purple — cor principal da marca.
  static const Color lacosPurple = Color(0xFF7B5CBF);

  /// Soft Lilac — complemento delicado da identidade.
  static const Color softLilac = Color(0xFFEDE7F6);

  // ── Neutros ──────────────────────────────────────────────────────────────

  /// Warm White — background principal da aplicação.
  static const Color warmWhite = Color(0xFFFAF8F5);

  /// Surface — cards, bottom sheets, dialogs e containers.
  static const Color surface = Color(0xFFFFFFFF);

  /// Graphite — texto principal. Nunca preto absoluto.
  static const Color graphite = Color(0xFF3D3D42);

  /// Texto secundário — datas, horários, legendas e informações auxiliares.
  static const Color textSecondary = Color(0xFF71717A);

  /// Divisores — quase imperceptíveis, apenas para organização.
  static const Color divider = Color(0xFFEBE8E4);

  // ── Semânticas ───────────────────────────────────────────────────────────

  /// Soft Green — sucesso, conclusão e confirmação.
  static const Color softGreen = Color(0xFF5EAD82);

  /// Warm Amber — atenção e avisos não críticos.
  static const Color warmAmber = Color(0xFFD9A441);

  /// Soft Rose — erros com comunicação tranquila.
  static const Color softRose = Color(0xFFD4727F);

  /// Soft Blue — informações e ajuda.
  static const Color softBlue = Color(0xFF6B9FD0);

  // ── Escala Laços Purple (Material 3) ─────────────────────────────────────

  static const Color purple50 = Color(0xFFF5F0FA);
  static const Color purple100 = Color(0xFFEBE0F5);
  static const Color purple200 = Color(0xFFD6C1EB);
  static const Color purple300 = Color(0xFFC0A2E0);
  static const Color purple400 = Color(0xFF9E7BD0);
  static const Color purple500 = lacosPurple;
  static const Color purple600 = Color(0xFF6349A6);
  static const Color purple700 = Color(0xFF4C3785);
  static const Color purple800 = Color(0xFF362664);
  static const Color purple900 = Color(0xFF221540);

  static const Map<int, Color> purpleScale = {
    50: purple50,
    100: purple100,
    200: purple200,
    300: purple300,
    400: purple400,
    500: purple500,
    600: purple600,
    700: purple700,
    800: purple800,
    900: purple900,
  };

  // ── Utilitários ──────────────────────────────────────────────────────────

  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color onSecondary = Color(0xFF3D3D42);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color onSuccess = Color(0xFFFFFFFF);
}
