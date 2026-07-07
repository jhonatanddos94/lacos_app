import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lacos_app/core/config/app_strings.dart';
import 'package:lacos_app/core/network/parse_temporary_error_mapper.dart';
import 'package:lacos_app/features/appointments/application/use_cases/cancel_appointment_use_case.dart';
import 'package:lacos_app/features/appointments/domain/entities/appointment.dart';
import 'package:lacos_app/features/appointments/domain/exceptions/appointment_exceptions.dart';

class CancelAppointmentController
    extends StateNotifier<AsyncValue<Appointment?>> {
  CancelAppointmentController(this._cancelAppointmentUseCase)
    : super(const AsyncData(null));

  final CancelAppointmentUseCase _cancelAppointmentUseCase;

  void reset() {
    state = const AsyncData(null);
  }

  Future<Appointment?> cancel(String appointmentId) async {
    if (state.isLoading) return null;

    debugPrint('[AppointmentCancel] started');
    state = const AsyncLoading();

    try {
      final canceledAppointment = await _cancelAppointmentUseCase(appointmentId);
      state = AsyncData(canceledAppointment);
      debugPrint('[AppointmentCancel] success');
      return canceledAppointment;
    } on Object catch (error, stackTrace) {
      debugPrint('[AppointmentCancel] failed: $error');
      final friendlyError = FormatException(_resolveErrorMessage(error));
      state = AsyncError(friendlyError, stackTrace);
      return null;
    }
  }

  String _resolveErrorMessage(Object error) {
    if (ParseTemporaryErrorMapper.isTemporaryThrowable(error)) {
      return AppStrings.temporarySaveError;
    }

    return switch (error) {
      AppointmentCannotCancelCompletedException() =>
        AppStrings.appointmentCannotCancelCompleted,
      FormatException(message: final message) => message,
      StateError(message: final message) => message,
      _ => AppStrings.appointmentCancelError,
    };
  }
}
