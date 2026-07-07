import 'package:flutter_test/flutter_test.dart';
import 'package:lacos_app/features/agenda/application/models/agenda_appointment_display.dart';
import 'package:lacos_app/features/agenda/application/organizers/agenda_display_organizer.dart';
import 'package:lacos_app/features/appointments/domain/enums/appointment_canceled_by.dart';
import 'package:lacos_app/features/appointments/domain/enums/appointment_status.dart';

void main() {
  group('AgendaDisplayOrganizer', () {
    test('organiza pendentes, concluídos e cancelados', () {
      final day = DateTime(2026, 7, 7);

      final sections = AgendaDisplayOrganizer.organize([
        _display(id: 'canceled', status: AppointmentStatus.canceled, hour: 13),
        _display(id: 'pending', status: AppointmentStatus.pending, hour: 9),
        _display(id: 'confirmed', status: AppointmentStatus.confirmed, hour: 11),
        _display(id: 'completed', status: AppointmentStatus.completed, hour: 10),
      ]);

      expect(sections.pending.map((item) => item.appointmentId), ['pending', 'confirmed']);
      expect(sections.completed.map((item) => item.appointmentId), ['completed']);
      expect(sections.canceled.map((item) => item.appointmentId), ['canceled']);
      expect(sections.isEmpty, isFalse);
      expect(sections.showPendingHeader, isTrue);
      expect(sections.hasCompletedSection, isTrue);
      expect(sections.hasCanceledSection, isTrue);
    });

    test('não mostra cabeçalho de pendentes quando só existem pendentes', () {
      final sections = AgendaDisplayOrganizer.organize([
        _display(id: 'pending', status: AppointmentStatus.pending, hour: 9),
      ]);

      expect(sections.showPendingHeader, isFalse);
      expect(sections.pending.length, 1);
    });

    test('retorna vazio quando não há atendimentos', () {
      final sections = AgendaDisplayOrganizer.organize(const []);

      expect(sections.isEmpty, isTrue);
    });
  });
}

AgendaAppointmentDisplay _display({
  required String id,
  required AppointmentStatus status,
  required int hour,
}) {
  final startAt = DateTime(2026, 7, 7, hour);
  return AgendaAppointmentDisplay(
    appointmentId: id,
    clientName: 'Cliente $id',
    servicesSummary: 'Corte',
    startAt: startAt,
    endAt: startAt.add(const Duration(hours: 1)),
    status: status,
    canceledBy: status == AppointmentStatus.canceled
        ? AppointmentCanceledBy.client
        : null,
    cancellationReason: status == AppointmentStatus.canceled
        ? 'Cliente desistiu'
        : null,
  );
}
