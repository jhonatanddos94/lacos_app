/// Relógio injetável para datas locais da Agenda e da Home.
abstract interface class AppClock {
  DateTime now();
}

class SystemAppClock implements AppClock {
  const SystemAppClock();

  @override
  DateTime now() => DateTime.now();
}

/// Duração até a próxima meia-noite local, sem tick por segundo.
Duration durationUntilNextLocalMidnight(DateTime now) {
  final nextMidnight = DateTime(now.year, now.month, now.day + 1);
  final duration = nextMidnight.difference(now);
  if (duration.isNegative) {
    return Duration.zero;
  }
  return duration;
}
