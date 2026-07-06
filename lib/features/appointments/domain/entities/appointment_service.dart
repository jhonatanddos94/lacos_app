class AppointmentService {
  const AppointmentService({
    required this.id,
    required this.appointmentId,
    required this.serviceId,
    required this.salonId,
    required this.ownerId,
    this.priceAtBooking,
    required this.durationMinutesAtBooking,
    required this.displayOrder,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String appointmentId;
  final String serviceId;
  final String salonId;
  final String ownerId;
  final double? priceAtBooking;
  final int durationMinutesAtBooking;
  final int displayOrder;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
}
