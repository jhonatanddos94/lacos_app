import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lacos_app/core/config/app_strings.dart';
import 'package:lacos_app/core/config/app_validation_messages.dart';
import 'package:lacos_app/core/workspace/application/providers/workspace_providers.dart';
import 'package:lacos_app/core/workspace/domain/entities/workspace.dart';
import 'package:lacos_app/features/auth/domain/entities/authenticated_user.dart';
import 'package:lacos_app/features/home/presentation/widgets/home_header.dart';
import 'package:lacos_app/features/professional/domain/entities/professional.dart';
import 'package:lacos_app/features/salon/application/providers/salon_providers.dart';
import 'package:lacos_app/features/salon/domain/entities/salon.dart';
import 'package:lacos_app/features/salon/presentation/bottom_sheets/salon_form_bottom_sheet.dart';
import 'package:lacos_app/features/salon/presentation/pages/salon_page.dart';
import 'package:lacos_app/features/working_hours/application/providers/working_hours_providers.dart';
import 'package:lacos_app/features/working_hours/presentation/pages/professional_working_hours_page.dart';
import 'package:lacos_app/shared/widgets/inputs/app_text_field.dart';

import '../../../../helpers/in_memory_professional_working_hours_repository.dart';
import '../../../../helpers/in_memory_salon_repository.dart';

