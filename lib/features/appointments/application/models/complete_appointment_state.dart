import 'package:lacos_app/features/appointments/application/models/complete_appointment_params.dart';

class CompleteAppointmentState {
  const CompleteAppointmentState({
    this.isLoading = false,
    this.errorMessage,
    this.success = false,
    this.procedureSummary = '',
    this.technicalNotes = '',
    this.result = '',
    this.productsUsed = '',
    this.finalAmount,
    this.services = const [],
  });

  final bool isLoading;
  final String? errorMessage;
  final bool success;
  final String procedureSummary;
  final String technicalNotes;
  final String result;
  final String productsUsed;
  final double? finalAmount;
  final List<CompletedServiceParams> services;

  CompleteAppointmentState copyWith({
    bool? isLoading,
    String? errorMessage,
    bool clearErrorMessage = false,
    bool? success,
    String? procedureSummary,
    String? technicalNotes,
    String? result,
    String? productsUsed,
    double? finalAmount,
    bool clearFinalAmount = false,
    List<CompletedServiceParams>? services,
  }) {
    return CompleteAppointmentState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearErrorMessage
          ? null
          : (errorMessage ?? this.errorMessage),
      success: success ?? this.success,
      procedureSummary: procedureSummary ?? this.procedureSummary,
      technicalNotes: technicalNotes ?? this.technicalNotes,
      result: result ?? this.result,
      productsUsed: productsUsed ?? this.productsUsed,
      finalAmount: clearFinalAmount ? null : (finalAmount ?? this.finalAmount),
      services: services ?? this.services,
    );
  }
}
