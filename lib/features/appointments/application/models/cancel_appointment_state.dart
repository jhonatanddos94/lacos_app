import 'package:lacos_app/features/appointments/domain/enums/appointment_canceled_by.dart';

class CancelAppointmentState {
  const CancelAppointmentState({
    this.canceledBy,
    this.cancellationReason = '',
    this.isLoading = false,
    this.errorMessage,
    this.success = false,
  });

  final AppointmentCanceledBy? canceledBy;
  final String cancellationReason;
  final bool isLoading;
  final String? errorMessage;
  final bool success;

  CancelAppointmentState copyWith({
    AppointmentCanceledBy? canceledBy,
    bool clearCanceledBy = false,
    String? cancellationReason,
    bool? isLoading,
    String? errorMessage,
    bool clearErrorMessage = false,
    bool? success,
  }) {
    return CancelAppointmentState(
      canceledBy: clearCanceledBy ? null : (canceledBy ?? this.canceledBy),
      cancellationReason: cancellationReason ?? this.cancellationReason,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearErrorMessage
          ? null
          : (errorMessage ?? this.errorMessage),
      success: success ?? this.success,
    );
  }
}
