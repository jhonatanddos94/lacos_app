import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lacos_app/core/config/app_strings.dart';
import 'package:lacos_app/features/appointments/presentation/bottom_sheets/complete_appointment_success_bottom_sheet.dart';
import 'package:lacos_app/features/appointments/presentation/helpers/complete_appointment_success_sheet_host.dart';
import 'package:lacos_app/features/appointments/presentation/models/complete_appointment_success_action.dart';

void main() {
  group('CompleteAppointmentSuccessBottomSheet', () {
    Future<void> openSheet(WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return Center(
                  child: ElevatedButton(
                    onPressed: () {
                      showCompleteAppointmentSuccessBottomSheet(
                        context: context,
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

    testWidgets('exibe conteúdo de celebração e convite para memória', (
      tester,
    ) async {
      await openSheet(tester);

      expect(
        find.text(AppStrings.appointmentCompleteSuccessSheetTitle),
        findsOneWidget,
      );
      expect(
        find.text(AppStrings.appointmentCompleteSuccessSheetMessage),
        findsOneWidget,
      );
      expect(
        find.text(AppStrings.appointmentCompleteSuccessMemoryPrompt),
        findsOneWidget,
      );
      expect(
        find.text(AppStrings.appointmentCompleteSuccessMemoryHint),
        findsOneWidget,
      );
      expect(
        find.text(AppStrings.appointmentCompleteSuccessRegisterMemory),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
    });

    testWidgets('Agora não retorna dismiss', (tester) async {
      CompleteAppointmentSuccessAction? result;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return Center(
                  child: ElevatedButton(
                    onPressed: () async {
                      result = await showCompleteAppointmentSuccessBottomSheet(
                        context: context,
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
      await tester.tap(find.text(AppStrings.appointmentCompleteSuccessNotNow));
      await tester.pumpAndSettle();

      expect(result, CompleteAppointmentSuccessAction.dismiss);
      expect(find.byType(CompleteAppointmentSuccessBottomSheet), findsNothing);
    });

    testWidgets('Registrar memória retorna addMemory', (tester) async {
      CompleteAppointmentSuccessAction? result;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return Center(
                  child: ElevatedButton(
                    onPressed: () async {
                      result = await showCompleteAppointmentSuccessBottomSheet(
                        context: context,
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
      await tester.tap(
        find.text(AppStrings.appointmentCompleteSuccessRegisterMemory),
      );
      await tester.pumpAndSettle();

      expect(result, CompleteAppointmentSuccessAction.addMemory);
      expect(find.byType(CompleteAppointmentSuccessBottomSheet), findsNothing);
    });
  });
}
