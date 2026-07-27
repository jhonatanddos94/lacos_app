abstract final class AppDurations {
  static const Duration veryFast = Duration(milliseconds: 100);
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration short = Duration(milliseconds: 250);
  static const Duration normal = Duration(milliseconds: 200);
  static const Duration medium = Duration(milliseconds: 250);
  static const Duration slow = Duration(milliseconds: 300);
  static const Duration splash = Duration(milliseconds: 300);
  static const Duration splashBowStep = Duration(milliseconds: 600);
  static const Duration carousel = Duration(seconds: 5);

  /// Intervalo entre memórias no preview rotativo da ficha da cliente.
  static const Duration memoryPreviewRotation = Duration(seconds: 5);

  /// Duração da transição fade + slide do preview de memórias.
  static const Duration memoryPreviewTransition = Duration(milliseconds: 300);
  static const Duration agendaHighlight = Duration(milliseconds: 2500);
  static const Duration appointmentPreparationBeforeStart = Duration(
    minutes: 30,
  );
}
