import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Níveis oficiais de elevação do Laços.
///
/// Sombras suaves, baixa opacidade e desfoque amplo — apenas para
/// transmitir profundidade, nunca impacto visual.
abstract final class AppShadows {
  static const List<BoxShadow> level0 = [];

  /// Cards, campos e containers discretamente destacados.
  static const List<BoxShadow> level1 = [
    BoxShadow(
      color: Color(0x0D3D3D42),
      blurRadius: 12,
      offset: Offset(0, 2),
    ),
  ];

  /// Dialogs, bottom sheets e menus temporários.
  static const List<BoxShadow> level2 = [
    BoxShadow(
      color: Color(0x143D3D42),
      blurRadius: 24,
      offset: Offset(0, 4),
    ),
  ];

  static Color get shadowColor => AppColors.graphite;
}
