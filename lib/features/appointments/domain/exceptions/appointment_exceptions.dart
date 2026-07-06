enum AppointmentValidationCode {
  emptyClientId,
  emptyProfessionalId,
  emptyServices,
  invalidServiceId,
  invalidServiceDuration,
  invalidTimeRange,
  notesTooLong,
}

class AppointmentValidationException implements Exception {
  const AppointmentValidationException(this.code);

  final AppointmentValidationCode code;
}

class AppointmentUnavailableException implements Exception {
  const AppointmentUnavailableException();
}

class AppointmentPartialSaveException implements Exception {
  const AppointmentPartialSaveException({
    required this.appointmentId,
    this.cause,
  });

  final String appointmentId;
  final Object? cause;
}
