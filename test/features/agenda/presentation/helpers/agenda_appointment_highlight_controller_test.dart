import 'package:flutter_test/flutter_test.dart';
import 'package:lacos_app/core/config/app_durations.dart';
import 'package:lacos_app/features/agenda/application/models/agenda_appointment_display.dart';
import 'package:lacos_app/features/agenda/presentation/helpers/agenda_appointment_highlight_controller.dart';
import 'package:lacos_app/features/agenda/presentation/helpers/agenda_appointment_scroll.dart';
import 'package:lacos_app/features/appointments/domain/enums/appointment_status.dart';

void main() {
  group('AgendaAppointmentHighlightController', () {
    late AgendaAppointmentHighlightController controller;
    var changeCount = 0;

    setUp(() {
      controller = AgendaAppointmentHighlightController(
        highlightDuration: const Duration(milliseconds: 100),
      );
      changeCount = 0;
    });

    tearDown(() {
      controller.dispose();
    });

    test('marca appointment como destacado', () {
      controller.applyHighlight(
        appointmentId: 'appointment-1',
        onChanged: () => changeCount++,
      );

      expect(controller.highlightedAppointmentId, 'appointment-1');
      expect(controller.isHighlighted('appointment-1'), isTrue);
      expect(controller.isHighlighted('appointment-2'), isFalse);
      expect(changeCount, 1);
    });

    test('remove destaque após AppDurations.agendaHighlight', () async {
      controller.applyHighlight(
        appointmentId: 'appointment-1',
        onChanged: () => changeCount++,
      );

      await Future<void>.delayed(AppDurations.agendaHighlight + const Duration(milliseconds: 20));

      expect(controller.highlightedAppointmentId, isNull);
      expect(changeCount, 2);
    });
  });

  group('AgendaAppointmentScroll', () {
    final day = DateTime(2026, 7, 7);
    late List<AgendaAppointmentDisplay> appointments;

    setUp(() {
      appointments = [
        AgendaAppointmentDisplay(
          appointmentId: 'appointment-1',
          clientId: 'client-1',
          clientName: 'Ana',
          servicesSummary: 'Corte',
          startAt: DateTime(day.year, day.month, day.day, 9),
          endAt: DateTime(day.year, day.month, day.day, 10),
          status: AppointmentStatus.pending,
        ),
        AgendaAppointmentDisplay(
          appointmentId: 'appointment-2',
          clientId: 'client-2',
          clientName: 'Maria',
          servicesSummary: 'Hidratação',
          startAt: DateTime(day.year, day.month, day.day, 11),
          endAt: DateTime(day.year, day.month, day.day, 12),
          status: AppointmentStatus.pending,
        ),
      ];
    });

    test('indexForAppointmentId encontra índice correto', () {
      expect(
        AgendaAppointmentScroll.indexForAppointmentId(
          appointments,
          'appointment-2',
        ),
        1,
      );
    });

    test('indexForAppointmentId retorna null quando não encontra', () {
      expect(
        AgendaAppointmentScroll.indexForAppointmentId(
          appointments,
          'missing',
        ),
        isNull,
      );
    });

    test('offsetForIndex calcula offset acumulado', () {
      expect(AgendaAppointmentScroll.offsetForIndex(0), 0);
      expect(
        AgendaAppointmentScroll.offsetForIndex(2),
        2 * (AgendaAppointmentScroll.estimatedItemHeight +
            AgendaAppointmentScroll.separatorHeight),
      );
    });

    test('targetOffsetForIndex respeita maxScrollExtent', () {
      final target = AgendaAppointmentScroll.targetOffsetForIndex(
        index: 5,
        maxScrollExtent: 100,
        viewportHeight: 200,
      );

      expect(target, lessThanOrEqualTo(100));
      expect(target, greaterThanOrEqualTo(0));
    });
  });
}
