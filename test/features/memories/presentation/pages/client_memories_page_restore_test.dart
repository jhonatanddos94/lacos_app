import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lacos_app/core/config/app_strings.dart';
import 'package:lacos_app/features/clients/domain/entities/client.dart';
import 'package:lacos_app/features/memories/application/memory_providers.dart';
import 'package:lacos_app/features/memories/domain/entities/client_memory.dart';
import 'package:lacos_app/features/memories/domain/repositories/client_memory_repository.dart';
import 'package:lacos_app/features/memories/presentation/bottom_sheets/client_memory_filters_bottom_sheet.dart';
import 'package:lacos_app/features/memories/presentation/pages/client_memories_page.dart';

Future<void> tapFilterChip(WidgetTester tester, String label) async {
  await tester.tap(
    find
        .descendant(
          of: find.byType(ClientMemoryFiltersBottomSheet),
          matching: find.text(label),
        )
        .first,
  );
  await tester.pumpAndSettle();
}

void main() {
  group('ClientMemoriesPage restore flow', () {
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
          child: MaterialApp(home: ClientMemoriesPage(client: _client())),
        ),
      );

      await tester.pumpAndSettle();
    }

    testWidgets('restaurar remove card do filtro Apenas arquivadas', (
      tester,
    ) async {
      repository.memories = [
        _memory(id: 'm1', content: 'Memória arquivada', isArchived: true),
      ];

      await pumpPage(tester);

      await tester.tap(find.byIcon(Icons.tune_rounded));
      await tester.pumpAndSettle();
      await tapFilterChip(tester, AppStrings.memoryFilterArchivedOnly);
      await tester.tap(find.text(AppStrings.memoryFilterApply));
      await tester.pumpAndSettle();

      expect(find.text('Memória arquivada'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.more_vert_rounded));
      await tester.pumpAndSettle();
      await tester.tap(find.text(AppStrings.memoryRestoreAction));
      await tester.pumpAndSettle();

      expect(find.text('Memória arquivada'), findsNothing);
      expect(find.text(AppStrings.memoryRestoredSuccess), findsOneWidget);
      expect(repository.restoreCalls, 1);
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

ClientMemory _memory({
  required String id,
  required String content,
  bool isArchived = false,
}) {
  return ClientMemory(
    id: id,
    clientId: 'client-1',
    salonId: 'salon-1',
    ownerId: 'owner-1',
    content: content,
    isArchived: isArchived,
    isActive: true,
    createdAt: DateTime(2026, 7, 8),
  );
}

class _FakeClientMemoryRepository implements ClientMemoryRepository {
  List<ClientMemory> memories = [];
  var restoreCalls = 0;

  @override
  Future<ClientMemory> restore(String memoryId) async {
    restoreCalls++;
    final index = memories.indexWhere((memory) => memory.id == memoryId);
    if (index == -1) {
      throw FormatException(AppStrings.memoryRestoreError);
    }

    final restored = memories[index].copyWith(isArchived: false);
    memories[index] = restored;
    return restored;
  }

  @override
  Future<List<ClientMemory>> findByClient({
    required String clientId,
    bool includeArchived = false,
  }) async {
    if (includeArchived) {
      return List<ClientMemory>.from(memories);
    }

    return memories.where((memory) => !memory.isArchived).toList();
  }

  @override
  Future<ClientMemory> archive(String memoryId) async {
    final index = memories.indexWhere((memory) => memory.id == memoryId);
    final archived = memories[index].copyWith(isArchived: true);
    memories[index] = archived;
    return archived;
  }

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
