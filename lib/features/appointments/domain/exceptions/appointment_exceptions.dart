enum AppointmentValidationCode {
  emptyClientId,
  emptyProfessionalId,
  emptyServices,
  invalidServiceId,
  invalidServiceDuration,
  invalidTimeRange,
  startAtInPast,
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

class AppointmentAlreadyCanceledException implements Exception {
  const AppointmentAlreadyCanceledException();
}

class AppointmentCannotCancelCompletedException implements Exception {
  const AppointmentCannotCancelCompletedException();
}

class AppointmentCannotCompleteException implements Exception {
  const AppointmentCannotCompleteException();
}

class AppointmentNotFoundException implements Exception {
  const AppointmentNotFoundException();
}
