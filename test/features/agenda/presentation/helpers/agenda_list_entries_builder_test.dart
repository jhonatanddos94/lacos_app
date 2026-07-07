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
        const AgendaDisplaySections(
          pending: [],
          completed: [],
          canceled: [],
        ),
      );

      expect(entries, isEmpty);
    });

    test('inclui seção cancelados quando houver itens', () {
      final entries = AgendaListEntriesBuilder.build(
        AgendaDisplaySections(
          canceled: [
            _display('canceled-1'),
          ],
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

AgendaAppointmentDisplay _display(String id) {
  final startAt = DateTime(2026, 7, 7, 13);
  return AgendaAppointmentDisplay(
    appointmentId: id,
    clientName: 'Beatriz',
    servicesSummary: 'Corte',
    startAt: startAt,
    endAt: startAt.add(const Duration(hours: 1)),
    status: AppointmentStatus.canceled,
  );
}