void main() {
  final now = DateTime(2026, 8, 14, 14);
  final professional = Professional(
    id: 'pro-1',
    name: 'Leticia',
    isActive: true,
    createdAt: now,
    updatedAt: now,
  );

  Salon salon({
    String name = 'Studio Aurora',
    String? phone = '67999999999',
    String? address = 'Rua das Flores, 10',
    String? city = 'Campo Grande',
    String? state = 'MS',
  }) {
    return Salon(
      id: 'salon-1',
      name: name,
      responsibleName: 'Leticia',
      phone: phone,
      address: address,
      city: city,
      state: state,
      isActive: true,
      createdAt: now,
      updatedAt: now,
    );
  }

  Workspace workspaceFor(Salon? current) => Workspace(
    user: const AuthenticatedUser(
      id: 'user-1',
      email: 'leticia@lacos.app',
      isEmailVerified: true,
    ),
    salon: current,
    professional: professional,
  );

  Future<void> pumpSalon(
    WidgetTester tester, {
    required InMemorySalonRepository repository,
    Size size = const Size(390, 844),
    TextScaler textScaler = TextScaler.noScaling,
    Widget child = const SalonPage(),
  }) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          salonRepositoryProvider.overrideWithValue(repository),
          workspaceProvider.overrideWith((ref) async {
            return workspaceFor(await repository.getCurrentSalon());
          }),
        ],
        child: MediaQuery(
          data: MediaQueryData(size: size, textScaler: textScaler),
          child: MaterialApp(home: child),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> openEditor(WidgetTester tester) async {
    final edit = find.byKey(SalonPage.editButtonKey);
    await tester.scrollUntilVisible(edit, 240);
    await tester.pumpAndSettle();
    await tester.ensureVisible(edit);
    await tester.pumpAndSettle();
    await tester.tap(edit);
    await tester.pumpAndSettle();
  }

  Finder field(Key key) => find.descendant(
    of: find.byKey(key),
    matching: find.byType(TextFormField),
  );

  testWidgets('A–D: dados atuais e responsável somente leitura', (
    tester,
  ) async {
    await pumpSalon(
      tester,
      repository: InMemorySalonRepository(current: salon()),
    );

    expect(find.byKey(SalonPage.pageKey), findsOneWidget);
    expect(find.byKey(SalonPage.infoCardKey), findsOneWidget);
    expect(find.text(AppStrings.moreSalonSubtitle), findsOneWidget);
    expect(find.text(AppStrings.salonInformationSection), findsOneWidget);
    expect(find.text('Studio Aurora'), findsWidgets);
    expect(find.text('Leticia'), findsOneWidget);
    expect(find.text('(67) 99999-9999'), findsOneWidget);
    expect(find.text('Rua das Flores, 10 · Campo Grande · MS'), findsOneWidget);
    expect(find.byKey(SalonPage.responsibleFieldKey), findsOneWidget);
    expect(find.byType(AppTextField), findsNothing);
  });

  testWidgets('C: opcionais ausentes não quebram', (tester) async {
    await pumpSalon(
      tester,
      repository: InMemorySalonRepository(
        current: salon(phone: null, address: null, city: null, state: null),
      ),
    );

    expect(find.text(AppStrings.salonPhoneLabel), findsNothing);
    expect(find.text(AppStrings.salonAddressLabel), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('E/AD: editar abre somente campos do Salon', (tester) async {
    await pumpSalon(
      tester,
      repository: InMemorySalonRepository(current: salon()),
    );
    await openEditor(tester);

    expect(find.byType(SalonFormBottomSheet), findsOneWidget);
    expect(field(SalonFormBottomSheet.nameFieldKey), findsOneWidget);
    expect(field(SalonFormBottomSheet.phoneFieldKey), findsOneWidget);
    expect(field(SalonFormBottomSheet.addressFieldKey), findsOneWidget);
    expect(field(SalonFormBottomSheet.cityFieldKey), findsOneWidget);
    expect(field(SalonFormBottomSheet.stateFieldKey), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(SalonFormBottomSheet),
        matching: find.text(AppStrings.salonResponsibleLabel),
      ),
      findsNothing,
    );
    expect(
      find.text(AppStrings.professionalProfileSpecialtiesLabel),
      findsNothing,
    );
    expect(find.text(AppStrings.professionalProfileEmailLabel), findsNothing);
  });

  testWidgets('F–I/N: salva, fecha e atualiza SalonPage', (tester) async {
    final repository = InMemorySalonRepository(current: salon());
    await pumpSalon(tester, repository: repository);
    await openEditor(tester);

    await tester.enterText(
      field(SalonFormBottomSheet.nameFieldKey),
      '  Studio Leticia  ',
    );
    await tester.enterText(
      field(SalonFormBottomSheet.phoneFieldKey),
      '(67) 98888-7777',
    );
    await tester.enterText(
      field(SalonFormBottomSheet.addressFieldKey),
      '  Avenida Central, 20  ',
    );
    final save = find.byKey(SalonFormBottomSheet.saveButtonKey);
    await tester.ensureVisible(save);
    await tester.tap(save);
    await tester.pumpAndSettle();

    expect(repository.current?.name, 'Studio Leticia');
    expect(repository.current?.phone, '67988887777');
    expect(repository.current?.address, 'Avenida Central, 20');
    expect(find.byType(SalonFormBottomSheet), findsNothing);
    expect(find.text('Studio Leticia'), findsWidgets);
    expect(find.text(AppStrings.salonUpdatedSuccess), findsOneWidget);
    expect(repository.createCalls, 0);
  });

  testWidgets('J: nome vazio mostra validação e não salva', (tester) async {
    final repository = InMemorySalonRepository(current: salon());
    await pumpSalon(tester, repository: repository);
    await openEditor(tester);

    await tester.enterText(field(SalonFormBottomSheet.nameFieldKey), ' ');
    final save = find.byKey(SalonFormBottomSheet.saveButtonKey);
    await tester.ensureVisible(save);
    await tester.tap(save);
    await tester.pump();

    expect(find.text(AppValidationMessages.salonNameRequired), findsOneWidget);
    expect(repository.updateCalls, 0);
    expect(find.byType(SalonFormBottomSheet), findsOneWidget);
  });

  testWidgets('L/M: erro mantém form, dados e mensagem sanitizada', (
    tester,
  ) async {
    final repository = InMemorySalonRepository(current: salon())
      ..updateError = Exception('Parse secret token');
    await pumpSalon(tester, repository: repository);
    await openEditor(tester);

    await tester.enterText(
      field(SalonFormBottomSheet.nameFieldKey),
      'Studio Novo',
    );
    final save = find.byKey(SalonFormBottomSheet.saveButtonKey);
    await tester.ensureVisible(save);
    await tester.tap(save);
    await tester.pumpAndSettle();

    expect(find.byType(SalonFormBottomSheet), findsOneWidget);
    expect(field(SalonFormBottomSheet.nameFieldKey), findsOneWidget);
    expect(find.text(AppStrings.salonUpdateError), findsOneWidget);
    expect(find.textContaining('secret'), findsNothing);
  });

  testWidgets('O: update atualiza HomeHeader sem relogar', (tester) async {
    final repository = InMemorySalonRepository(current: salon());
    await pumpSalon(
      tester,
      repository: repository,
      child: _HomeSalonHarness(now: now),
    );

    expect(find.text('Studio Aurora'), findsOneWidget);
    await tester.tap(find.byKey(HomeHeader.salonButtonKey));
    await tester.pumpAndSettle();
    await openEditor(tester);
    await tester.enterText(
      field(SalonFormBottomSheet.nameFieldKey),
      'Studio Leticia',
    );
    final save = find.byKey(SalonFormBottomSheet.saveButtonKey);
    await tester.ensureVisible(save);
    await tester.tap(save);
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(find.text('Studio Leticia'), findsOneWidget);
    expect(repository.current?.responsibleName, 'Leticia');
  });

  testWidgets('Horários: Meu salão abre tela semanal', (tester) async {
    final workingHoursRepository = InMemoryProfessionalWorkingHoursRepository();
    await tester.binding.setSurfaceSize(const Size(390, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          salonRepositoryProvider.overrideWithValue(
            InMemorySalonRepository(current: salon()),
          ),
          professionalWorkingHoursRepositoryProvider.overrideWithValue(
            workingHoursRepository,
          ),
          workspaceProvider.overrideWith((ref) async => workspaceFor(salon())),
        ],
        child: const MaterialApp(home: SalonPage()),
      ),
    );
    await tester.pumpAndSettle();

    final action = find.byKey(SalonPage.workingHoursButtonKey);
    await tester.ensureVisible(action);
    await tester.tap(action);
    await tester.pumpAndSettle();

    expect(find.byType(ProfessionalWorkingHoursPage), findsOneWidget);
    expect(find.text(AppStrings.workingHoursTitle), findsOneWidget);
  });

  testWidgets('W–Y: 320px e textScale 1.3/1.5 sem overflow', (tester) async {
    for (final scale in [1.0, 1.3, 1.5]) {
      await pumpSalon(
        tester,
        repository: InMemorySalonRepository(
          current: salon(
            name: 'Studio de Beleza com um Nome Muito Longo',
            address: 'Avenida com endereço extenso, número 123, complemento 45',
          ),
        ),
        size: const Size(320, 640),
        textScaler: TextScaler.linear(scale),
      );
      expect(tester.takeException(), isNull);
      await openEditor(tester);
      expect(tester.takeException(), isNull);
      expect(find.byType(Scrollable), findsWidgets);
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();
    }
  });
}

class _HomeSalonHarness extends ConsumerWidget {
  const _HomeSalonHarness({required this.now});

  final DateTime now;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workspace = ref.watch(workspaceProvider).valueOrNull;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: HomeHeader(
            professionalName: workspace?.professional?.name ?? 'Profissional',
            salonName: workspace?.salon?.name ?? 'Seu salão',
            now: now,
            onProfileTap: () {},
            onSalonTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (context) => const SalonPage(),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
