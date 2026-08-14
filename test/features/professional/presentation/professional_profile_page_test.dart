import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lacos_app/core/config/app_strings.dart';
import 'package:lacos_app/core/time/application/providers/clock_providers.dart';
import 'package:lacos_app/core/workspace/application/providers/workspace_providers.dart';
import 'package:lacos_app/core/workspace/domain/entities/workspace.dart';
import 'package:lacos_app/features/agenda/application/agenda_day.dart';
import 'package:lacos_app/features/agenda/application/providers/agenda_providers.dart';
import 'package:lacos_app/features/agenda/application/providers/calendar_today_providers.dart';
import 'package:lacos_app/features/auth/application/providers/remember_me_providers.dart';
import 'package:lacos_app/features/auth/domain/entities/authenticated_user.dart';
import 'package:lacos_app/features/home/application/providers/home_upcoming_days_provider.dart';
import 'package:lacos_app/features/home/presentation/pages/home_page.dart';
import 'package:lacos_app/features/home/presentation/widgets/home_header.dart';
import 'package:lacos_app/features/professional/application/providers/professional_providers.dart';
import 'package:lacos_app/features/professional/domain/entities/professional.dart';
import 'package:lacos_app/features/professional/presentation/bottom_sheets/professional_profile_form_bottom_sheet.dart';
import 'package:lacos_app/features/professional/presentation/navigation/professional_profile_navigation.dart';
import 'package:lacos_app/features/professional/presentation/pages/professional_profile_page.dart';
import 'package:lacos_app/features/salon/domain/entities/salon.dart';
import 'package:lacos_app/shared/widgets/buttons/app_button.dart';
import 'package:lacos_app/shared/widgets/inputs/app_text_field.dart';

import '../../../helpers/home_test_fixtures.dart';
import '../../../helpers/in_memory_professional_repository.dart';
import '../../../helpers/in_memory_remember_me_preference_repository.dart';

