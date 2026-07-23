import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lacos_app/features/memories/application/memory_providers.dart';
import 'package:lacos_app/features/memories/application/models/client_memory_profile_preview.dart';
import 'package:lacos_app/features/memories/domain/entities/client_memory.dart';
import 'package:lacos_app/features/memories/domain/repositories/client_memory_repository.dart';

void main() {
  group('clientMemoryProfilePreviewProvider', () {
    test(
      'deriva da mesma consulta e retorna fallback com memórias comuns',
      () async {
        final repository = _FakeClientMemoryRepository(
          memories: [
            _memory(id: 'common-1', createdAt: DateTime(2026, 7, 14)),
            _memory(id: 'common-2', createdAt: DateTime(2026, 7, 13)),
          ],
        );

        final container = ProviderContainer(
          overrides: [
            clientMemoryRepositoryProvider.overrideWithValue(repository),
          ],
        );
        addTearDown(container.dispose);

        await container.read(clientMemoriesProvider('client-1').future);

        final preview = container.read(
          clientMemoryProfilePreviewProvider('client-1'),
        );

        expect(repository.findByClientCalls, 1);
        expect(preview.kind, ClientMemoryProfilePreviewKind.newest);
        expect(preview.items.map((memory) => memory.id), [
          'common-1',
          'common-2',
        ]);
        expect(preview.hasContent, isTrue);
      },
    );
  });
}

ClientMemory _memory({required String id, DateTime? createdAt}) {
  return ClientMemory(
    id: id,
    clientId: 'client-1',
    salonId: 'salon-1',
    ownerId: 'owner-1',
    content: 'Memory $id',
    isActive: true,
    createdAt: createdAt,
    updatedAt: createdAt,
  );
}

class _FakeClientMemoryRepository implements ClientMemoryRepository {
  _FakeClientMemoryRepository({required this.memories});

  final List<ClientMemory> memories;
  var findByClientCalls = 0;

  @override
  Future<List<ClientMemory>> findByClient({
    required String clientId,
    bool includeArchived = false,
  }) async {
    findByClientCalls++;
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
