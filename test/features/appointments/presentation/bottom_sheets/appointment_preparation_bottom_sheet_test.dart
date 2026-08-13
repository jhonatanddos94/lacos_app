import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lacos_app/core/config/app_strings.dart';
import 'package:lacos_app/features/appointments/application/models/appointment_preparation_data.dart';
import 'package:lacos_app/features/appointments/presentation/bottom_sheets/appointment_preparation_bottom_sheet.dart';
import 'package:lacos_app/features/appointments/presentation/models/appointment_preparation_action.dart';
import 'package:lacos_app/features/memories/application/memory_providers.dart';
import 'package:lacos_app/features/memories/domain/entities/client_memory.dart';

import '../../helpers/gated_client_memory_repository.dart';

void main() {
  group('AppointmentPreparationBottomSheet', () {
    const data = AppointmentPreparationData(
      appointmentId: 'appointment-1',
      clientId: 'client-1',
      clientName: 'Maria Silva',
      clientPhotoUrl: null,
      servicesSummary: 'Corte • Hidratação',
      scheduleTimeLabel: '14:00 – 15:30',
      memories: [],
    );

    final memories = [
      gatedMemory(id: 'm1', content: 'Vai casar em novembro.'),
      gatedMemory(id: 'm2', content: 'Prefere café sem açúcar.'),
    ];

    Future<void> openSheet(
      WidgetTester tester, {
      required GatedClientMemoryRepository repository,
    }) async {
      await tester.binding.setSurfaceSize(const Size(800, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            clientMemoryRepositoryProvider.overrideWithValue(repository),
          ],
          child: MaterialApp(
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
                              const AppointmentPreparationBottomSheet(
                                data: data,
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
        ),
      );

      await tester.tap(find.text('open'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
    }

    testWidgets('exibe dados da cliente antes das memórias', (tester) async {
      final repository = GatedClientMemoryRepository(
        findCompleter: Completer<List<ClientMemory>>(),
        memories: memories,
      );

      await openSheet(tester, repository: repository);

      expect(find.text(AppStrings.appointmentPreparationTitle), findsOneWidget);
      expect(find.text('Maria Silva'), findsOneWidget);
      expect(
        find.textContaining('Corte • Hidratação', findRichText: true),
        findsOneWidget,
      );
      expect(
        find.textContaining('14:00 – 15:30', findRichText: true),
        findsOneWidget,
      );
      expect(
        find.byKey(AppointmentPreparationBottomSheet.memoriesLoadingKey),
        findsOneWidget,
      );
      expect(find.text('Vai casar em novembro.'), findsNothing);
    });

    testWidgets('exibe dados da cliente e memórias', (tester) async {
      final repository = GatedClientMemoryRepository(memories: memories);

      await openSheet(tester, repository: repository);
      await tester.pump();

      expect(find.text(AppStrings.appointmentPreparationTitle), findsOneWidget);
      expect(find.text('Maria Silva'), findsOneWidget);
      expect(
        find.text(AppStrings.appointmentPreparationMemoriesSection),
        findsOneWidget,
      );
      expect(find.text('Vai casar em novembro.'), findsOneWidget);
      expect(find.text('Prefere café sem açúcar.'), findsOneWidget);
    });

    testWidgets('exibe empty state quando não há memórias', (tester) async {
      await openSheet(tester, repository: GatedClientMemoryRepository());
      await tester.pump();

      expect(
        find.text(AppStrings.appointmentPreparationMemoriesEmpty),
        findsOneWidget,
      );
    });

    testWidgets('Continuar retorna continueToAppointment', (tester) async {
      AppointmentPreparationAction? result;
      final repository = GatedClientMemoryRepository(memories: memories);

      await tester.binding.setSurfaceSize(const Size(800, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            clientMemoryRepositoryProvider.overrideWithValue(repository),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  return Center(
                    child: ElevatedButton(
                      onPressed: () async {
                        result =
                            await showModalBottomSheet<
                              AppointmentPreparationAction
                            >(
                              context: context,
                              isScrollControlled: true,
                              builder: (context) =>
                                  const AppointmentPreparationBottomSheet(
                                    data: data,
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
      final repository = GatedClientMemoryRepository(memories: memories);

      await tester.binding.setSurfaceSize(const Size(800, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            clientMemoryRepositoryProvider.overrideWithValue(repository),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  return Center(
                    child: ElevatedButton(
                      onPressed: () async {
                        result =
                            await showModalBottomSheet<
                              AppointmentPreparationAction
                            >(
                              context: context,
                              isScrollControlled: true,
                              builder: (context) =>
                                  const AppointmentPreparationBottomSheet(
                                    data: data,
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

    testWidgets('duplo Continuar não empilha dois pops', (tester) async {
      var popCount = 0;
      final repository = GatedClientMemoryRepository(memories: memories);

      await tester.binding.setSurfaceSize(const Size(800, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            clientMemoryRepositoryProvider.overrideWithValue(repository),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  return Center(
                    child: ElevatedButton(
                      onPressed: () async {
                        await showModalBottomSheet<
                          AppointmentPreparationAction
                        >(
                          context: context,
                          isScrollControlled: true,
                          builder: (context) =>
                              const AppointmentPreparationBottomSheet(
                                data: data,
                              ),
                        );
                        popCount++;
                      },
                      child: const Text('open'),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text(AppStrings.appointmentPreparationContinue));
      await tester.tap(
        find.text(AppStrings.appointmentPreparationContinue),
        warnIfMissed: false,
      );
      await tester.pumpAndSettle();

      expect(popCount, 1);
    });
  });
}
