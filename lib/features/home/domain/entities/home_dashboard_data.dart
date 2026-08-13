import 'package:lacos_app/features/appointments/domain/enums/appointment_operational_state.dart';

class TodayScheduleAppointment {
  const TodayScheduleAppointment({
    required this.startTime,
    required this.endTime,
    required this.clientName,
    required this.serviceName,
    required this.status,
    this.durationLabel,
    this.clientPhotoUrl,
    this.operationalState,
    this.statusSubtitle,
    this.statusDetail,
  });

  final String startTime;
  final String endTime;
  final String clientName;
  final String serviceName;
  final ScheduleStatus status;
  final String? durationLabel;
  final String? clientPhotoUrl;
  final AppointmentOperationalState? operationalState;
  final String? statusSubtitle;
  final String? statusDetail;
}

enum ScheduleStatus { completed, next, pending, confirmed, canceled }

enum QuickActionType { appointment, client, search }
