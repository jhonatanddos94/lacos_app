import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lacos_app/core/config/app_field_limits.dart';
import 'package:lacos_app/core/config/app_strings.dart';
import 'package:lacos_app/core/config/app_validation_messages.dart';
import 'package:lacos_app/core/network/parse_temporary_error_mapper.dart';
import 'package:lacos_app/features/appointments/application/models/created_appointment.dart';
import 'package:lacos_app/features/appointments/application/use_cases/create_appointment_use_case.dart';
import 'package:lacos_app/features/appointments/domain/entities/appointment.dart';
import 'package:lacos_app/features/appointments/domain/exceptions/appointment_exceptions.dart';
import 'package:lacos_app/features/services/domain/entities/service.dart';

class CreateAppointmentController
    extends StateNotifier<AsyncValue<CreatedAppointment?>> {
  CreateAppointmentController(this._createAppointmentUseCase)
    : super(const AsyncData(null));

  final CreateAppointmentUseCase _createAppointmentUseCase;

  void reset() {
    state = const AsyncData(null);
  }

  Future<CreatedAppointment?> save({
    required String clientId,
    required String professionalId,
    required List<Service> services,
    required DateTime startAt,
    required DateTime endAt,
    required List<Appointment> existingAppointments,
    String? notes,
  }) async {
    if (state.isLoading) return null;

    final validationError = _validate(
      clientId: clientId,
      professionalId: professionalId,
      services: services,
      startAt: startAt,
      endAt: endAt,
      notes: notes,
    );
    if (validationError != null) {
      return _fail(validationError);
    }

    debugPrint('[AppointmentSave] started');
    state = const AsyncLoading();

    try {
      final createdAppointment = await _createAppointmentUseCase(
        clientId: clientId,
        professionalId: professionalId,
        services: services,
        startAt: startAt,
        endAt: endAt,
        existingAppointments: existingAppointments,
        notes: notes,
      );
      state = AsyncData(createdAppointment);
      debugPrint('[AppointmentSave] success');
      return createdAppointment;
    } on AppointmentPartialSaveException catch (error, stackTrace) {
      debugPrint(
        '[AppointmentSave] partial save: appointmentId=${error.appointmentId}',
      );
      final friendlyError = FormatException(
        AppStrings.appointmentPartialSaveError,
      );
      state = AsyncError(friendlyError, stackTrace);
      return null;
    } on Object catch (error, stackTrace) {
      debugPrint('[AppointmentSave] failed: $error');
      final friendlyError = FormatException(_resolveErrorMessage(error));
      state = AsyncError(friendlyError, stackTrace);
      return null;
    }
  }

  String? _validate({
    required String clientId,
    required String professionalId,
    required List<Service> services,
    required DateTime startAt,
    required DateTime endAt,
    String? notes,
  }) {
    if (clientId.trim().isEmpty) {
      return AppStrings.appointmentClientRequired;
    }

    if (professionalId.trim().isEmpty) {
      return AppStrings.appointmentProfessionalRequired;
    }

    if (services.isEmpty) {
      return AppStrings.appointmentAddAtLeastOneService;
    }

    for (final service in services) {
      if (service.id.trim().isEmpty) {
        return AppValidationMessages.requiredField;
      }

      final durationMinutes = service.durationMinutes;
      if (durationMinutes == null || durationMinutes <= 0) {
        return AppValidationMessages.serviceDurationRequired;
      }
    }

    if (!startAt.isBefore(endAt)) {
      return AppStrings.appointmentInvalidTimeRange;
    }

    final trimmedNotes = notes?.trim();
    if (trimmedNotes != null &&
        trimmedNotes.length > AppFieldLimits.appointmentNotes) {
      return AppStrings.appointmentNotesMaxLengthError;
    }

    return null;
  }

  CreatedAppointment? _fail(String message) {
    debugPrint('[AppointmentSave] failed: $message');
    state = AsyncError(FormatException(message), StackTrace.current);
    return null;
  }
}

String _resolveErrorMessage(Object error) {
  if (ParseTemporaryErrorMapper.isTemporaryThrowable(error)) {
    return AppStrings.temporarySaveError;
  }

  return switch (error) {
    AppointmentValidationException(code: final code) =>
      _validationMessageForCode(code),
    AppointmentUnavailableException() =>
      AppStrings.appointmentSlotNoLongerAvailable,
    AppointmentPartialSaveException() => AppStrings.appointmentPartialSaveError,
    FormatException(message: final message) => message,
    StateError(message: final message) => message,
    _ => AppStrings.appointmentSaveError,
  };
}

String _validationMessageForCode(AppointmentValidationCode code) {
  return switch (code) {
    AppointmentValidationCode.emptyClientId =>
      AppStrings.appointmentClientRequired,
    AppointmentValidationCode.emptyProfessionalId =>
      AppStrings.appointmentProfessionalRequired,
    AppointmentValidationCode.emptyServices =>
      AppStrings.appointmentAddAtLeastOneService,
    AppointmentValidationCode.invalidServiceId =>
      AppValidationMessages.requiredField,
    AppointmentValidationCode.invalidServiceDuration =>
      AppValidationMessages.serviceDurationRequired,
    AppointmentValidationCode.invalidTimeRange =>
      AppStrings.appointmentInvalidTimeRange,
    AppointmentValidationCode.notesTooLong =>
      AppStrings.appointmentNotesMaxLengthError,
  };
}
