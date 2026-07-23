import 'package:flutter_test/flutter_test.dart';
import 'package:lacos_app/features/memories/domain/entities/client_memory.dart';
import 'package:lacos_app/features/memories/domain/repositories/client_memory_repository.dart';

void main() {
  group('ClientMemoryRepository restore', () {
    late _SpyClientMemoryRepository repository;

    setUp(() {
      repository = _SpyClientMemoryRepository();
    });

    test('restore altera somente isArchived', () async {
      final restored = await repository.restore('memory-1');

      expect(restored.isArchived, isFalse);
      expect(restored.content, 'Conteúdo original');
      expect(restored.isPinned, isTrue);
      expect(repository.updateCalls, 0);
    });
  });
}

class _SpyClientMemoryRepository implements ClientMemoryRepository {
  var updateCalls = 0;

  @override
  Future<ClientMemory> restore(String memoryId) async {
    return ClientMemory(
      id: memoryId,
      clientId: 'client-1',
      salonId: 'salon-1',
      ownerId: 'owner-1',
      content: 'Conteúdo original',
      isPinned: true,
      isArchived: false,
      isActive: true,
    );
  }

  @override
  Future<ClientMemory> archive(String memoryId) => throw UnimplementedError();

  @override
  Future<ClientMemory> create(ClientMemory memory) =>
      throw UnimplementedError();

  @override
  Future<void> delete(String memoryId) => throw UnimplementedError();

  @override
  Future<List<ClientMemory>> findByClient({
    required String clientId,
    bool includeArchived = false,
  }) {
    throw UnimplementedError();
  }

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
  Future<ClientMemory> update(ClientMemory memory) async {
    updateCalls++;
    throw UnimplementedError();
  }
}
