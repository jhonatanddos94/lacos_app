import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lacos_app/features/services/application/providers/service_providers.dart';
import 'package:lacos_app/features/services/presentation/pages/services_page.dart';
import 'package:lacos_app/features/services/presentation/widgets/service_catalog_tile.dart';

import '../../helpers/fake_service_repository.dart';
import '../../../../helpers/home_responsive_test_helpers.dart';

void main() {
  Future<void> pumpCatalog(
    WidgetTester tester, {
    required TextScaler textScaler,
  }) async {
    await configureCompactViewport(tester);

    await tester.pumpWidget(
      wrapTextScale(
        textScaler: textScaler,
        child: ProviderScope(
          overrides: [
            servicesProvider.overrideWith(
              (ref) async => [
                buildTestService(),
                buildTestService(
                  id: 'service-2',
                  name:
                      'Escova progressiva com tratamento de reconstrução intensa',
                  price: 1250,
                  durationMinutes: 180,
                ),
              ],
            ),
          ],
          child: const MaterialApp(home: Scaffold(body: ServicesPage())),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('320x640 textScale 1.0 sem overflow', (tester) async {
    await pumpCatalog(tester, textScaler: TextScaler.noScaling);
    expectNoRenderOverflow(tester);
    expect(find.byKey(ServiceCatalogTile.tileKey('service-1')), findsOneWidget);
  });

  testWidgets('320x640 textScale 1.5 sem overflow', (tester) async {
    await pumpCatalog(tester, textScaler: const TextScaler.linear(1.5));
    expectNoRenderOverflow(tester);
    expect(find.byKey(ServicesPage.searchBarKey), findsOneWidget);
    expect(find.byIcon(Icons.more_vert_rounded), findsNWidgets(2));
  });

  testWidgets('320x640 textScale 1.5 com 20 serviços e busca', (tester) async {
    await configureCompactViewport(tester);

    await tester.pumpWidget(
      wrapTextScale(
        textScaler: const TextScaler.linear(1.5),
        child: ProviderScope(
          overrides: [
            servicesProvider.overrideWith(
              (ref) async => [
                for (var index = 1; index <= 20; index++)
                  buildTestService(
                    id: 'service-$index',
                    name: index == 7
                        ? 'Tratamento Reconstrutor Intensivo Pós-Química'
                        : 'Serviço ${index.toString().padLeft(2, '0')}',
                    price: index == 20 ? 999999.99 : 80,
                    durationMinutes: index == 20 ? 180 : 30,
                  ),
              ],
            ),
          ],
          child: const MaterialApp(home: Scaffold(body: ServicesPage())),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expectNoRenderOverflow(tester);
    expect(find.byKey(ServicesPage.searchBarKey), findsOneWidget);

    await tester.enterText(
      find.descendant(
        of: find.byKey(ServicesPage.searchBarKey),
        matching: find.byType(TextField),
      ),
      'reconstrutor',
    );
    await tester.pump();

    expect(
      find.text('Tratamento Reconstrutor Intensivo Pós-Química'),
      findsOneWidget,
    );
    expectNoRenderOverflow(tester);
  });
}
