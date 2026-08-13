import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lacos_app/core/config/app_strings.dart';
import 'package:lacos_app/features/services/application/providers/service_providers.dart';
import 'package:lacos_app/features/services/presentation/bottom_sheets/service_picker_bottom_sheet.dart';
import 'package:lacos_app/features/services/presentation/pages/services_page.dart';
import 'package:lacos_app/features/services/presentation/widgets/service_catalog_tile.dart';
import 'package:lacos_app/features/services/presentation/widgets/services_list_section.dart';

import '../../helpers/fake_service_repository.dart';

void main() {
  Future<void> pumpCatalog(
    WidgetTester tester, {
    required FakeServiceRepository repository,
  }) async {
    await tester.binding.setSurfaceSize(const Size(400, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [serviceRepositoryProvider.overrideWithValue(repository)],
        child: const MaterialApp(home: Scaffold(body: ServicesPage())),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> fillRequiredServiceFields(
    WidgetTester tester, {
    required String name,
    String durationLabel = '30 min',
  }) async {
    await tester.enterText(find.byType(TextFormField).first, name);
    await tester.tap(find.byType(DropdownButtonFormField<int?>));
    await tester.pumpAndSettle();
    await tester.tap(find.text(durationLabel).last);
    await tester.pumpAndSettle();
  }

  testWidgets('criar serviço aparece imediatamente na lista', (tester) async {
    final repository = FakeServiceRepository();
    await pumpCatalog(tester, repository: repository);

    await tester.tap(find.byKey(ServicesPage.emptyCtaKey));
    await tester.pumpAndSettle();

    await fillRequiredServiceFields(tester, name: 'Manicure');
    await tester.ensureVisible(find.text(AppStrings.saveService));
    await tester.tap(find.text(AppStrings.saveService));
    await tester.pumpAndSettle();

    expect(find.text('Manicure'), findsOneWidget);
    expect(find.text(AppStrings.servicesEmptyTitle), findsNothing);
    expect(find.text(AppStrings.serviceCreatedSuccess), findsOneWidget);
  });

  testWidgets('editar serviço atualiza a lista', (tester) async {
    final service = buildTestService(name: 'Corte');
    final repository = FakeServiceRepository(seed: [service]);
    await pumpCatalog(tester, repository: repository);

    await tester.tap(find.byKey(ServiceCatalogTile.tileKey(service.id)));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).first, 'Corte feminino');
    await tester.ensureVisible(find.text(AppStrings.saveChanges));
    await tester.tap(find.text(AppStrings.saveChanges));
    await tester.pumpAndSettle();

    expect(find.text('Corte feminino'), findsOneWidget);
    expect(find.text('Corte'), findsNothing);
    expect(find.text(AppStrings.serviceUpdatedSuccess), findsOneWidget);
  });

  testWidgets('serviço criado aparece no picker de agendamento', (
    tester,
  ) async {
    final repository = FakeServiceRepository(
      seed: [buildTestService(name: 'Hidratação')],
    );

    await tester.binding.setSurfaceSize(const Size(400, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [serviceRepositoryProvider.overrideWithValue(repository)],
        child: const MaterialApp(
          home: Scaffold(body: ServicePickerBottomSheet()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Hidratação'), findsOneWidget);
  });

  testWidgets('serviço inativo não aparece no picker', (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          servicesProvider.overrideWith(
            (ref) async => [
              buildTestService(id: 'active', name: 'Corte ativo'),
              buildTestService(
                id: 'inactive',
                name: 'Coloração inativa',
                isActive: false,
              ),
            ],
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(body: ServicePickerBottomSheet()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Corte ativo'), findsOneWidget);
    expect(find.text('Coloração inativa'), findsNothing);
  });

  testWidgets('desativar serviço remove da lista e do picker', (tester) async {
    final service = buildTestService(name: 'Escova');
    final repository = FakeServiceRepository(seed: [service]);
    await pumpCatalog(tester, repository: repository);

    await tester.tap(find.byKey(ServiceCatalogTile.menuKey(service.id)));
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppStrings.deleteService));
    await tester.pumpAndSettle();
    await tester.tap(
      find.widgetWithText(FilledButton, AppStrings.deleteService),
    );
    await tester.pumpAndSettle();

    expect(find.text('Escova'), findsNothing);
    expect(find.text(AppStrings.servicesEmptyTitle), findsOneWidget);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [serviceRepositoryProvider.overrideWithValue(repository)],
        child: const MaterialApp(
          home: Scaffold(body: ServicePickerBottomSheet()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Escova'), findsNothing);
  });

  testWidgets('editar com busca ativa atualiza o filtro local', (tester) async {
    final corte = buildTestService(id: '1', name: 'Corte');
    final hidratacao = buildTestService(id: '2', name: 'Hidratação');
    final repository = FakeServiceRepository(seed: [corte, hidratacao]);
    await pumpCatalog(tester, repository: repository);

    await tester.enterText(
      find.descendant(
        of: find.byKey(ServicesPage.searchBarKey),
        matching: find.byType(TextField),
      ),
      'corte',
    );
    await tester.pump();

    expect(find.text('Corte'), findsOneWidget);
    expect(find.text('Hidratação'), findsNothing);

    await tester.tap(find.byKey(ServiceCatalogTile.tileKey(corte.id)));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, 'Coloração');
    await tester.ensureVisible(find.text(AppStrings.saveChanges));
    await tester.tap(find.text(AppStrings.saveChanges));
    await tester.pumpAndSettle();

    expect(find.text('Coloração'), findsNothing);
    expect(find.text('Corte'), findsNothing);
    expect(find.byKey(ServicesListSection.searchEmptyKey), findsOneWidget);

    await tester.tap(find.byKey(ServicesListSection.clearSearchKey));
    await tester.pump();

    expect(find.text('Coloração'), findsOneWidget);
    expect(find.text('Hidratação'), findsOneWidget);
  });
}
