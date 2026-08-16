import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lacos_app/core/config/app_strings.dart';
import 'package:lacos_app/core/config/app_validation_messages.dart';
import 'package:lacos_app/features/clients/application/providers/client_next_appointment_providers.dart';
import 'package:lacos_app/features/clients/application/providers/client_providers.dart';
import 'package:lacos_app/features/clients/application/providers/client_service_history_providers.dart';
import 'package:lacos_app/features/clients/domain/entities/client.dart';
import 'package:lacos_app/features/clients/domain/enums/client_list_filter.dart';
import 'package:lacos_app/features/clients/presentation/pages/client_details_page.dart';
import 'package:lacos_app/features/clients/presentation/pages/clients_page.dart';
import 'package:lacos_app/features/clients/presentation/widgets/client_shortcut_card.dart';
import 'package:lacos_app/features/memories/application/memory_providers.dart';
import 'package:lacos_app/features/memories/domain/entities/client_memory.dart';
import 'package:lacos_app/features/memories/domain/repositories/client_memory_repository.dart';

import '../../../../helpers/in_memory_client_repository.dart';

void main() {
  final now = DateTime(2026, 8, 14);

  Client maria({bool isFavorite = false}) {
    return Client(
      id: 'client-1',
      name: 'Maria Lima',
      phone: '11999990000',
      isActive: true,
      isFavorite: isFavorite,
      createdAt: now,
      updatedAt: now,
    );
  }

  List<Override> detailsOverrides(InMemoryClientRepository repository) {
    return [
      clientRepositoryProvider.overrideWithValue(repository),
      clientMemoryRepositoryProvider.overrideWithValue(
        _FakeClientMemoryRepository(),
      ),
      clientServiceHistoryProvider('client-1').overrideWith(
        (ref) async => const [],
      ),
      clientNextAppointmentProvider('client-1').overrideWith(
        (ref) async => null,
      ),
    ];
  }

  Future<void> pumpDetails(
    WidgetTester tester, {
    required InMemoryClientRepository repository,
    Client? client,
  }) async {
    await tester.binding.setSurfaceSize(const Size(800, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: detailsOverrides(repository),
        child: MaterialApp(
          home: ClientDetailsPage(client: client ?? repository.clients.first),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('H/J/K: favoritar atualiza ficha e lista', (tester) async {
    final repository = InMemoryClientRepository(clients: [maria()]);
    await pumpDetails(tester, repository: repository);

    expect(find.byIcon(Icons.favorite_border_rounded), findsWidgets);

    await tester.tap(find.byKey(ClientDetailsPage.favoriteButtonKey));
    await tester.pumpAndSettle();

    expect(repository.updateCalls, 1);
    expect(repository.clients.single.isFavorite, isTrue);
    expect(repository.clients.single.id, 'client-1');
    expect(find.byIcon(Icons.favorite_rounded), findsOneWidget);
    expect(
      find.byTooltip(AppStrings.removeClientFromFavorites),
      findsOneWidget,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: detailsOverrides(repository),
        child: const MaterialApp(home: Scaffold(body: ClientsPage())),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(ClientShortcutCard.chipKey(ClientListFilter.favorites)));
    await tester.pump();

    expect(find.text('Maria Lima'), findsOneWidget);
  });

  testWidgets('I: desfavoritar persiste e atualiza a ficha', (tester) async {
    final repository = InMemoryClientRepository(
      clients: [maria(isFavorite: true)],
    );
    await pumpDetails(tester, repository: repository);

    await tester.tap(find.byKey(ClientDetailsPage.favoriteButtonKey));
    await tester.pumpAndSettle();

    expect(repository.clients.single.isFavorite, isFalse);
    expect(
      find.byTooltip(AppStrings.favoriteClientAction),
      findsOneWidget,
    );
  });

  testWidgets('N: tap duplicado não dispara segundo update', (tester) async {
    final repository = InMemoryClientRepository(clients: [maria()]);
    repository.updateCompleter = Completer<void>();
    await pumpDetails(tester, repository: repository);

    await tester.tap(find.byKey(ClientDetailsPage.favoriteButtonKey));
    await tester.pump();
    await tester.tap(
      find.byKey(ClientDetailsPage.favoriteButtonKey),
      warnIfMissed: false,
    );
    await tester.pump();

    expect(repository.updateCalls, 1);

    repository.updateCompleter!.complete();
    await tester.pumpAndSettle();
    expect(repository.clients.single.isFavorite, isTrue);
  });

  testWidgets('O/P: erro sanitizado mantém UI funcional', (tester) async {
    final repository = InMemoryClientRepository(clients: [maria()]);
    repository.updateError = Exception('ECONNRESET parseapi.back4app.com');
    await pumpDetails(tester, repository: repository);

    await tester.tap(find.byKey(ClientDetailsPage.favoriteButtonKey));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.clientDetailsTitle), findsOneWidget);
    expect(find.text('Maria Lima'), findsOneWidget);
    expect(
      find.byTooltip(AppStrings.favoriteClientAction),
      findsOneWidget,
    );
    expect(
      find.textContaining(AppValidationMessages.unexpectedError),
      findsOneWidget,
    );
    expect(find.textContaining('back4app'), findsNothing);
    expect(repository.clients.single.isFavorite, isFalse);

    repository.updateError = null;
    await tester.tap(find.byKey(ClientDetailsPage.favoriteButtonKey));
    await tester.pumpAndSettle();
    expect(repository.clients.single.isFavorite, isTrue);
  });

  testWidgets('AD: coração tem touch target >= 48', (tester) async {
    await pumpDetails(
      tester,
      repository: InMemoryClientRepository(clients: [maria()]),
    );

    final size = tester.getSize(find.byKey(ClientDetailsPage.favoriteButtonKey));
    expect(size.height, greaterThanOrEqualTo(48));
    expect(size.width, greaterThanOrEqualTo(48));
  });
}

class _FakeClientMemoryRepository implements ClientMemoryRepository {
  @override
  Future<List<ClientMemory>> findByClient({
    required String clientId,
    bool includeArchived = false,
  }) async {
    return const [];
  }

  @override
  Future<void> markMentioned(String memoryId) async {}

  @override
  Future<void> touchMentioned({required List<String> memoryIds}) async {}

  @override
  Future<ClientMemory> archive(String memoryId) => throw UnimplementedError();

  @override
  Future<ClientMemory> create(ClientMemory memory) =>
      throw UnimplementedError();

  @override
  Future<void> delete(String memoryId) => throw UnimplementedError();

  @override
  Future<ClientMemory> setPinned({
    required String memoryId,
    required bool isPinned,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<ClientMemory> update(ClientMemory memory) =>
      throw UnimplementedError();

  @override
  Future<ClientMemory> restore(String memoryId) => throw UnimplementedError();
}
