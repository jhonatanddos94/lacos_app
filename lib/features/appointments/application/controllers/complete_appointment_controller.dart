import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lacos_app/core/config/app_strings.dart';
import 'package:lacos_app/core/config/app_validation_messages.dart';
import 'package:lacos_app/core/network/parse_temporary_error_mapper.dart';
import 'package:lacos_app/features/appointments/application/models/complete_appointment_params.dart';
import 'package:lacos_app/features/appointments/application/models/complete_appointment_state.dart';
import 'package:lacos_app/features/appointments/application/use_cases/complete_appointment_use_case.dart';
import 'package:lacos_app/features/appointments/domain/exceptions/appointment_exceptions.dart';
import 'package:lacos_app/features/service_records/domain/entities/service_record.dart';

class CompleteAppointmentController
    extends StateNotifier<CompleteAppointmentState> {
  CompleteAppointmentController(this._completeAppointmentUseCase)
    : super(const CompleteAppointmentState());

  final CompleteAppointmentUseCase _completeAppointmentUseCase;
  var _submissionInFlight = false;

  void setProcedureSummary(String value) {
    state = state.copyWith(procedureSummary: value, clearErrorMessage: true);
  }

  void setTechnicalNotes(String value) {
    state = state.copyWith(technicalNotes: value, clearErrorMessage: true);
  }

  void setResult(String value) {
    state = state.copyWith(result: value, clearErrorMessage: true);
  }

  void setProductsUsed(String value) {
    state = state.copyWith(productsUsed: value, clearErrorMessage: true);
  }

  void setFinalAmount(double? value) {
    state = state.copyWith(
      finalAmount: value,
      clearFinalAmount: value == null,
      clearErrorMessage: true,
    );
  }

  void setServices(List<CompletedServiceParams> services) {
    state = state.copyWith(services: services, clearErrorMessage: true);
  }

  void reset() {
    _submissionInFlight = false;
    state = const CompleteAppointmentState();
  }

  Future<ServiceRecord?> complete(
    String appointmentId, {
    List<String> mentionedMemoryIds = const [],
  }) async {
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

    debugPrint('[AppointmentComplete] controller complete start');
    _submissionInFlight = true;
    state = state.copyWith(
      isLoading: true,
      success: false,
      clearErrorMessage: true,
    );

    try {
      final serviceRecord = await _completeAppointmentUseCase(
        CompleteAppointmentParams(
          appointmentId: appointmentId,
          procedureSummary: _nullableText(state.procedureSummary),
          technicalNotes: _nullableText(state.technicalNotes),
          result: _nullableText(state.result),
          productsUsed: _nullableText(state.productsUsed),
          finalAmount: state.finalAmount,
          services: state.services,
          mentionedMemoryIds: mentionedMemoryIds,
        ),
      );

      state = state.copyWith(
        isLoading: false,
        success: true,
        clearErrorMessage: true,
      );
      debugPrint('[AppointmentComplete] success');
      return serviceRecord;
    } on Object catch (error) {
      debugPrint('[AppointmentComplete] failed: $error');
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

    if (state.services.isEmpty) {
      return AppStrings.appointmentCompleteAtLeastOneService;
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
      AppointmentNotFoundException() => AppStrings.appointmentNotFound,
      AppointmentCannotCompleteException() =>
        AppStrings.appointmentCannotComplete,
      FormatException(message: final message) => message,
      StateError(message: final message) => message,
      _ => AppStrings.appointmentCompleteSubmitError,
    };
  }
}
