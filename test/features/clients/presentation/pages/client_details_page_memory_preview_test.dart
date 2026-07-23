import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lacos_app/core/config/app_strings.dart';
import 'package:lacos_app/features/clients/domain/entities/client.dart';
import 'package:lacos_app/features/clients/presentation/pages/client_details_page.dart';
import 'package:lacos_app/features/memories/application/memory_providers.dart';
import 'package:lacos_app/features/memories/domain/entities/client_memory.dart';
import 'package:lacos_app/features/memories/domain/repositories/client_memory_repository.dart';

void main() {
  group('ClientDetailsPage memory preview', () {
    late _FakeClientMemoryRepository repository;

    setUp(() {
      repository = _FakeClientMemoryRepository();
    });

    Future<void> pumpPage(WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            clientMemoryRepositoryProvider.overrideWithValue(repository),
          ],
          child: MaterialApp(home: ClientDetailsPage(client: _client())),
        ),
      );

      await tester.pumpAndSettle();
    }

    testWidgets('seção aparece quando há apenas uma memória comum', (
      tester,
    ) async {
      repository.memories = [
        _memory(id: 'common-1', content: 'Prefere água morna'),
      ];

      await pumpPage(tester);

      expect(find.text(AppStrings.memoryImportantTitle), findsOneWidget);
      expect(find.text('Prefere água morna'), findsOneWidget);
      expect(find.text(AppStrings.memoryImportantViewAll), findsOneWidget);
    });

    testWidgets('seção permanece oculta quando não há memória válida', (
      tester,
    ) async {
      repository.memories = const [];

      await pumpPage(tester);

      expect(find.text(AppStrings.memoryImportantTitle), findsNothing);
      expect(find.text(AppStrings.memoryImportantViewAll), findsNothing);
    });
  });
}

Client _client() {
  final now = DateTime(2026, 7, 8);

  return Client(
    id: 'client-1',
    name: 'Maria',
    phone: '11999999999',
    isActive: true,
    createdAt: now,
    updatedAt: now,
  );
}

ClientMemory _memory({required String id, required String content}) {
  return ClientMemory(
    id: id,
    clientId: 'client-1',
    salonId: 'salon-1',
    ownerId: 'owner-1',
    content: content,
    isActive: true,
    createdAt: DateTime(2026, 7, 8),
    updatedAt: DateTime(2026, 7, 8),
  );
}

class _FakeClientMemoryRepository implements ClientMemoryRepository {
  List<ClientMemory> memories = [];

  @override
  Future<List<ClientMemory>> findByClient({
    required String clientId,
    bool includeArchived = false,
  }) async {
    return memories.where((memory) => !memory.isArchived).toList();
  }

  @override
  Future<ClientMemory> archive(String memoryId) => throw UnimplementedError();

  @override
  Future<ClientMemory> restore(String memoryId) => throw UnimplementedError();

  @override
  Future<ClientMemory> create(ClientMemory memory) =>
      throw UnimplementedError();

  @override
  Future<void> delete(String memoryId) => throw UnimplementedError();

  @override
  Future<void> markMentioned(String memoryId) async {}

  @override
  Future<void> touchMentioned({required List<String> memoryIds}) async {}

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
}
