import 'package:flutter/material.dart';

/// Escala oficial de espaçamentos do Laços.
///
/// Unidade base: 4dp. Todos os valores são múltiplos dessa unidade.
abstract final class AppSpacing {
  static const double xxxs = 4;
  static const double xxs = 8;
  static const double xs = 12;
  static const double sm = 16;
  static const double md = 24;
  static const double lg = 32;
  static const double xl = 48;
  static const double xxl = 64;

  /// Margem horizontal padrão das telas (Grid & Layout).
  static const double screenHorizontal = sm;

  static EdgeInsets get paddingXxxs => const EdgeInsets.all(xxxs);
  static EdgeInsets get paddingXxs => const EdgeInsets.all(xxs);
  static EdgeInsets get paddingXs => const EdgeInsets.all(xs);
  static EdgeInsets get paddingSm => const EdgeInsets.all(sm);
  static EdgeInsets get paddingMd => const EdgeInsets.all(md);
  static EdgeInsets get paddingLg => const EdgeInsets.all(lg);
  static EdgeInsets get paddingXl => const EdgeInsets.all(xl);
  static EdgeInsets get paddingXxl => const EdgeInsets.all(xxl);

  static EdgeInsets get screenPadding =>
      const EdgeInsets.symmetric(horizontal: screenHorizontal);
}
