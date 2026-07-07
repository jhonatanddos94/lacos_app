class CompletedServiceParams {
  const CompletedServiceParams({
    required this.serviceId,
    this.finalAmount,
    this.notes,
  });

  final String serviceId;
  final double? finalAmount;
  final String? notes;
}

class CompleteAppointmentParams {
  const CompleteAppointmentParams({
    required this.appointmentId,
    required this.services,
    this.procedureSummary,
    this.technicalNotes,
    this.result,
    this.productsUsed,
    this.finalAmount,
  });

  final String appointmentId;
  final List<CompletedServiceParams> services;
  final String? procedureSummary;
  final String? technicalNotes;
  final String? result;
  final String? productsUsed;
  final double? finalAmount;
}
