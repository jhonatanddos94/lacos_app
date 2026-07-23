import 'package:flutter_test/flutter_test.dart';
import 'package:lacos_app/features/memories/application/memory_providers.dart';
import 'package:lacos_app/features/memories/domain/entities/client_memory.dart';
import 'package:lacos_app/features/memories/domain/repositories/client_memory_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  group('clientMemoryHighlightsProvider', () {
    test('ignora memórias arquivadas do catálogo', () async {
      final repository = _FakeClientMemoryRepository(
        memories: [
          _memory(id: 'active', isArchived: false, isPinned: true),
          _memory(id: 'archived', isArchived: true, isPinned: true),
        ],
      );

      final container = ProviderContainer(
        overrides: [
          clientMemoryRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(container.dispose);

      await container.read(clientMemoriesProvider('client-1').future);

      final highlights = container.read(
        clientMemoryHighlightsProvider('client-1'),
      );

      expect(highlights.pinned.map((memory) => memory.id), ['active']);
      expect(highlights.hasContent, isTrue);
    });
  });
}

ClientMemory _memory({
  required String id,
  required bool isArchived,
  bool isPinned = false,
}) {
  return ClientMemory(
    id: id,
    clientId: 'client-1',
    salonId: 'salon-1',
    ownerId: 'owner-1',
    content: 'Memory $id',
    isArchived: isArchived,
    isPinned: isPinned,
    isActive: true,
  );
}

class _FakeClientMemoryRepository implements ClientMemoryRepository {
  _FakeClientMemoryRepository({required this.memories});

  final List<ClientMemory> memories;

  @override
  Future<List<ClientMemory>> findByClient({
    required String clientId,
    bool includeArchived = false,
  }) async {
    if (includeArchived) {
      return memories;
    }

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
