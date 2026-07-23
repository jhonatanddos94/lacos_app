enum AppointmentStatus {
  pending,
  confirmed,
  completed,
  canceled;

  static AppointmentStatus fromParse(String value) {
    return switch (value) {
      'pending' => AppointmentStatus.pending,
      'confirmed' => AppointmentStatus.confirmed,
      'completed' => AppointmentStatus.completed,
      'canceled' => AppointmentStatus.canceled,
      _ => throw ArgumentError.value(
        value,
        'value',
        'Status de agendamento inválido.',
      ),
    };
  }

  String toParse() {
    return switch (this) {
      AppointmentStatus.pending => 'pending',
      AppointmentStatus.confirmed => 'confirmed',
      AppointmentStatus.completed => 'completed',
      AppointmentStatus.canceled => 'canceled',
    };
  }

  bool get canBeCompleted => switch (this) {
    AppointmentStatus.pending || AppointmentStatus.confirmed => true,
    _ => false,
  };

  bool get canBeEdited => switch (this) {
    AppointmentStatus.pending || AppointmentStatus.confirmed => true,
    _ => false,
  };

  bool get canBeCanceled => switch (this) {
    AppointmentStatus.pending || AppointmentStatus.confirmed => true,
    _ => false,
  };

  bool get countsForCalendarIndicator => this != AppointmentStatus.canceled;
}
