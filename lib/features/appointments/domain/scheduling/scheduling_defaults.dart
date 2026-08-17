/// Fallback global de expediente até [WorkingHoursResolver] por salão/profissional.
///
/// Todos os dias da semana — inclusive sábado e domingo — usam a mesma janela.
/// Domingo **não** é tratado como fechado; a configuração semanal futura definirá
/// `isWorking`, `startMinutes` e `endMinutes` por weekday.
abstract final class SchedulingDefaults {
  static const int openingMinutes = 9 * 60;
  static const int closingMinutes = 18 * 60;
  static const int slotIntervalMinutes = 15;

  static DateTime openingTimeOn(DateTime day) => _timeOnDay(day, openingMinutes);

  static DateTime closingTimeOn(DateTime day) => _timeOnDay(day, closingMinutes);

  static DateTime _timeOnDay(DateTime day, int minutesFromMidnight) {
    return DateTime(
      day.year,
      day.month,
      day.day,
      minutesFromMidnight ~/ 60,
      minutesFromMidnight % 60,
    );
  }
}
