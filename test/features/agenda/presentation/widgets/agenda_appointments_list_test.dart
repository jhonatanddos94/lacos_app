import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lacos_app/features/agenda/application/models/agenda_appointment_display.dart';
import 'package:lacos_app/features/agenda/presentation/widgets/agenda_appointments_list.dart';
import 'package:lacos_app/features/appointments/domain/enums/appointment_status.dart';
import 'package:lacos_app/features/home/presentation/widgets/schedule_item.dart';

void main() {
  group('AgendaScheduleListView', () {
    testWidgets('destaca apenas o appointment informado', (
      WidgetTester tester,
    ) async {
      final selectedDay = DateTime(2026, 7, 7);
      final scrollController = ScrollController();
      addTearDown(scrollController.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 600,
              child: AgendaScheduleListView(
                appointments: _appointments(selectedDay),
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

      expect(scheduleItems.length, 3);
      expect(scheduleItems.elementAt(0).isHighlighted, isFalse);
      expect(scheduleItems.elementAt(1).isHighlighted, isTrue);
      expect(scheduleItems.elementAt(2).isHighlighted, isFalse);
    });

    testWidgets('usa ScrollController informado', (WidgetTester tester) async {
      final selectedDay = DateTime(2026, 7, 7);
      final scrollController = ScrollController();
      addTearDown(scrollController.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 600,
              child: AgendaScheduleListView(
                appointments: _appointments(selectedDay),
                selectedDay: selectedDay,
                scrollController: scrollController,
              ),
            ),
          ),
        ),
      );

      final listView = tester.widget<ListView>(find.byType(ListView));
      expect(listView.controller, scrollController);
    });
  });
}

List<AgendaAppointmentDisplay> _appointments(DateTime day) {
  return [
    AgendaAppointmentDisplay(
      appointmentId: 'appointment-1',
      clientName: 'Ana',
      servicesSummary: 'Corte',
      startAt: DateTime(day.year, day.month, day.day, 9),
      endAt: DateTime(day.year, day.month, day.day, 10),
      status: AppointmentStatus.pending,
    ),
    AgendaAppointmentDisplay(
      appointmentId: 'appointment-2',
      clientName: 'Maria',
      servicesSummary: 'Hidratação',
      startAt: DateTime(day.year, day.month, day.day, 11),
      endAt: DateTime(day.year, day.month, day.day, 12),
      status: AppointmentStatus.pending,
    ),
    AgendaAppointmentDisplay(
      appointmentId: 'appointment-3',
      clientName: 'Joana',
      servicesSummary: 'Coloração',
      startAt: DateTime(day.year, day.month, day.day, 14),
      endAt: DateTime(day.year, day.month, day.day, 15),
      status: AppointmentStatus.pending,
    ),
  ];
}
