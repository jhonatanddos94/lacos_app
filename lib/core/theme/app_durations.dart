/// Durações oficiais de animação do Laços.
abstract final class AppDurations {
  /// 100 ms — pequenos feedbacks.
  static const Duration veryFast = Duration(milliseconds: 100);

  /// 150 ms — botões, hover e mudanças de estado.
  static const Duration fast = Duration(milliseconds: 150);

  /// 200 ms — animação padrão da aplicação.
  static const Duration normal = Duration(milliseconds: 200);

  /// 250 ms — expansões, cards e bottom sheets.
  static const Duration medium = Duration(milliseconds: 250);

  /// 300 ms — transições de tela, onboarding e splash.
  static const Duration slow = Duration(milliseconds: 300);
}
