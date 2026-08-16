import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lacos_app/core/config/app_strings.dart';
import 'package:lacos_app/features/clients/application/providers/client_next_appointment_providers.dart';
import 'package:lacos_app/features/clients/application/providers/client_providers.dart';
import 'package:lacos_app/features/clients/application/providers/client_service_history_providers.dart';
import 'package:lacos_app/features/clients/domain/entities/client.dart';
import 'package:lacos_app/features/clients/presentation/pages/client_details_page.dart';
import 'package:lacos_app/features/memories/application/memory_providers.dart';
import 'package:lacos_app/features/memories/domain/entities/client_memory.dart';
import 'package:lacos_app/features/memories/domain/repositories/client_memory_repository.dart';

import '../../../../helpers/home_responsive_test_helpers.dart';
import '../../../../helpers/in_memory_client_repository.dart';

void main() {
  final now = DateTime(2026, 7, 8);

  Client client({
    String name = 'Maria Lima',
    String? instagram = 'maria.lima',
    String? photoUrl,
    bool isFavorite = false,
  }) {
    return Client(
      id: 'client-1',
      name: name,
      phone: '11999990000',
      instagram: instagram,
      photoUrl: photoUrl,
      isActive: true,
      isFavorite: isFavorite,
      clientSince: now,
      createdAt: now,
      updatedAt: now,
    );
  }

  List<Override> overrides(InMemoryClientRepository repository) {
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
    required Client detailsClient,
    Size size = const Size(390, 1200),
    TextScaler textScaler = TextScaler.noScaling,
  }) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final repository = InMemoryClientRepository(clients: [detailsClient]);

    await tester.pumpWidget(
      ProviderScope(
        overrides: overrides(repository),
        child: MediaQuery(
          data: MediaQueryData(size: size, textScaler: textScaler),
          child: MaterialApp(
            home: ClientDetailsPage(
              key: ValueKey(
                '${detailsClient.id}-${detailsClient.isFavorite}-'
                '${detailsClient.name}-${detailsClient.photoUrl}',
              ),
              client: detailsClient,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('A/P/Q/R: ficha não apresenta overflow em 320 e textScale', (
    tester,
  ) async {
    final detailsClient = client(
      name: 'Maria Fernanda Albuquerque de Souza e Silva',
      instagram: 'mariafernanda.albuquerque.souza.oficial',
    );

    for (final size in const [
      Size(320, 720),
      Size(360, 800),
      Size(390, 844),
    ]) {
      for (final scaler in [
        TextScaler.noScaling,
        const TextScaler.linear(1.3),
        const TextScaler.linear(1.5),
      ]) {
        await pumpDetails(
          tester,
          detailsClient: detailsClient,
          size: size,
          textScaler: scaler,
        );
        expectNoRenderOverflow(tester);
      }
    }
  });

  testWidgets('B/C: chip Cliente desde sai do header e data fica nos dados', (
    tester,
  ) async {
    await pumpDetails(tester, detailsClient: client());

    expect(find.textContaining('Jul/2026'), findsNothing);
    expect(find.text(AppStrings.clientSince), findsOneWidget);
    expect(find.text('08/07/2026'), findsOneWidget);
  });

  testWidgets('D/E: coração no header representa favorita', (tester) async {
    await pumpDetails(tester, detailsClient: client());

    expect(find.byKey(ClientDetailsPage.favoriteButtonKey), findsOneWidget);
    expect(
      tester
          .widget<IconButton>(find.byKey(ClientDetailsPage.favoriteButtonKey))
          .tooltip,
      AppStrings.favoriteClientAction,
    );
    expect(find.byIcon(Icons.favorite_border_rounded), findsOneWidget);

    await pumpDetails(tester, detailsClient: client(isFavorite: true));

    expect(
      tester
          .widget<IconButton>(find.byKey(ClientDetailsPage.favoriteButtonKey))
          .tooltip,
      AppStrings.removeClientFromFavorites,
    );
    expect(find.byIcon(Icons.favorite_rounded), findsOneWidget);
  });

  testWidgets('S: nome e Instagram longos, com e sem foto, sem overflow', (
    tester,
  ) async {
    await pumpDetails(
      tester,
      detailsClient: client(
        name: 'Ana Beatriz Gonçalves da Costa Figueiredo',
        instagram: 'anabeatriz.goncalves.da.costa.figueiredo',
        photoUrl: 'https://example.com/ana.jpg',
      ),
      size: const Size(320, 720),
      textScaler: const TextScaler.linear(1.5),
    );
    expectNoRenderOverflow(tester);
    expect(find.byKey(ClientDetailsPage.favoriteButtonKey), findsOneWidget);

    await pumpDetails(
      tester,
      detailsClient: client(
        name: 'Helena',
        instagram: null,
      ),
      size: const Size(320, 720),
      textScaler: const TextScaler.linear(1.5),
    );
    expectNoRenderOverflow(tester);
    expect(find.byKey(ClientDetailsPage.favoriteButtonKey), findsOneWidget);
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
