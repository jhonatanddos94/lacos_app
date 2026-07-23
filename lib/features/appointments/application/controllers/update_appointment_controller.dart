import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lacos_app/core/config/app_field_limits.dart';
import 'package:lacos_app/core/config/app_strings.dart';
import 'package:lacos_app/core/config/app_validation_messages.dart';
import 'package:lacos_app/core/network/parse_temporary_error_mapper.dart';
import 'package:lacos_app/features/appointments/application/models/updated_appointment.dart';
import 'package:lacos_app/features/appointments/application/use_cases/update_appointment_use_case.dart';
import 'package:lacos_app/features/appointments/domain/exceptions/appointment_exceptions.dart';
import 'package:lacos_app/features/services/domain/entities/service.dart';

class UpdateAppointmentController
    extends StateNotifier<AsyncValue<UpdatedAppointment?>> {
  UpdateAppointmentController(this._updateAppointmentUseCase)
    : super(const AsyncData(null));

  final UpdateAppointmentUseCase _updateAppointmentUseCase;

  void reset() {
    state = const AsyncData(null);
  }

  Future<UpdatedAppointment?> save({
    required String appointmentId,
    required String clientId,
    required String professionalId,
    required List<Service> services,
    required DateTime startAt,
    required DateTime endAt,
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

    debugPrint('[AppointmentUpdate] started');
    state = const AsyncLoading();

    try {
      final updatedAppointment = await _updateAppointmentUseCase(
        UpdateAppointmentParams(
          appointmentId: appointmentId,
          clientId: clientId,
          professionalId: professionalId,
          services: services,
          startAt: startAt,
          endAt: endAt,
          notes: notes,
        ),
      );
      state = AsyncData(updatedAppointment);
      debugPrint('[AppointmentUpdate] success');
      return updatedAppointment;
    } on AppointmentServicesUpdateException catch (error, stackTrace) {
      debugPrint('[AppointmentUpdate] services sync failed: ${error.cause}');
      final friendlyError = FormatException(
        AppStrings.appointmentServicesUpdateError,
      );
      state = AsyncError(friendlyError, stackTrace);
      return null;
    } on AppointmentPartialSaveException catch (error, stackTrace) {
      debugPrint(
        '[AppointmentUpdate] partial save: appointmentId=${error.appointmentId}',
      );
      final friendlyError = FormatException(
        AppStrings.appointmentPartialSaveError,
      );
      state = AsyncError(friendlyError, stackTrace);
      return null;
    } on Object catch (error, stackTrace) {
      debugPrint('[AppointmentUpdate] failed: $error');
      final friendlyError = FormatException(
        resolveUpdateAppointmentErrorMessage(error),
      );
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

  UpdatedAppointment? _fail(String message) {
    debugPrint('[AppointmentUpdate] failed: $message');
    state = AsyncError(FormatException(message), StackTrace.current);
    return null;
  }
}

String resolveUpdateAppointmentErrorMessage(Object error) {
  if (ParseTemporaryErrorMapper.isTemporaryThrowable(error)) {
    return AppStrings.temporarySaveError;
  }

  return switch (error) {
    AppointmentValidationException(code: final code) =>
      _validationMessageForCode(code),
    AppointmentUnavailableException() =>
      AppStrings.appointmentSlotNoLongerAvailable,
    AppointmentCannotEditException() => AppStrings.appointmentCannotEdit,
    AppointmentNotFoundException() => AppStrings.appointmentNotFound,
    AppointmentServicesUpdateException() =>
      AppStrings.appointmentServicesUpdateError,
    AppointmentPartialSaveException() => AppStrings.appointmentPartialSaveError,
    FormatException(message: final message) => message,
    StateError(message: final message) => message,
    _ => AppStrings.appointmentUpdateError,
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
    AppointmentValidationCode.startAtInPast =>
      AppStrings.appointmentStartAtInPast,
    AppointmentValidationCode.notesTooLong =>
      AppStrings.appointmentNotesMaxLengthError,
  };
}
