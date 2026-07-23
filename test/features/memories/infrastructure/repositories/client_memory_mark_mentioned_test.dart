import 'package:flutter_test/flutter_test.dart';
import 'package:lacos_app/features/memories/domain/entities/client_memory.dart';
import 'package:lacos_app/features/memories/domain/repositories/client_memory_repository.dart';

void main() {
  group('ClientMemoryRepository markMentioned', () {
    late _SpyClientMemoryRepository repository;

    setUp(() {
      repository = _SpyClientMemoryRepository();
    });

    test('markMentioned delega para touchMentioned com um único id', () async {
      await repository.markMentioned('memory-1');

      expect(repository.touchedMemoryIds, ['memory-1']);
      expect(repository.updateCalls, 0);
      expect(repository.createCalls, 0);
      expect(repository.deleteCalls, 0);
    });
  });
}

class _SpyClientMemoryRepository implements ClientMemoryRepository {
  var updateCalls = 0;
  var createCalls = 0;
  var deleteCalls = 0;
  List<String> touchedMemoryIds = const [];

  @override
  Future<void> markMentioned(String memoryId) {
    return touchMentioned(memoryIds: [memoryId]);
  }

  @override
  Future<void> touchMentioned({required List<String> memoryIds}) async {
    touchedMemoryIds = memoryIds;
  }

  @override
  Future<ClientMemory> archive(String memoryId) => throw UnimplementedError();

  @override
  Future<ClientMemory> create(ClientMemory memory) async {
    createCalls++;
    throw UnimplementedError();
  }

  @override
  Future<void> delete(String memoryId) async {
    deleteCalls++;
  }

  @override
  Future<List<ClientMemory>> findByClient({
    required String clientId,
    bool includeArchived = false,
  }) {
    throw UnimplementedError();
  }

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

  @override
  Future<ClientMemory> restore(String memoryId) => throw UnimplementedError();
}
