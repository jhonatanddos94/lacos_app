class ServiceRecord {
  const ServiceRecord({
    required this.id,
    this.appointmentId,
    required this.clientId,
    required this.professionalId,
    required this.salonId,
    required this.ownerId,
    this.serviceDate,
    this.procedureSummary,
    this.technicalNotes,
    this.result,
    this.finalAmount,
    this.productsUsed,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String? appointmentId;
  final String clientId;
  final String professionalId;
  final String salonId;
  final String ownerId;
  final DateTime? serviceDate;
  final String? procedureSummary;
  final String? technicalNotes;
  final String? result;
  final double? finalAmount;
  final String? productsUsed;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
}
