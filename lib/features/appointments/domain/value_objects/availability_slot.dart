class AvailabilitySlot {
  const AvailabilitySlot({
    required this.startAt,
    required this.durationMinutes,
  });

  final DateTime startAt;
  final int durationMinutes;

  DateTime get endAt => startAt.add(Duration(minutes: durationMinutes));
}
