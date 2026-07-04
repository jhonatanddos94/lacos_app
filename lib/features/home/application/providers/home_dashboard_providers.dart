import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lacos_app/features/home/domain/entities/home_dashboard_data.dart';

final homeDashboardProvider = Provider<HomeDashboardData>((ref) {
  return const HomeDashboardData(
    nextAppointment: NextAppointmentPreview(
      clientName: 'Ana Paula Silva',
      serviceName: 'Corte e Escova',
      dateLabel: 'Hoje, 04 de julho',
      timeLabel: '14:30',
      highlights: [
        ClientHighlight(
          label: 'Foto da cliente',
          kind: ClientHighlightKind.photo,
        ),
        ClientHighlight(
          label: '☕ Prefere café sem açúcar.',
          kind: ClientHighlightKind.memory,
        ),
        ClientHighlight(
          label: '🎂 Faz aniversário em agosto.',
          kind: ClientHighlightKind.memory,
        ),
      ],
    ),
    quickActions: [
      QuickActionPreview(
        label: 'Novo\nagendamento',
        type: QuickActionType.appointment,
      ),
      QuickActionPreview(label: 'Nova\ncliente', type: QuickActionType.client),
      QuickActionPreview(
        label: 'Registrar\nmemória',
        type: QuickActionType.memory,
      ),
    ],
    summary: [
      SalonSummaryMetric(
        label: 'Clientes',
        value: '28',
        type: SalonSummaryMetricType.clients,
      ),
      SalonSummaryMetric(
        label: 'Atendimentos hoje',
        value: '5',
        type: SalonSummaryMetricType.appointments,
      ),
      SalonSummaryMetric(
        label: 'Serviços ativos',
        value: '12',
        type: SalonSummaryMetricType.services,
      ),
    ],
    todaySchedule: [
      TodayScheduleAppointment(
        startTime: '09:00',
        endTime: '10:00',
        clientName: 'Juliana Mendes',
        serviceName: 'Coloração',
        status: ScheduleStatus.completed,
      ),
      TodayScheduleAppointment(
        startTime: '11:00',
        endTime: '12:30',
        clientName: 'Marina Costa',
        serviceName: 'Mechas + Tonalização',
        status: ScheduleStatus.completed,
      ),
      TodayScheduleAppointment(
        startTime: '14:30',
        endTime: '15:30',
        clientName: 'Ana Paula Silva',
        serviceName: 'Corte e Escova',
        status: ScheduleStatus.next,
      ),
    ],
  );
});