void main() {
  final now = homeTestNow;

  setUp(resetProfessionalProfileNavigationGuardForTest);
  tearDown(resetProfessionalProfileNavigationGuardForTest);

  Professional leticia({String? specialties = 'Cabeleireira'}) {
    return Professional(
      id: 'professional-1',
      name: 'Leticia',
      specialties: specialties,
      isActive: true,
      createdAt: DateTime(2026, 8, 13),
      updatedAt: DateTime(2026, 8, 13),
    );
  }

  Workspace workspaceFor(
    Professional? professional, {
    String email = 'leticia@lacos.app',
  }) {
    return Workspace(
      user: AuthenticatedUser(
        id: 'user-1',
        email: email,
        isEmailVerified: true,
      ),
      salon: Salon(
        id: 'salon-1',
        name: 'Studio Aurora',
        responsibleName: 'Leticia',
        isActive: true,
        createdAt: DateTime(2026, 8, 13),
        updatedAt: DateTime(2026, 8, 13),
      ),
      professional: professional,
    );
  }

  Future<void> pumpProfile(
    WidgetTester tester, {
    required InMemoryProfessionalRepository repository,
    Size size = const Size(420, 1200),
    TextScaler textScaler = TextScaler.noScaling,
    String email = 'leticia@lacos.app',
    List<Override> extraOverrides = const [],
  }) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          professionalRepositoryProvider.overrideWithValue(repository),
          workspaceProvider.overrideWith((ref) async {
            return workspaceFor(
              await repository.getCurrentProfessional(),
              email: email,
            );
          }),
          ...extraOverrides,
        ],
        child: MediaQuery(
          data: MediaQueryData(size: size, textScaler: textScaler),
          child: const MaterialApp(home: ProfessionalProfilePage()),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> openEditor(WidgetTester tester) async {
    final editButton = find.byKey(ProfessionalProfilePage.editButtonKey);
    await tester.scrollUntilVisible(
      editButton,
      80,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(editButton);
    await tester.pumpAndSettle();
  }

  testWidgets(
    'A/B/C/E: perfil abre com dados atuais e e-mail somente leitura',
    (tester) async {
      await pumpProfile(
        tester,
        repository: InMemoryProfessionalRepository(current: leticia()),
      );

      expect(find.text('Leticia'), findsWidgets);
      expect(find.text('Cabeleireira'), findsWidgets);
      expect(find.text('leticia@lacos.app'), findsOneWidget);
      expect(find.byType(AppTextField), findsNothing);
      expect(find.byKey(ProfessionalProfilePage.editButtonKey), findsOneWidget);
      expect(
        find.byKey(ProfessionalProfilePage.logoutButtonKey),
        findsOneWidget,
      );
    },
  );

  testWidgets('D: especialidade ausente não quebra layout', (tester) async {
    await pumpProfile(
      tester,
      repository: InMemoryProfessionalRepository(
        current: leticia(specialties: null),
      ),
    );

    expect(find.text('Leticia'), findsWidgets);
    expect(find.text('Cabeleireira'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('F: Editar perfil abre o formulário', (tester) async {
    await pumpProfile(
      tester,
      repository: InMemoryProfessionalRepository(current: leticia()),
    );

    await openEditor(tester);

    expect(find.byType(ProfessionalProfileFormBottomSheet), findsOneWidget);
    expect(
      find.byKey(ProfessionalProfileFormBottomSheet.saveButtonKey),
      findsOneWidget,
    );
    expect(find.text(AppStrings.professionalProfileSaveAction), findsOneWidget);
  });

  testWidgets('G/H/I/N: salvar atualiza perfil com trim', (tester) async {
    final repository = InMemoryProfessionalRepository(current: leticia());
    await pumpProfile(tester, repository: repository);
    await openEditor(tester);

    await tester.enterText(
      find.byKey(ProfessionalProfileFormBottomSheet.nameFieldKey),
      '  Carolina  ',
    );
    await tester.enterText(
      find.byKey(ProfessionalProfileFormBottomSheet.specialtiesFieldKey),
      '  Colorista  ',
    );
    await tester.tap(
      find.byKey(ProfessionalProfileFormBottomSheet.saveButtonKey),
    );
    await tester.pumpAndSettle();

    expect(find.byType(ProfessionalProfileFormBottomSheet), findsNothing);
    expect(find.text('Carolina'), findsWidgets);
    expect(find.text('Colorista'), findsWidgets);
    expect(repository.current?.name, 'Carolina');
    expect(repository.current?.specialties, 'Colorista');
    expect(repository.current?.id, 'professional-1');
  });

  testWidgets('J: nome inválido bloqueia save', (tester) async {
    final repository = InMemoryProfessionalRepository(current: leticia());
    await pumpProfile(tester, repository: repository);
    await openEditor(tester);

    await tester.enterText(
      find.byKey(ProfessionalProfileFormBottomSheet.nameFieldKey),
      '   ',
    );
    await tester.tap(
      find.byKey(ProfessionalProfileFormBottomSheet.saveButtonKey),
    );
    await tester.pump();

    expect(
      find.text(AppStrings.professionalProfileNameRequired),
      findsOneWidget,
    );
    expect(find.byType(ProfessionalProfileFormBottomSheet), findsOneWidget);
    expect(repository.updateCalls, 0);
  });

  testWidgets('K: loading impede duplo submit', (tester) async {
    final completer = Completer<Professional>();
    final repository = _DelayedProfessionalRepository(
      current: leticia(),
      completer: completer,
    );
    await pumpProfile(tester, repository: repository);
    await openEditor(tester);

    await tester.enterText(
      find.byKey(ProfessionalProfileFormBottomSheet.nameFieldKey),
      'Carolina',
    );
    await tester.tap(
      find.byKey(ProfessionalProfileFormBottomSheet.saveButtonKey),
    );
    await tester.pump();
    await tester.tap(
      find.byKey(ProfessionalProfileFormBottomSheet.saveButtonKey),
      warnIfMissed: false,
    );
    await tester.pump();

    expect(repository.updateCalls, 1);
    expect(
      tester
          .widget<AppButton>(
            find.byKey(ProfessionalProfileFormBottomSheet.saveButtonKey),
          )
          .onPressed,
      isNull,
    );

    completer.complete(repository.current!);
    await tester.pumpAndSettle();
  });

  testWidgets('L/M: erro sanitizado mantém edição', (tester) async {
    final repository = InMemoryProfessionalRepository(current: leticia())
      ..updateError = Exception('ParseException boom token');
    await pumpProfile(tester, repository: repository);
    await openEditor(tester);

    await tester.enterText(
      find.byKey(ProfessionalProfileFormBottomSheet.nameFieldKey),
      'Carolina',
    );
    await tester.tap(
      find.byKey(ProfessionalProfileFormBottomSheet.saveButtonKey),
    );
    await tester.pumpAndSettle();

    expect(find.byType(ProfessionalProfileFormBottomSheet), findsOneWidget);
    expect(
      find.text(AppStrings.professionalProfileUpdateError),
      findsOneWidget,
    );
    expect(find.textContaining('token'), findsNothing);
    expect(find.textContaining('ParseException'), findsNothing);
    expect(
      tester
          .widget<TextField>(
            find.descendant(
              of: find.byKey(ProfessionalProfileFormBottomSheet.nameFieldKey),
              matching: find.byType(TextField),
            ),
          )
          .controller
          ?.text,
      'Carolina',
    );
  });

  testWidgets('O/P: sucesso atualiza HomeHeader e professionalsProvider', (
    tester,
  ) async {
    final repository = InMemoryProfessionalRepository(current: leticia());
    var professionalListReads = 0;
    await tester.binding.setSurfaceSize(const Size(420, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appClockProvider.overrideWithValue(FakeAppClock(now)),
          calendarTodayProvider.overrideWithValue(AgendaDay.from(now)),
          professionalRepositoryProvider.overrideWithValue(repository),
          workspaceProvider.overrideWith((ref) async {
            return workspaceFor(await repository.getCurrentProfessional());
          }),
          professionalsProvider.overrideWith((ref) async {
            professionalListReads++;
            return repository.findAll();
          }),
          agendaAppointmentsDisplayProvider.overrideWith(
            (ref, day) async => const [],
          ),
          homeUpcomingDaysProvider.overrideWith((ref) async => const []),
        ],
        child: const MaterialApp(
          home: Stack(
            fit: StackFit.expand,
            children: [HomePage(), _ProfessionalsProbe()],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Leticia'), findsWidgets);
    final readsAfterHome = professionalListReads;

    await tester.tap(find.byKey(HomeHeader.profileAvatarKey));
    await tester.pumpAndSettle();
    await openEditor(tester);
    await tester.enterText(
      find.byKey(ProfessionalProfileFormBottomSheet.nameFieldKey),
      'Carolina',
    );
    await tester.tap(
      find.byKey(ProfessionalProfileFormBottomSheet.saveButtonKey),
    );
    await tester.pumpAndSettle();

    expect(find.text('Carolina'), findsWidgets);
    expect(professionalListReads, greaterThan(readsAfterHome));

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.textContaining('Carolina'), findsWidgets);
  });

  testWidgets('S: logout continua visível e separado da edição', (
    tester,
  ) async {
    await pumpProfile(
      tester,
      repository: InMemoryProfessionalRepository(current: leticia()),
    );

    expect(
      find.text(AppStrings.professionalProfileAccountSection),
      findsOneWidget,
    );
    expect(find.byKey(ProfessionalProfilePage.logoutButtonKey), findsOneWidget);
    expect(find.byType(ProfessionalProfileFormBottomSheet), findsNothing);
  });

  testWidgets('T: salvar perfil não altera remember-me', (tester) async {
    final repository = InMemoryProfessionalRepository(current: leticia());
    final rememberMe = InMemoryRememberMePreferenceRepository(value: true);

    await pumpProfile(
      tester,
      repository: repository,
      extraOverrides: [
        rememberMePreferenceRepositoryProvider.overrideWithValue(rememberMe),
      ],
    );
    await openEditor(tester);
    await tester.enterText(
      find.byKey(ProfessionalProfileFormBottomSheet.nameFieldKey),
      'Carolina',
    );
    await tester.tap(
      find.byKey(ProfessionalProfileFormBottomSheet.saveButtonKey),
    );
    await tester.pumpAndSettle();

    expect(repository.current?.name, 'Carolina');
    expect(rememberMe.writeCalls, 0);
    expect(rememberMe.value, isTrue);
  });

  testWidgets('U/V/W/X: 320px e textScale sem overflow com textos longos', (
    tester,
  ) async {
    final long = leticia();
    final repository = InMemoryProfessionalRepository(
      current: Professional(
        id: long.id,
        name: 'Leticia Maria da Silva Souza Oliveira',
        specialties: 'Cabeleireira colorista especialista em loiros',
        isActive: true,
        createdAt: long.createdAt,
        updatedAt: long.updatedAt,
      ),
    );
    const longEmail = 'leticia.maria.da.silva.souza@estudioauroralacos.app';

    for (final scale in [1.0, 1.3, 1.5]) {
      await pumpProfile(
        tester,
        repository: repository,
        size: const Size(320, 640),
        textScaler: TextScaler.linear(scale),
        email: longEmail,
      );
      expect(tester.takeException(), isNull);
    }

    await openEditor(tester);
    expect(tester.takeException(), isNull);
    expect(find.byType(ProfessionalProfileFormBottomSheet), findsOneWidget);
  });

  testWidgets('Y: abrir perfil não faz findAll extra', (tester) async {
    final repository = InMemoryProfessionalRepository(current: leticia());
    var findAllCalls = 0;

    await tester.binding.setSurfaceSize(const Size(420, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          professionalRepositoryProvider.overrideWithValue(repository),
          workspaceProvider.overrideWith((ref) async {
            return workspaceFor(await repository.getCurrentProfessional());
          }),
          professionalsProvider.overrideWith((ref) async {
            findAllCalls++;
            return repository.findAll();
          }),
        ],
        child: const MaterialApp(home: ProfessionalProfilePage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Leticia'), findsWidgets);
    expect(findAllCalls, 0);
  });
}

class _ProfessionalsProbe extends ConsumerWidget {
  const _ProfessionalsProbe();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(professionalsProvider);
    return const SizedBox.shrink();
  }
}

class _DelayedProfessionalRepository extends InMemoryProfessionalRepository {
  _DelayedProfessionalRepository({
    required super.current,
    required this.completer,
  });

  final Completer<Professional> completer;

  @override
  Future<Professional> update({
    required String professionalId,
    required String name,
    String? specialties,
    String? photoPath,
    bool removePhoto = false,
  }) async {
    updateCalls++;
    current = Professional(
      id: professionalId,
      name: name,
      specialties: specialties,
      isActive: true,
      createdAt: DateTime(2026, 8, 13),
      updatedAt: DateTime(2026, 8, 14),
    );
    return completer.future;
  }
}
