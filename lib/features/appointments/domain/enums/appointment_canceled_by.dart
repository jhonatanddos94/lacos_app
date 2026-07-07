enum AppointmentCanceledBy {
  client,
  salon;

  static AppointmentCanceledBy? fromParse(String? value) {
    return switch (value) {
      'client' => AppointmentCanceledBy.client,
      'salon' => AppointmentCanceledBy.salon,
      _ => null,
    };
  }

  String toParse() {
    return switch (this) {
      AppointmentCanceledBy.client => 'client',
      AppointmentCanceledBy.salon => 'salon',
    };
  }
}
