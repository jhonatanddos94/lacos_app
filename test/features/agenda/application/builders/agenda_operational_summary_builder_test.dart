import 'package:flutter_test/flutter_test.dart';
import 'package:lacos_app/features/agenda/application/builders/agenda_operational_summary_builder.dart';
import 'package:lacos_app/features/agenda/application/models/agenda_appointment_display.dart';
import 'package:lacos_app/features/appointments/domain/enums/appointment_status.dart';

void main() {
  group('AgendaOperationalSummaryBuilder', () {
    final day = DateTime(2026, 7, 8);

    test('conta estados operacionais corretamente', () {
      final now = DateTime(2026, 7, 8, 12);

      final summary = AgendaOperationalSummaryBuilder.build([
        _display(
          id: 'overdue-1',
          status: AppointmentStatus.pending,
          startAt: DateTime(2026, 7, 8, 9),
          endAt: DateTime(2026, 7, 8, 10),
        ),
        _display(
          id: 'overdue-2',
          status: AppointmentStatus.confirmed,
          startAt: DateTime(2026, 7, 8, 10),
          endAt: DateTime(2026, 7, 8, 11),
        ),
        _display(
          id: 'current',
          status: AppointmentStatus.pending,
          startAt: DateTime(2026, 7, 8, 11, 30),
          endAt: DateTime(2026, 7, 8, 12, 30),
        ),
        _display(
          id: 'upcoming-1',
          status: AppointmentStatus.pending,
          startAt: DateTime(2026, 7, 8, 13),
          endAt: DateTime(2026, 7, 8, 14),
        ),
        _display(
          id: 'upcoming-2',
          status: AppointmentStatus.confirmed,
          startAt: DateTime(2026, 7, 8, 14),
          endAt: DateTime(2026, 7, 8, 15),
        ),
        _display(
          id: 'upcoming-3',
          status: AppointmentStatus.pending,
          startAt: DateTime(2026, 7, 8, 15),
          endAt: DateTime(2026, 7, 8, 16),
        ),
        _display(
          id: 'upcoming-4',
          status: AppointmentStatus.pending,
          startAt: DateTime(2026, 7, 8, 16),
          endAt: DateTime(2026, 7, 8, 17),
        ),
        _display(
          id: 'completed-1',
          status: AppointmentStatus.completed,
          startAt: DateTime(2026, 7, 8, 8),
          endAt: DateTime(2026, 7, 8, 9),
        ),
        _display(
          id: 'completed-2',
          status: AppointmentStatus.completed,
          startAt: DateTime(2026, 7, 8, 9, 30),
          endAt: DateTime(2026, 7, 8, 10, 30),
        ),
        _display(
          id: 'completed-3',
          status: AppointmentStatus.completed,
          startAt: DateTime(2026, 7, 8, 10, 30),
          endAt: DateTime(2026, 7, 8, 11, 30),
        ),
        _display(
          id: 'canceled',
          status: AppointmentStatus.canceled,
          startAt: DateTime(2026, 7, 8, 17),
          endAt: DateTime(2026, 7, 8, 18),
        ),
      ], now: now);

      expect(summary.overdueCount, 2);
      expect(summary.currentCount, 1);
      expect(summary.upcomingCount, 4);
      expect(summary.completedCount, 3);
      expect(summary.canceledCount, 1);
      expect(summary.hasActiveOperationalItems, isTrue);
    });

    test('retorna resumo vazio quando não há atendimentos', () {
      final summary = AgendaOperationalSummaryBuilder.build(const [], now: day);

      expect(summary.isEmpty, isTrue);
      expect(summary.hasActiveOperationalItems, isFalse);
    });
  });
}

AgendaAppointmentDisplay _display({
  required String id,
  required AppointmentStatus status,
  required DateTime startAt,
  required DateTime endAt,
}) {
  return AgendaAppointmentDisplay(
    appointmentId: id,
    clientId: 'client-$id',
    clientName: 'Cliente $id',
    servicesSummary: 'Corte',
    startAt: startAt,
    endAt: endAt,
    status: status,
  );
}
