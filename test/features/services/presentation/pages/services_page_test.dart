import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lacos_app/core/config/app_strings.dart';
import 'package:lacos_app/features/services/application/providers/service_providers.dart';
import 'package:lacos_app/features/services/application/services/service_catalog_display_formatter.dart';
import 'package:lacos_app/features/services/domain/entities/service.dart';
import 'package:lacos_app/features/services/presentation/bottom_sheets/service_form_bottom_sheet.dart';
import 'package:lacos_app/features/services/presentation/pages/services_page.dart';
import 'package:lacos_app/features/services/presentation/widgets/service_catalog_tile.dart';
import 'package:lacos_app/features/services/presentation/widgets/services_list_section.dart';

import '../../helpers/fake_service_repository.dart';

void main() {
  Future<void> pumpServicesPage(
    WidgetTester tester, {
    List<Override> overrides = const [],
    Size size = const Size(400, 1200),
    TextScaler textScaler = TextScaler.noScaling,
  }) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MediaQuery(
        data: MediaQueryData(size: size, textScaler: textScaler),
        child: ProviderScope(
          overrides: overrides,
          child: const MaterialApp(home: Scaffold(body: ServicesPage())),
        ),
      ),
    );
  }

  testWidgets('loading mostra skeleton', (tester) async {
    final completer = Completer<List<Service>>();

    await pumpServicesPage(
      tester,
      overrides: [servicesProvider.overrideWith((ref) => completer.future)],
    );
    await tester.pump();

    expect(find.byKey(ServicesPage.loadingKey), findsOneWidget);
    expect(find.text(AppStrings.servicesEmptyTitle), findsNothing);
  });

  testWidgets('empty state e CTA abrem o formulário existente', (tester) async {
    await pumpServicesPage(
      tester,
      overrides: [
        servicesProvider.overrideWith((ref) async => const <Service>[]),
        serviceRepositoryProvider.overrideWithValue(FakeServiceRepository()),
      ],
    );
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.servicesEmptyTitle), findsOneWidget);
    expect(find.text(AppStrings.servicesEmptyMessage), findsOneWidget);
    expect(find.text(AppStrings.servicesEmptyCta), findsOneWidget);
    expect(find.byKey(ServicesPage.fabKey), findsNothing);

    await tester.tap(find.byKey(ServicesPage.emptyCtaKey));
    await tester.pumpAndSettle();

    expect(find.byType(ServiceFormBottomSheet), findsOneWidget);
    expect(find.text(AppStrings.newServiceTitle), findsOneWidget);
  });

  testWidgets('lista mostra nome, preço e duração', (tester) async {
    final service = buildTestService();

    await pumpServicesPage(
      tester,
      overrides: [
        servicesProvider.overrideWith((ref) async => [service]),
      ],
    );
    await tester.pumpAndSettle();

    expect(find.text('Corte feminino'), findsOneWidget);
    expect(
      find.text(
        ServiceCatalogDisplayFormatter.details(price: 80, durationMinutes: 60),
      ),
      findsOneWidget,
    );
    expect(find.byKey(ServicesPage.fabKey), findsOneWidget);
    expect(find.text(AppStrings.servicesEmptyTitle), findsNothing);
  });

  testWidgets('tocar o serviço abre edição', (tester) async {
    final service = buildTestService();

    await pumpServicesPage(
      tester,
      overrides: [
        servicesProvider.overrideWith((ref) async => [service]),
        serviceRepositoryProvider.overrideWithValue(
          FakeServiceRepository(seed: [service]),
        ),
      ],
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(ServiceCatalogTile.tileKey(service.id)));
    await tester.pumpAndSettle();

    expect(find.byType(ServiceFormBottomSheet), findsOneWidget);
    expect(find.text(AppStrings.editService), findsOneWidget);
  });

  testWidgets('erro mostra mensagem amigável e retry recarrega', (
    tester,
  ) async {
    final repository = FakeServiceRepository(
      findAllError: Exception('parse-internal'),
    );

    await pumpServicesPage(
      tester,
      overrides: [serviceRepositoryProvider.overrideWithValue(repository)],
    );
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.servicesLoadError), findsOneWidget);
    expect(find.text('parse-internal'), findsNothing);
    expect(find.text(AppStrings.tryAgain), findsOneWidget);

    repository.findAllError = null;
    repository.items.add(buildTestService());

    await tester.tap(find.byKey(ServicesPage.errorRetryKey));
    await tester.pumpAndSettle();

    expect(find.text('Corte feminino'), findsOneWidget);
    expect(find.text(AppStrings.servicesLoadError), findsNothing);
  });

  testWidgets('nome longo não estoura em 320px', (tester) async {
    await pumpServicesPage(
      tester,
      size: const Size(320, 640),
      overrides: [
        servicesProvider.overrideWith(
          (ref) async => [
            buildTestService(
              name:
                  'Hidratação reconstrução profunda com cronograma capilar completo',
              price: 999999.99,
              durationMinutes: 180,
            ),
          ],
        ),
      ],
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  testWidgets('duplo toque no empty CTA não empilha dois formulários', (
    tester,
  ) async {
    await pumpServicesPage(
      tester,
      overrides: [
        servicesProvider.overrideWith((ref) async => const <Service>[]),
        serviceRepositoryProvider.overrideWithValue(FakeServiceRepository()),
      ],
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(ServicesPage.emptyCtaKey));
    await tester.tap(find.byKey(ServicesPage.emptyCtaKey), warnIfMissed: false);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.byType(ServiceFormBottomSheet), findsOneWidget);
  });

  testWidgets('semantics do item descreve serviço e ação', (tester) async {
    final service = buildTestService();

    await pumpServicesPage(
      tester,
      overrides: [
        servicesProvider.overrideWith((ref) async => [service]),
      ],
    );
    await tester.pumpAndSettle();

    expect(
      tester.getSemantics(find.byKey(ServiceCatalogTile.tileKey(service.id))),
      matchesSemantics(
        label: ServiceCatalogDisplayFormatter.semantics(
          name: service.name,
          durationMinutes: service.durationMinutes,
          price: service.price,
        ),
        isButton: true,
      ),
    );
  });

  testWidgets('header e cards não repetem o ícone de tesoura', (tester) async {
    await pumpServicesPage(
      tester,
      overrides: [
        servicesProvider.overrideWith(
          (ref) async => [
            buildTestService(),
            buildTestService(id: '2', name: 'Hidratação'),
          ],
        ),
      ],
    );
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.content_cut_outlined), findsNothing);
    expect(find.byIcon(Icons.content_cut_rounded), findsNothing);
    expect(find.byIcon(Icons.chevron_right_rounded), findsNothing);
    expect(find.byIcon(Icons.more_vert_rounded), findsNWidgets(2));
    expect(find.text(AppStrings.servicesPageTitle), findsOneWidget);
    expect(find.text(AppStrings.servicesActiveCount(2)), findsOneWidget);
  });

  testWidgets('busca não aparece no empty', (tester) async {
    await pumpServicesPage(
      tester,
      overrides: [
        servicesProvider.overrideWith((ref) async => const <Service>[]),
      ],
    );
    await tester.pumpAndSettle();

    expect(find.byKey(ServicesPage.searchBarKey), findsNothing);
  });

  testWidgets('busca aparece quando há serviços', (tester) async {
    await pumpServicesPage(
      tester,
      overrides: [
        servicesProvider.overrideWith((ref) async => [buildTestService()]),
      ],
    );
    await tester.pumpAndSettle();

    expect(find.byKey(ServicesPage.searchBarKey), findsOneWidget);
    expect(find.text(AppStrings.servicesSearchHint), findsOneWidget);
  });

  Future<void> enterSearch(WidgetTester tester, String query) async {
    await tester.enterText(
      find.descendant(
        of: find.byKey(ServicesPage.searchBarKey),
        matching: find.byType(TextField),
      ),
      query,
    );
    await tester.pump();
  }

  testWidgets('busca filtra por substring, case-insensitive e trim', (
    tester,
  ) async {
    await pumpServicesPage(
      tester,
      overrides: [
        servicesProvider.overrideWith(
          (ref) async => [
            buildTestService(id: '1', name: 'Coloração'),
            buildTestService(id: '2', name: 'Corte feminino'),
            buildTestService(id: '3', name: 'Hidratação'),
          ],
        ),
      ],
    );
    await tester.pumpAndSettle();

    await enterSearch(tester, '  HIDRA  ');

    expect(find.text('Hidratação'), findsOneWidget);
    expect(find.text('Coloração'), findsNothing);
    expect(find.text('Corte feminino'), findsNothing);
    expect(find.text(AppStrings.servicesEmptyTitle), findsNothing);
  });

  testWidgets('busca preserva ordem A–Z', (tester) async {
    await pumpServicesPage(
      tester,
      overrides: [
        servicesProvider.overrideWith(
          (ref) async => [
            buildTestService(id: '1', name: 'Coloração'),
            buildTestService(id: '2', name: 'Corte feminino'),
            buildTestService(id: '3', name: 'Hidratação'),
          ],
        ),
      ],
    );
    await tester.pumpAndSettle();

    await enterSearch(tester, 'a');

    final names = tester
        .widgetList<Text>(find.byType(Text))
        .map((text) => text.data)
        .whereType<String>()
        .where(
          (value) =>
              value == 'Coloração' ||
              value == 'Corte feminino' ||
              value == 'Hidratação',
        )
        .toList();

    expect(names, ['Coloração', 'Hidratação']);
  });

  testWidgets('search-empty é específico e limpar restaura a lista', (
    tester,
  ) async {
    await pumpServicesPage(
      tester,
      overrides: [
        servicesProvider.overrideWith(
          (ref) async => [
            buildTestService(id: '1', name: 'Corte feminino'),
            buildTestService(id: '2', name: 'Hidratação'),
          ],
        ),
      ],
    );
    await tester.pumpAndSettle();

    await enterSearch(tester, 'manicure');

    expect(find.byKey(ServicesListSection.searchEmptyKey), findsOneWidget);
    expect(find.text(AppStrings.servicesSearchEmptyTitle), findsOneWidget);
    expect(find.text(AppStrings.servicesSearchEmptyMessage), findsOneWidget);
    expect(find.text(AppStrings.servicesEmptyTitle), findsNothing);
    expect(find.text(AppStrings.servicesEmptyCta), findsNothing);

    await tester.tap(find.byKey(ServicesListSection.clearSearchKey));
    await tester.pump();

    expect(find.text('Corte feminino'), findsOneWidget);
    expect(find.text('Hidratação'), findsOneWidget);
    expect(find.byKey(ServicesListSection.searchEmptyKey), findsNothing);
  });

  testWidgets('duplo toque no FAB e no card não empilha formulários', (
    tester,
  ) async {
    final service = buildTestService();
    await pumpServicesPage(
      tester,
      overrides: [
        servicesProvider.overrideWith((ref) async => [service]),
        serviceRepositoryProvider.overrideWithValue(
          FakeServiceRepository(seed: [service]),
        ),
      ],
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(ServicesPage.fabKey));
    await tester.tap(find.byKey(ServicesPage.fabKey), warnIfMissed: false);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.byType(ServiceFormBottomSheet), findsOneWidget);

    await tester.tap(find.byTooltip(AppStrings.cancel));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(ServiceCatalogTile.tileKey(service.id)));
    await tester.tap(
      find.byKey(ServiceCatalogTile.tileKey(service.id)),
      warnIfMissed: false,
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.byType(ServiceFormBottomSheet), findsOneWidget);
  });

  testWidgets('teclado aberto mantém a busca visível sem overflow', (
    tester,
  ) async {
    await pumpServicesPage(
      tester,
      size: const Size(320, 640),
      overrides: [
        servicesProvider.overrideWith((ref) async => [buildTestService()]),
      ],
    );
    await tester.pumpAndSettle();

    final searchField = find.descendant(
      of: find.byKey(ServicesPage.searchBarKey),
      matching: find.byType(TextField),
    );
    await tester.tap(searchField);
    await tester.showKeyboard(searchField);
    await tester.pump();

    expect(find.byKey(ServicesPage.searchBarKey), findsOneWidget);
    expect(find.byKey(ServicesPage.fabKey), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('pull-to-refresh recarrega servicesProvider', (tester) async {
    final repository = FakeServiceRepository(seed: [buildTestService()]);

    await pumpServicesPage(
      tester,
      overrides: [serviceRepositoryProvider.overrideWithValue(repository)],
    );
    await tester.pumpAndSettle();

    expect(repository.findAllCallCount, 1);

    await tester.fling(find.byType(ListView).first, const Offset(0, 400), 2000);
    await tester.pumpAndSettle();

    expect(repository.findAllCallCount, 2);
    expect(find.text('Corte feminino'), findsOneWidget);
  });
}
