import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lacos_app/core/theme/app_colors.dart';
import 'package:lacos_app/features/home/domain/entities/home_dashboard_data.dart';
import 'package:lacos_app/features/home/presentation/widgets/schedule_item.dart';

void main() {
  group('ScheduleItem', () {
    testWidgets('aplica destaque visual quando isHighlighted é true', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ScheduleItem(
              appointment: _appointment(),
              isHighlighted: true,
            ),
          ),
        ),
      );

      final animatedContainers = tester.widgetList<AnimatedContainer>(
        find.byType(AnimatedContainer),
      );

      expect(
        animatedContainers.any(
          (container) =>
              container.decoration is BoxDecoration &&
              (container.decoration! as BoxDecoration).border?.top.color ==
                  AppColors.purple300,
        ),
        isTrue,
      );
    });

    testWidgets('não aplica borda de destaque quando isHighlighted é false', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ScheduleItem(
              appointment: _appointment(),
              isHighlighted: false,
            ),
          ),
        ),
      );

      final animatedContainers = tester.widgetList<AnimatedContainer>(
        find.byType(AnimatedContainer),
      );

      expect(
        animatedContainers.any(
          (container) =>
              container.decoration is BoxDecoration &&
              (container.decoration! as BoxDecoration).border != null,
        ),
        isFalse,
      );
    });
  });
}

TodayScheduleAppointment _appointment() {
  return const TodayScheduleAppointment(
    startTime: '10:00',
    endTime: '11:00',
    clientName: 'Maria Silva',
    serviceName: 'Corte',
    status: ScheduleStatus.pending,
  );
}
