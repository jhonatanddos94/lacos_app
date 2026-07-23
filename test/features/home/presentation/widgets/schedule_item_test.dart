import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lacos_app/core/config/app_strings.dart';
import 'package:lacos_app/features/appointments/domain/enums/appointment_operational_state.dart';
import 'package:lacos_app/features/home/domain/entities/home_dashboard_data.dart';
import 'package:lacos_app/features/home/presentation/widgets/schedule_item.dart';

void main() {
  group('ScheduleItem', () {
    testWidgets('exibe subtítulo de cancelamento e motivo', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ScheduleItem(
              appointment: TodayScheduleAppointment(
                startTime: '13:00',
                endTime: '14:00',
                clientName: 'Beatriz',
                serviceName: 'Corte',
                status: ScheduleStatus.canceled,
                statusSubtitle: AppStrings.appointmentCanceledByClientLabel,
                statusDetail: 'Cliente desistiu',
              ),
            ),
          ),
        ),
      );

      expect(find.text('Cancelado'), findsOneWidget);
      expect(
        find.text(AppStrings.appointmentCanceledByClientLabel),
        findsOneWidget,
      );
      expect(find.text('Cliente desistiu'), findsOneWidget);
    });

    testWidgets('overdue nunca exibe badge Pendente', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ScheduleItem(
              appointment: TodayScheduleAppointment(
                startTime: '09:00',
                endTime: '10:00',
                clientName: 'Ana',
                serviceName: 'Corte',
                status: ScheduleStatus.pending,
                operationalState: AppointmentOperationalState.overdue,
              ),
            ),
          ),
        ),
      );

      expect(find.text('Pendente'), findsNothing);
      expect(find.text('Confirmado'), findsNothing);
      expect(
        find.text(AppStrings.appointmentOperationalStateOverdueLabel),
        findsOneWidget,
      );
    });

    testWidgets('upcoming confirmado exibe Agendado em vez de Confirmado', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ScheduleItem(
              appointment: TodayScheduleAppointment(
                startTime: '14:00',
                endTime: '15:00',
                clientName: 'Maria',
                serviceName: 'Corte',
                status: ScheduleStatus.confirmed,
                operationalState: AppointmentOperationalState.upcoming,
              ),
            ),
          ),
        ),
      );

      expect(find.text('Confirmado'), findsNothing);
      expect(find.text('Pendente'), findsNothing);
      expect(
        find.text(AppStrings.appointmentOperationalStateUpcomingLabel),
        findsOneWidget,
      );
    });

    testWidgets('exibe borda âmbar no card overdue', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ScheduleItem(
              appointment: TodayScheduleAppointment(
                startTime: '09:00',
                endTime: '10:00',
                clientName: 'Ana',
                serviceName: 'Corte',
                status: ScheduleStatus.pending,
                operationalState: AppointmentOperationalState.overdue,
              ),
            ),
          ),
        ),
      );

      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is AnimatedContainer &&
              widget.decoration is BoxDecoration &&
              (widget.decoration! as BoxDecoration).color ==
                  const Color(0xFFB8741A),
        ),
        findsOneWidget,
      );
      expect(
        find.text(AppStrings.appointmentOperationalStateOverdueLabel),
        findsOneWidget,
      );
    });

    testWidgets('exibe badge aguardando conclusão para overdue', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ScheduleItem(
              appointment: TodayScheduleAppointment(
                startTime: '09:00',
                endTime: '10:00',
                clientName: 'Ana',
                serviceName: 'Corte',
                status: ScheduleStatus.pending,
                operationalState: AppointmentOperationalState.overdue,
              ),
            ),
          ),
        ),
      );

      expect(
        find.text(AppStrings.appointmentOperationalStateOverdueLabel),
        findsOneWidget,
      );
    });

    testWidgets('exibe badge em andamento para current', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ScheduleItem(
              appointment: TodayScheduleAppointment(
                startTime: '10:00',
                endTime: '11:00',
                clientName: 'Maria',
                serviceName: 'Corte',
                status: ScheduleStatus.confirmed,
                operationalState: AppointmentOperationalState.current,
              ),
            ),
          ),
        ),
      );

      expect(
        find.text(AppStrings.appointmentOperationalStateCurrentLabel),
        findsOneWidget,
      );
    });

    testWidgets('exibe badge concluído para completed', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ScheduleItem(
              appointment: TodayScheduleAppointment(
                startTime: '10:00',
                endTime: '11:00',
                clientName: 'Maria',
                serviceName: 'Corte',
                status: ScheduleStatus.completed,
              ),
            ),
          ),
        ),
      );

      expect(find.text('Concluído'), findsOneWidget);
    });
  });
}
