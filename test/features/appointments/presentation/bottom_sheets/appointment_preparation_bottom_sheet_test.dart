import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lacos_app/core/config/app_strings.dart';
import 'package:lacos_app/features/appointments/application/models/appointment_preparation_data.dart';
import 'package:lacos_app/features/appointments/application/models/appointment_preparation_memory_item.dart';
import 'package:lacos_app/features/appointments/presentation/bottom_sheets/appointment_preparation_bottom_sheet.dart';
import 'package:lacos_app/features/appointments/presentation/models/appointment_preparation_action.dart';

void main() {
  group('AppointmentPreparationBottomSheet', () {
    final dataWithMemories = AppointmentPreparationData(
      appointmentId: 'appointment-1',
      clientId: 'client-1',
      clientName: 'Maria Silva',
      clientPhotoUrl: null,
      servicesSummary: 'Corte • Hidratação',
      scheduleTimeLabel: '14:00 – 15:30',
      memories: [
        AppointmentPreparationMemoryItem(
          content: 'Vai casar em novembro.',
          displayEmoji: '💜',
          isPinned: false,
          priorityWeight: 0,
          sortAt: DateTime(2026, 7, 10),
        ),
        AppointmentPreparationMemoryItem(
          content: 'Prefere café sem açúcar.',
          displayEmoji: '☕',
          isPinned: false,
          priorityWeight: 0,
          sortAt: DateTime(2026, 7, 9),
        ),
      ],
    );

    const dataWithoutMemories = AppointmentPreparationData(
      appointmentId: 'appointment-1',
      clientId: 'client-1',
      clientName: 'Maria Silva',
      clientPhotoUrl: null,
      servicesSummary: 'Corte',
      scheduleTimeLabel: '14:00 – 15:00',
      memories: [],
    );

    Future<void> openSheet(
      WidgetTester tester,
      AppointmentPreparationData data,
    ) async {
      await tester.binding.setSurfaceSize(const Size(800, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return Center(
                  child: ElevatedButton(
                    onPressed: () {
                      showModalBottomSheet<AppointmentPreparationAction>(
                        context: context,
                        isScrollControlled: true,
                        builder: (context) =>
                            AppointmentPreparationBottomSheet(data: data),
                      );
                    },
                    child: const Text('open'),
                  ),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
    }

    testWidgets('exibe dados da cliente e memórias', (tester) async {
      await openSheet(tester, dataWithMemories);

      expect(
        find.text(AppStrings.appointmentPreparationTitle),
        findsOneWidget,
      );
      expect(find.text('Maria Silva'), findsOneWidget);
      expect(find.text(AppStrings.appointmentPreparationMemoriesSection), findsOneWidget);
      expect(find.text('Vai casar em novembro.'), findsOneWidget);
      expect(find.text('Prefere café sem açúcar.'), findsOneWidget);
    });

    testWidgets('exibe empty state quando não há memórias', (tester) async {
      await openSheet(tester, dataWithoutMemories);

      expect(
        find.text(AppStrings.appointmentPreparationMemoriesEmpty),
        findsOneWidget,
      );
    });

    testWidgets('Continuar retorna continueToAppointment', (tester) async {
      AppointmentPreparationAction? result;

      await tester.binding.setSurfaceSize(const Size(800, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return Center(
                  child: ElevatedButton(
                    onPressed: () async {
                      result = await showModalBottomSheet<
                          AppointmentPreparationAction>(
                        context: context,
                        isScrollControlled: true,
                        builder: (context) => AppointmentPreparationBottomSheet(
                          data: dataWithMemories,
                        ),
                      );
                    },
                    child: const Text('open'),
                  ),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.text(AppStrings.appointmentPreparationContinue),
      );
      await tester.tap(find.text(AppStrings.appointmentPreparationContinue));
      await tester.pumpAndSettle();

      expect(result, AppointmentPreparationAction.continueToAppointment);
    });

    testWidgets('Agora não retorna dismiss', (tester) async {
      AppointmentPreparationAction? result;

      await tester.binding.setSurfaceSize(const Size(800, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return Center(
                  child: ElevatedButton(
                    onPressed: () async {
                      result = await showModalBottomSheet<
                          AppointmentPreparationAction>(
                        context: context,
                        isScrollControlled: true,
                        builder: (context) => AppointmentPreparationBottomSheet(
                          data: dataWithMemories,
                        ),
                      );
                    },
                    child: const Text('open'),
                  ),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.text(AppStrings.appointmentPreparationNotNow),
      );
      await tester.tap(find.text(AppStrings.appointmentPreparationNotNow));
      await tester.pumpAndSettle();

      expect(result, AppointmentPreparationAction.dismiss);
    });
  });
}
