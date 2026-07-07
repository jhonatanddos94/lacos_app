class ServiceRecordService {
  const ServiceRecordService({
    required this.id,
    required this.serviceRecordId,
    required this.serviceId,
    required this.salonId,
    required this.ownerId,
    this.finalAmount,
    this.notes,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String serviceRecordId;
  final String serviceId;
  final String salonId;
  final String ownerId;
  final double? finalAmount;
  final String? notes;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
}
