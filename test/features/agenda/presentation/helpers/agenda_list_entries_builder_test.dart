import 'package:flutter_test/flutter_test.dart';
import 'package:lacos_app/core/config/app_strings.dart';
import 'package:lacos_app/features/agenda/application/models/agenda_appointment_display.dart';
import 'package:lacos_app/features/agenda/application/models/agenda_display_sections.dart';
import 'package:lacos_app/features/agenda/presentation/helpers/agenda_list_entries_builder.dart';
import 'package:lacos_app/features/appointments/domain/enums/appointment_status.dart';

void main() {
  group('AgendaListEntriesBuilder', () {
    test('monta entradas com cabeçalhos de seção', () {
      final entries = AgendaListEntriesBuilder.build(
        const AgendaDisplaySections(pending: [], completed: [], canceled: []),
      );

      expect(entries, isEmpty);
    });

    test('inclui contadores nas seções quando houver itens', () {
      final entries = AgendaListEntriesBuilder.build(
        AgendaDisplaySections(
          pending: [
            _display('pending-1', AppointmentStatus.pending),
            _display('pending-2', AppointmentStatus.confirmed),
          ],
          completed: [_display('completed-1', AppointmentStatus.completed)],
          canceled: [_display('canceled-1', AppointmentStatus.canceled)],
        ),
      );

      expect(
        entries.any(
          (entry) => entry.title == '${AppStrings.agendaSectionPending} (2)',
        ),
        isTrue,
      );
      expect(
        entries.any(
          (entry) => entry.title == '${AppStrings.agendaSectionCompleted} (1)',
        ),
        isTrue,
      );
      expect(
        entries.any(
          (entry) => entry.title == '${AppStrings.agendaSectionCanceled} (1)',
        ),
        isTrue,
      );
    });

    test('inclui seção cancelados quando houver itens', () {
      final entries = AgendaListEntriesBuilder.build(
        AgendaDisplaySections(
          canceled: [_display('canceled-1', AppointmentStatus.canceled)],
        ),
      );

      expect(
        entries.any(
          (entry) =>
              entry.title?.startsWith(AppStrings.agendaSectionCanceled) ??
              false,
        ),
        isTrue,
      );
      expect(
        AgendaListEntriesBuilder.indexForAppointmentId(entries, 'canceled-1'),
        isNotNull,
      );
    });
  });
}

AgendaAppointmentDisplay _display(String id, AppointmentStatus status) {
  final startAt = DateTime(2026, 7, 7, 13);
  return AgendaAppointmentDisplay(
    appointmentId: id,
    clientId: 'client-1',
    clientName: 'Beatriz',
    servicesSummary: 'Corte',
    startAt: startAt,
    endAt: startAt.add(const Duration(hours: 1)),
    status: status,
  );
}
