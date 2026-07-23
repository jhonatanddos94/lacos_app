import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lacos_app/core/config/app_strings.dart';
import 'package:lacos_app/features/agenda/application/models/agenda_appointment_display.dart';
import 'package:lacos_app/features/agenda/presentation/widgets/agenda_header.dart';
import 'package:lacos_app/features/appointments/domain/enums/appointment_status.dart';

void main() {
  group('AgendaHeader operational summary', () {
    testWidgets('mostra resumo operacional apenas com categorias existentes', (
      tester,
    ) async {
      final referenceNow = DateTime(2026, 7, 8, 12);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AgendaHeader(
              selectedDay: DateTime(2026, 7, 8),
              referenceNow: referenceNow,
              appointments: [
                _display(
                  status: AppointmentStatus.pending,
                  startAt: DateTime(2026, 7, 8, 9),
                  endAt: DateTime(2026, 7, 8, 10),
                ),
                _display(
                  status: AppointmentStatus.pending,
                  startAt: DateTime(2026, 7, 8, 10),
                  endAt: DateTime(2026, 7, 8, 11),
                ),
                _display(
                  status: AppointmentStatus.pending,
                  startAt: DateTime(2026, 7, 8, 11, 30),
                  endAt: DateTime(2026, 7, 8, 12, 30),
                ),
                _display(
                  status: AppointmentStatus.pending,
                  startAt: DateTime(2026, 7, 8, 13),
                  endAt: DateTime(2026, 7, 8, 14),
                ),
              ],
              isLoading: false,
              onCalendarPressed: () {},
            ),
          ),
        ),
      );

      expect(
        find.text(
          '2 ${AppStrings.agendaOperationalSummaryOverdue} • '
          '1 ${AppStrings.agendaOperationalSummaryCurrent} • '
          '1 ${AppStrings.agendaOperationalSummaryUpcoming}',
        ),
        findsOneWidget,
      );
    });

    testWidgets('mostra nenhum atendimento quando a lista está vazia', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AgendaHeader(
              selectedDay: DateTime(2026, 7, 8),
              appointments: const [],
              isLoading: false,
              onCalendarPressed: () {},
            ),
          ),
        ),
      );

      expect(find.text(AppStrings.agendaOperationalSummaryNone), findsOneWidget);
    });
  });
}

AgendaAppointmentDisplay _display({
  required AppointmentStatus status,
  required DateTime startAt,
  required DateTime endAt,
}) {
  return AgendaAppointmentDisplay(
    appointmentId: 'appointment-${startAt.hour}',
    clientId: 'client-1',
    clientName: 'Cliente',
    servicesSummary: 'Corte',
    startAt: startAt,
    endAt: endAt,
    status: status,
  );
}
