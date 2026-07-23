import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lacos_app/core/config/app_strings.dart';
import 'package:lacos_app/core/config/app_validation_messages.dart';
import 'package:lacos_app/core/network/parse_temporary_error_mapper.dart';
import 'package:lacos_app/features/appointments/application/models/cancel_appointment_params.dart';
import 'package:lacos_app/features/appointments/application/models/cancel_appointment_state.dart';
import 'package:lacos_app/features/appointments/application/use_cases/cancel_appointment_use_case.dart';
import 'package:lacos_app/features/appointments/domain/entities/appointment.dart';
import 'package:lacos_app/features/appointments/domain/enums/appointment_canceled_by.dart';
import 'package:lacos_app/features/appointments/domain/exceptions/appointment_exceptions.dart';

class CancelAppointmentController
    extends StateNotifier<CancelAppointmentState> {
  CancelAppointmentController(this._cancelAppointmentUseCase)
    : super(const CancelAppointmentState());

  final CancelAppointmentUseCase _cancelAppointmentUseCase;
  var _submissionInFlight = false;

  void setCanceledBy(AppointmentCanceledBy value) {
    state = state.copyWith(canceledBy: value, clearErrorMessage: true);
  }

  void setCancellationReason(String value) {
    state = state.copyWith(cancellationReason: value, clearErrorMessage: true);
  }

  void reset() {
    _submissionInFlight = false;
    state = const CancelAppointmentState();
  }

  Future<Appointment?> cancel(String appointmentId) async {
    if (state.isLoading || _submissionInFlight) return null;

    final validationError = _validate(appointmentId: appointmentId);
    if (validationError != null) {
      state = state.copyWith(
        errorMessage: validationError,
        success: false,
        isLoading: false,
      );
      return null;
    }

    debugPrint('[AppointmentCancel] started');
    _submissionInFlight = true;
    state = state.copyWith(
      isLoading: true,
      success: false,
      clearErrorMessage: true,
    );

    try {
      final canceledAppointment = await _cancelAppointmentUseCase(
        CancelAppointmentParams(
          appointmentId: appointmentId,
          canceledBy: state.canceledBy!,
          cancellationReason: _nullableText(state.cancellationReason),
        ),
      );

      state = state.copyWith(
        isLoading: false,
        success: true,
        clearErrorMessage: true,
      );
      debugPrint('[AppointmentCancel] success');
      return canceledAppointment;
    } on Object catch (error) {
      debugPrint('[AppointmentCancel] failed: $error');
      state = state.copyWith(
        isLoading: false,
        success: false,
        errorMessage: _resolveErrorMessage(error),
      );
      return null;
    } finally {
      _submissionInFlight = false;
    }
  }

  String? _validate({required String appointmentId}) {
    if (appointmentId.trim().isEmpty) {
      return AppValidationMessages.requiredField;
    }

    if (state.canceledBy == null) {
      return AppStrings.appointmentCancelWhoCanceledRequired;
    }

    return null;
  }

  String? _nullableText(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return null;
    }

    return trimmed;
  }

  String _resolveErrorMessage(Object error) {
    if (ParseTemporaryErrorMapper.isTemporaryThrowable(error)) {
      return AppStrings.temporarySaveError;
    }

    return switch (error) {
      AppointmentCannotCancelCompletedException() =>
        AppStrings.appointmentCannotCancelCompleted,
      AppointmentAlreadyCanceledException() =>
        AppStrings.appointmentAlreadyCanceled,
      FormatException(message: final message) => message,
      StateError(message: final message) => message,
      _ => AppStrings.appointmentCancelSubmitError,
    };
  }
}
