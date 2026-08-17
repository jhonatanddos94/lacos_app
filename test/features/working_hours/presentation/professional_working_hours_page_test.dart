import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lacos_app/core/config/app_strings.dart';
import 'package:lacos_app/core/workspace/application/providers/workspace_providers.dart';
import 'package:lacos_app/core/workspace/domain/entities/workspace.dart';
import 'package:lacos_app/features/auth/domain/entities/authenticated_user.dart';
import 'package:lacos_app/features/professional/domain/entities/professional.dart';
import 'package:lacos_app/features/salon/domain/entities/salon.dart';
import 'package:lacos_app/features/working_hours/application/models/working_hours_day_draft.dart';
import 'package:lacos_app/features/working_hours/application/providers/working_hours_providers.dart';
import 'package:lacos_app/features/working_hours/presentation/helpers/working_hours_time_picker.dart';
import 'package:lacos_app/features/working_hours/presentation/pages/professional_working_hours_page.dart';
import 'package:lacos_app/features/working_hours/presentation/widgets/working_hours_day_row.dart';
import 'package:lacos_app/shared/widgets/buttons/app_button.dart';

import '../../../helpers/in_memory_professional_working_hours_repository.dart';

void main() {
  final now = DateTime(2026, 8, 14, 14);

  Workspace workspace({Professional? professional}) {
    return Workspace(
      user: const AuthenticatedUser(
        id: 'user-1',
        email: 'leticia@lacos.app',
        isEmailVerified: true,
      ),
      salon: Salon(
        id: 'salon-1',
        name: 'Studio Aurora',
        responsibleName: 'Leticia',
        isActive: true,
        createdAt: now,
        updatedAt: now,
      ),
      professional: professional ??
          Professional(
            id: 'pro-1',
            name: 'Leticia',
            isActive: true,
            createdAt: now,
            updatedAt: now,
          ),
    );
  }

  Future<void> pumpPage(
    WidgetTester tester, {
    required InMemoryProfessionalWorkingHoursRepository repository,
    Workspace? currentWorkspace,
    Size size = const Size(390, 900),
    TextScaler textScaler = TextScaler.noScaling,
  }) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          professionalWorkingHoursRepositoryProvider.overrideWithValue(
            repository,
          ),
          workspaceProvider.overrideWith(
            (ref) async => currentWorkspace ?? workspace(),
          ),
        ],
        child: MediaQuery(
          data: MediaQueryData(size: size, textScaler: textScaler),
          child: const MaterialApp(home: ProfessionalWorkingHoursPage()),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('O/P: UI mostra Seg–Dom com default 09–18', (tester) async {
    final repository = InMemoryProfessionalWorkingHoursRepository();
    await pumpPage(tester, repository: repository);

    expect(find.byKey(ProfessionalWorkingHoursPage.pageKey), findsOneWidget);
    expect(find.text(AppStrings.workingHoursSubtitle), findsOneWidget);
    expect(find.text('SEG'), findsOneWidget);
    expect(find.text('DOM'), findsOneWidget);
    expect(find.text('09:00'), findsWidgets);
    expect(find.text('18:00'), findsWidgets);
    expect(repository.findWeekCalls, 1);
  });

  testWidgets('Q/R: toggle Atende esconde horários', (tester) async {
    final repository = InMemoryProfessionalWorkingHoursRepository();
    await pumpPage(tester, repository: repository);

    final sundaySwitch = find.byKey(
      Key('working-hours-switch-${DateTime.sunday}'),
    );
    await tester.scrollUntilVisible(sundaySwitch, 120);
    await tester.pumpAndSettle();
    await tester.tap(sundaySwitch, warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(
      find.byKey(Key('working-hours-start-${DateTime.sunday}')),
      findsNothing,
    );
    expect(
      find.descendant(
        of: find.byKey(WorkingHoursDayRow.weekdayKey(DateTime.sunday)),
        matching: find.text(AppStrings.workingHoursNotWorkingLabel),
      ),
      findsOneWidget,
    );
  });

  testWidgets('U: salvar persiste semana inteira', (tester) async {
    final repository = InMemoryProfessionalWorkingHoursRepository();
    await pumpPage(tester, repository: repository);

    final saveButton = find.byKey(ProfessionalWorkingHoursPage.saveButtonKey);
    await tester.scrollUntilVisible(saveButton, 120);
    await tester.pumpAndSettle();
    await tester.tap(saveButton);
    await tester.pumpAndSettle();

    expect(repository.saveWeekCalls, 1);
    expect(find.byType(ProfessionalWorkingHoursPage), findsNothing);
  });

  testWidgets('V/W: erro mantém tela e mensagem sanitizada', (tester) async {
    final repository = InMemoryProfessionalWorkingHoursRepository()
      ..saveError = Exception('Parse secret token');
    await pumpPage(tester, repository: repository);

    final saveButton = find.byKey(ProfessionalWorkingHoursPage.saveButtonKey);
    await tester.scrollUntilVisible(saveButton, 120);
    await tester.pumpAndSettle();
    await tester.tap(saveButton);
    await tester.pumpAndSettle();

    expect(repository.saveWeekCalls, 1);
    expect(find.byType(ProfessionalWorkingHoursPage), findsOneWidget);
    expect(find.byKey(ProfessionalWorkingHoursPage.saveErrorKey), findsOneWidget);
    expect(find.text(AppStrings.workingHoursSaveError), findsOneWidget);
    expect(find.textContaining('secret'), findsNothing);
  });

  testWidgets('X: duplo save bloqueado', (tester) async {
    final repository = InMemoryProfessionalWorkingHoursRepository()
      ..saveGate = Completer<void>();
    await pumpPage(tester, repository: repository);

    final saveButton = find.byKey(ProfessionalWorkingHoursPage.saveButtonKey);
    await tester.scrollUntilVisible(saveButton, 120);
    await tester.pumpAndSettle();
    await tester.tap(saveButton);
    await tester.pump();

    final loadingButton = tester.widget<AppButton>(saveButton);
    expect(loadingButton.isLoading, isTrue);
    expect(loadingButton.onPressed, isNull);

    repository.saveGate!.complete();
    await tester.pumpAndSettle();
  });

  testWidgets('Y–AA: 320px e textScale 1.3/1.5 sem overflow', (tester) async {
    for (final scale in [1.0, 1.3, 1.5]) {
      final repository = InMemoryProfessionalWorkingHoursRepository();
      await pumpPage(
        tester,
        repository: repository,
        size: const Size(320, 900),
        textScaler: TextScaler.linear(scale),
      );
      expect(tester.takeException(), isNull);
      await tester.scrollUntilVisible(
        find.byKey(WorkingHoursDayRow.weekdayKey(DateTime.sunday)),
        120,
      );
      expect(tester.takeException(), isNull);
    }
  });

  test('AB/AC: domingo aparece como dia normal no draft default', () {
    final week = WorkingHoursWeekFactory.defaultWeek();
    final sunday = week.singleWhere((day) => day.weekday == DateTime.sunday);

    expect(week.length, DateTime.daysPerWeek);
    expect(sunday.isWorking, isTrue);
    expect(sunday.startMinutes, 9 * 60);
    expect(sunday.endMinutes, 18 * 60);
  });

  test('J: time picker snap usa granularidade de 15 min', () {
    expect(snapWorkingHoursMinutes(9 * 60 + 7), 9 * 60);
    expect(snapWorkingHoursMinutes(9 * 60 + 8), 9 * 60 + 15);
  });
}
