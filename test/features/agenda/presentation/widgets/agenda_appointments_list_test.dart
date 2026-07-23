import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lacos_app/core/config/app_strings.dart';
import 'package:lacos_app/features/agenda/application/models/agenda_appointment_display.dart';
import 'package:lacos_app/features/agenda/application/organizers/agenda_display_organizer.dart';
import 'package:lacos_app/features/agenda/presentation/widgets/agenda_appointments_list.dart';
import 'package:lacos_app/features/agenda/presentation/widgets/agenda_section_header.dart';
import 'package:lacos_app/features/appointments/domain/enums/appointment_canceled_by.dart';
import 'package:lacos_app/features/appointments/domain/enums/appointment_status.dart';
import 'package:lacos_app/features/home/presentation/widgets/schedule_item.dart';

void main() {
  group('AgendaAppointmentsList sections', () {
    testWidgets('organiza seções e mantém cancelados visíveis', (tester) async {
      final day = DateTime(2026, 7, 7);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 800,
              child: AgendaAppointmentsList(
                appointments: [
                  _display(
                    id: 'pending',
                    status: AppointmentStatus.pending,
                    hour: 9,
                    name: 'Ana',
                  ),
                  _display(
                    id: 'canceled',
                    status: AppointmentStatus.canceled,
                    hour: 13,
                    name: 'Beatriz',
                    canceledBy: AppointmentCanceledBy.client,
                    cancellationReason: 'Cliente desistiu',
                  ),
                ],
                selectedDay: day,
                scrollBottomPadding: 0,
              ),
            ),
          ),
        ),
      );

      expect(find.text('Ana'), findsOneWidget);
      expect(find.text('Beatriz'), findsOneWidget);
      expect(
        find.textContaining(AppStrings.agendaSectionCanceled),
        findsOneWidget,
      );
      expect(
        find.text(AppStrings.appointmentCanceledByClientLabel),
        findsOneWidget,
      );
      expect(find.text('Cliente desistiu'), findsOneWidget);
      expect(find.text(AppStrings.agendaEmptyDay), findsNothing);
    });

    testWidgets('mostra empty state apenas quando o dia está vazio', (
      tester,
    ) async {
      final day = DateTime(2026, 7, 7);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AgendaAppointmentsList(
              appointments: const [],
              selectedDay: day,
              scrollBottomPadding: 0,
            ),
          ),
        ),
      );

      expect(find.text(AppStrings.agendaEmptyDay), findsOneWidget);
    });

    testWidgets('não mostra empty state quando existem apenas cancelados', (
      tester,
    ) async {
      final day = DateTime(2026, 7, 7);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 400,
              child: AgendaAppointmentsList(
                appointments: [
                  _display(
                    id: 'canceled',
                    status: AppointmentStatus.canceled,
                    hour: 13,
                    name: 'Beatriz',
                  ),
                ],
                selectedDay: day,
                scrollBottomPadding: 0,
              ),
            ),
          ),
        ),
      );

      expect(find.text(AppStrings.agendaEmptyDay), findsNothing);
      expect(find.text('Beatriz'), findsOneWidget);
      expect(find.byType(AgendaSectionHeader), findsOneWidget);
    });

    testWidgets('exibe contadores nas seções da agenda', (tester) async {
      final day = DateTime(2026, 7, 7);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 800,
              child: AgendaAppointmentsList(
                appointments: [
                  _display(
                    id: 'pending',
                    status: AppointmentStatus.pending,
                    hour: 9,
                    name: 'Ana',
                  ),
                  _display(
                    id: 'completed',
                    status: AppointmentStatus.completed,
                    hour: 10,
                    name: 'Maria',
                  ),
                  _display(
                    id: 'canceled',
                    status: AppointmentStatus.canceled,
                    hour: 13,
                    name: 'Beatriz',
                  ),
                ],
                selectedDay: day,
                scrollBottomPadding: 0,
              ),
            ),
          ),
        ),
      );

      expect(
        find.text('${AppStrings.agendaSectionPending} (1)'),
        findsOneWidget,
      );
      expect(
        find.text('${AppStrings.agendaSectionCompleted} (1)'),
        findsOneWidget,
      );
      expect(
        find.text('${AppStrings.agendaSectionCanceled} (1)'),
        findsOneWidget,
      );
    });
  });

  group('AgendaScheduleListView', () {
    testWidgets('destaca apenas o appointment informado', (tester) async {
      final selectedDay = DateTime(2026, 7, 7);
      final appointments = [
        _display(
          id: 'appointment-1',
          status: AppointmentStatus.pending,
          hour: 9,
          name: 'Ana',
        ),
        _display(
          id: 'appointment-2',
          status: AppointmentStatus.pending,
          hour: 11,
          name: 'Maria',
        ),
      ];
      final scrollController = ScrollController();
      addTearDown(scrollController.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 600,
              child: AgendaScheduleListView(
                sections: AgendaDisplayOrganizer.organize(appointments),
                selectedDay: selectedDay,
                highlightedAppointmentId: 'appointment-2',
                scrollController: scrollController,
              ),
            ),
          ),
        ),
      );

      final scheduleItems = tester.widgetList<ScheduleItem>(
        find.byType(ScheduleItem),
      );

      expect(scheduleItems.length, 2);
      expect(scheduleItems.elementAt(0).isHighlighted, isFalse);
      expect(scheduleItems.elementAt(1).isHighlighted, isTrue);
    });
  });

  group('AgendaDisplayOrganizer', () {
    test('mantém cancelado na lista organizada', () {
      final sections = AgendaDisplayOrganizer.organize([
        _display(
          id: 'canceled',
          status: AppointmentStatus.canceled,
          hour: 13,
          name: 'Beatriz',
        ),
      ]);

      expect(sections.canceled.length, 1);
      expect(sections.isEmpty, isFalse);
    });
  });
}

AgendaAppointmentDisplay _display({
  required String id,
  required AppointmentStatus status,
  required int hour,
  required String name,
  AppointmentCanceledBy? canceledBy,
  String? cancellationReason,
}) {
  final startAt = DateTime(2026, 7, 7, hour);
  return AgendaAppointmentDisplay(
    appointmentId: id,
    clientId: 'client-$id',
    clientName: name,
    servicesSummary: 'Corte',
    startAt: startAt,
    endAt: startAt.add(const Duration(hours: 1)),
    status: status,
    canceledBy: canceledBy,
    cancellationReason: cancellationReason,
  );
}
