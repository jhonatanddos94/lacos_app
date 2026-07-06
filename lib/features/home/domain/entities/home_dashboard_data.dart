class HomeDashboardData {
  const HomeDashboardData({
    required this.nextAppointment,
    required this.quickActions,
    required this.summary,
    required this.todaySchedule,
  });

  final NextAppointmentPreview nextAppointment;
  final List<QuickActionPreview> quickActions;
  final List<SalonSummaryMetric> summary;
  final List<TodayScheduleAppointment> todaySchedule;
}

class NextAppointmentPreview {
  const NextAppointmentPreview({
    required this.clientName,
    required this.serviceName,
    required this.dateLabel,
    required this.timeLabel,
    required this.highlights,
  });

  final String clientName;
  final String serviceName;
  final String dateLabel;
  final String timeLabel;
  final List<ClientHighlight> highlights;
}

class ClientHighlight {
  const ClientHighlight({required this.label, required this.kind});

  final String label;
  final ClientHighlightKind kind;
}

enum ClientHighlightKind { photo, memory }

class QuickActionPreview {
  const QuickActionPreview({required this.label, required this.type});

  final String label;
  final QuickActionType type;
}

enum QuickActionType { appointment, client, memory }

class SalonSummaryMetric {
  const SalonSummaryMetric({
    required this.label,
    required this.value,
    required this.type,
  });

  final String label;
  final String value;
  final SalonSummaryMetricType type;
}

enum SalonSummaryMetricType { clients, appointments, services }

class TodayScheduleAppointment {
  const TodayScheduleAppointment({
    required this.startTime,
    required this.endTime,
    required this.clientName,
    required this.serviceName,
    required this.status,
    this.durationLabel,
  });

  final String startTime;
  final String endTime;
  final String clientName;
  final String serviceName;
  final ScheduleStatus status;
  final String? durationLabel;
}

enum ScheduleStatus { completed, next, pending, confirmed, canceled }
