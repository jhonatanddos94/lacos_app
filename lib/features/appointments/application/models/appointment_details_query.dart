class AppointmentDetailsQuery {
  const AppointmentDetailsQuery({
    required this.appointmentId,
    required this.day,
  });

  final String appointmentId;
  final DateTime day;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is AppointmentDetailsQuery &&
            appointmentId == other.appointmentId &&
            day.year == other.day.year &&
            day.month == other.day.month &&
            day.day == other.day.day;
  }

  @override
  int get hashCode => Object.hash(appointmentId, day.year, day.month, day.day);
}
