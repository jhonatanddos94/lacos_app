import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lacos_app/core/config/app_strings.dart';
import 'package:lacos_app/features/clients/application/providers/client_providers.dart';
import 'package:lacos_app/features/clients/domain/entities/client.dart';
import 'package:lacos_app/features/clients/domain/enums/client_list_filter.dart';
import 'package:lacos_app/features/clients/presentation/pages/clients_page.dart';
import 'package:lacos_app/features/clients/presentation/widgets/client_shortcut_card.dart';
import 'package:lacos_app/features/clients/presentation/widgets/client_shortcuts_section.dart';
import 'package:lacos_app/features/clients/presentation/widgets/clients_search_bar.dart';

import '../../../../helpers/home_responsive_test_helpers.dart';
import '../../../../helpers/in_memory_client_repository.dart';

void main() {
  final now = DateTime(2026, 8, 14);

  Client client({
    required String id,
    required String name,
    String phone = '11999990000',
    bool isFavorite = false,
  }) {
    return Client(
      id: id,
      name: name,
      phone: phone,
      isActive: true,
      isFavorite: isFavorite,
      createdAt: now,
      updatedAt: now,
    );
  }

  Future<void> pumpPage(
    WidgetTester tester, {
    required InMemoryClientRepository repository,
    Size size = const Size(390, 844),
    TextScaler textScaler = TextScaler.noScaling,
  }) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          clientRepositoryProvider.overrideWithValue(repository),
        ],
        child: MediaQuery(
          data: MediaQueryData(size: size, textScaler: textScaler),
          child: const MaterialApp(home: Scaffold(body: ClientsPage())),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Finder filterChip(ClientListFilter filter) {
    return find.byKey(ClientShortcutCard.chipKey(filter));
  }

  testWidgets('A/B: header de Clientes não tem perfil nem área vazia', (
    tester,
  ) async {
    await pumpPage(tester, repository: InMemoryClientRepository());

    expect(find.byIcon(Icons.person_outline_rounded), findsNothing);
    expect(find.byIcon(Icons.notifications_none_rounded), findsNothing);
    expect(find.byType(IconButton), findsNothing);
    expect(find.text('Clientes'), findsOneWidget);
  });

  testWidgets('C: Todas mostra todas', (tester) async {
    final repository = InMemoryClientRepository(
      clients: [
        client(id: '1', name: 'Ana Souza'),
        client(id: '2', name: 'Maria Lima', isFavorite: true),
      ],
    );
    await pumpPage(tester, repository: repository);

    expect(find.text('Ana Souza'), findsOneWidget);
    expect(find.text('Maria Lima'), findsOneWidget);
    expect(find.text(AppStrings.clientsListTitle), findsOneWidget);
    expect(find.text('Recentes'), findsNothing);
    expect(find.text('Sem retorno'), findsNothing);
    expect(find.text(AppStrings.allClients), findsOneWidget);
    expect(find.text(AppStrings.favoriteClients), findsOneWidget);
  });

  testWidgets('D: somente um segmento selecionado', (tester) async {
    await pumpPage(tester, repository: InMemoryClientRepository());

    expect(
      tester
          .getSemantics(filterChip(ClientListFilter.all))
          .flagsCollection
          .isSelected
          .toBoolOrNull(),
      isTrue,
    );
    expect(
      tester
          .getSemantics(filterChip(ClientListFilter.favorites))
          .flagsCollection
          .isSelected
          .toBoolOrNull(),
      isFalse,
    );

    await tester.tap(filterChip(ClientListFilter.favorites));
    await tester.pump();

    expect(
      tester
          .getSemantics(filterChip(ClientListFilter.favorites))
          .flagsCollection
          .isSelected
          .toBoolOrNull(),
      isTrue,
    );
    expect(
      tester
          .getSemantics(filterChip(ClientListFilter.all))
          .flagsCollection
          .isSelected
          .toBoolOrNull(),
      isFalse,
    );
  });

  testWidgets('A: seletor acompanha a largura da SearchBar', (tester) async {
    await pumpPage(
      tester,
      repository: InMemoryClientRepository(),
      size: const Size(390, 844),
    );

    final searchWidth = tester.getSize(find.byType(ClientsSearchBar)).width;
    final filterWidth = tester.getSize(
      find.byKey(ClientShortcutsSection.barKey),
    ).width;

    expect(filterWidth, closeTo(searchWidth, 1));
  });

  testWidgets('C: altura visual é mais baixa que o touch target', (tester) async {
    await pumpPage(tester, repository: InMemoryClientRepository());

    final barHeight = tester
        .getSize(find.byKey(ClientShortcutsSection.barKey))
        .height;
    expect(barHeight, ClientShortcutCard.visualHeight);
    expect(barHeight, lessThan(kMinInteractiveDimension));
  });

  testWidgets('C/D/E: selected fill ocupa o track e encaixa nas pontas', (
    tester,
  ) async {
    await pumpPage(tester, repository: InMemoryClientRepository());

    Rect barRect() =>
        tester.getRect(find.byKey(ClientShortcutsSection.barKey));
    Rect fillRect() =>
        tester.getRect(find.byKey(ClientShortcutCard.selectedFillKey));

    var bar = barRect();
    var fill = fillRect();
    expect(fill.height, closeTo(bar.height, 1));
    expect(fill.top, closeTo(bar.top, 1));
    expect(fill.bottom, closeTo(bar.bottom, 1));
    expect(fill.left, closeTo(bar.left, 1));
    expect(fill.width, closeTo(bar.width / 2, 1));

    await tester.tap(filterChip(ClientListFilter.favorites));
    await tester.pump();

    bar = barRect();
    fill = fillRect();
    expect(fill.height, closeTo(bar.height, 1));
    expect(fill.top, closeTo(bar.top, 1));
    expect(fill.bottom, closeTo(bar.bottom, 1));
    expect(fill.right, closeTo(bar.right, 1));
    expect(fill.width, closeTo(bar.width / 2, 1));
  });

  testWidgets('F/G: segmentos iguais e touch target >= 48', (tester) async {
    await pumpPage(tester, repository: InMemoryClientRepository());

    final allSize = tester.getSize(filterChip(ClientListFilter.all));
    final favoritesSize = tester.getSize(filterChip(ClientListFilter.favorites));
    expect((allSize.width - favoritesSize.width).abs(), lessThan(1));
    expect(allSize.height, greaterThanOrEqualTo(48));
    expect(favoritesSize.height, greaterThanOrEqualTo(48));
    expect(allSize.width, greaterThanOrEqualTo(48));
    expect(favoritesSize.width, greaterThanOrEqualTo(48));
  });

  testWidgets('M: Favoritas mostra só favoritas', (tester) async {
    final repository = InMemoryClientRepository(
      clients: [
        client(id: '1', name: 'Ana Souza'),
        client(id: '2', name: 'Maria Lima', isFavorite: true),
      ],
    );
    await pumpPage(tester, repository: repository);

    await tester.tap(filterChip(ClientListFilter.favorites));
    await tester.pump();

    expect(find.text('Maria Lima'), findsOneWidget);
    expect(find.text('Ana Souza'), findsNothing);
    expect(find.text(AppStrings.favoriteClientsListTitle), findsOneWidget);
    expect(find.text(AppStrings.clientsListTitle), findsNothing);
  });

  testWidgets('E: Favoritas vazia mostra empty correto', (tester) async {
    await pumpPage(
      tester,
      repository: InMemoryClientRepository(
        clients: [client(id: '1', name: 'Ana Souza')],
      ),
    );

    await tester.tap(filterChip(ClientListFilter.favorites));
    await tester.pump();

    expect(find.text(AppStrings.emptyFavoritesTitle), findsOneWidget);
    expect(find.text(AppStrings.emptyAllClientsTitle), findsNothing);
  });

  testWidgets('L: busca continua funcionando', (tester) async {
    await pumpPage(
      tester,
      repository: InMemoryClientRepository(
        clients: [
          client(id: '1', name: 'Ana Souza'),
          client(id: '2', name: 'Maria Lima'),
        ],
      ),
    );

    await tester.enterText(
      find.descendant(
        of: find.byKey(ClientsPage.searchBarKey),
        matching: find.byType(TextField),
      ),
      'Ana',
    );
    await tester.pump();

    expect(find.text('Ana Souza'), findsOneWidget);
    expect(find.text('Maria Lima'), findsNothing);
  });

  testWidgets('N: busca + Favoritas combinam', (tester) async {
    await pumpPage(
      tester,
      repository: InMemoryClientRepository(
        clients: [
          client(id: '1', name: 'Ana Souza', isFavorite: true),
          client(id: '2', name: 'Marina Costa', isFavorite: true),
          client(id: '3', name: 'Maria Lima'),
        ],
      ),
    );

    await tester.tap(filterChip(ClientListFilter.favorites));
    await tester.pump();
    await tester.enterText(
      find.descendant(
        of: find.byKey(ClientsPage.searchBarKey),
        matching: find.byType(TextField),
      ),
      'Mar',
    );
    await tester.pump();

    expect(find.text('Marina Costa'), findsOneWidget);
    expect(find.text('Ana Souza'), findsNothing);
    expect(find.text('Maria Lima'), findsNothing);
  });

  testWidgets('O: filtro e busca não disparam query extra', (tester) async {
    final repository = InMemoryClientRepository(
      clients: [
        client(id: '1', name: 'Ana Souza'),
        client(id: '2', name: 'Maria Lima', isFavorite: true),
      ],
    );
    await pumpPage(tester, repository: repository);
    expect(repository.findAllCalls, 1);

    await tester.tap(filterChip(ClientListFilter.favorites));
    await tester.pump();
    await tester.tap(filterChip(ClientListFilter.all));
    await tester.pump();
    await tester.enterText(
      find.descendant(
        of: find.byKey(ClientsPage.searchBarKey),
        matching: find.byType(TextField),
      ),
      'Ana',
    );
    await tester.pump();

    expect(repository.findAllCalls, 1);
    expect(repository.updateCalls, 0);
  });

  testWidgets('H/I/J/K: 320/390/430 e textScale sem overflow', (tester) async {
    final repository = InMemoryClientRepository(
      clients: [client(id: '1', name: 'Ana Souza')],
    );

    for (final size in const [
      Size(320, 640),
      Size(360, 800),
      Size(390, 844),
      Size(430, 932),
    ]) {
      for (final scaler in [
        TextScaler.noScaling,
        const TextScaler.linear(1.3),
        const TextScaler.linear(1.5),
      ]) {
        await pumpPage(
          tester,
          repository: repository,
          size: size,
          textScaler: scaler,
        );
        expectNoRenderOverflow(tester);
        expect(find.text(AppStrings.allClients), findsOneWidget);
        expect(find.text(AppStrings.favoriteClients), findsOneWidget);
      }
    }
  });
}
