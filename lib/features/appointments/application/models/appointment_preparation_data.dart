import 'package:lacos_app/features/appointments/application/models/appointment_preparation_memory_item.dart';

class AppointmentPreparationData {
  const AppointmentPreparationData({
    required this.appointmentId,
    required this.clientId,
    required this.clientName,
    required this.clientPhotoUrl,
    required this.servicesSummary,
    required this.scheduleTimeLabel,
    required this.memories,
  });

  final String appointmentId;
  final String clientId;
  final String clientName;
  final String? clientPhotoUrl;
  final String servicesSummary;
  final String scheduleTimeLabel;
  final List<AppointmentPreparationMemoryItem> memories;
}
