import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lacos_app/core/config/app_strings.dart';
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
      expect(find.text(AppStrings.appointmentCanceledByClientLabel), findsOneWidget);
      expect(find.text('Cliente desistiu'), findsOneWidget);
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
