import 'package:flutter/material.dart';

/// Escala oficial de arredondamento de bordas do Laços.
abstract final class AppRadius {
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 24;

  static BorderRadius get borderXs => BorderRadius.circular(xs);
  static BorderRadius get borderSm => BorderRadius.circular(sm);
  static BorderRadius get borderMd => BorderRadius.circular(md);
  static BorderRadius get borderLg => BorderRadius.circular(lg);

  static BorderRadius get borderTopLg =>
      const BorderRadius.vertical(top: Radius.circular(lg));

  /// Borda outline padrão para campos de texto e inputs.
  static OutlineInputBorder inputBorder(Color color, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: borderSm,
      borderSide: BorderSide(color: color, width: width),
    );
  }
}
