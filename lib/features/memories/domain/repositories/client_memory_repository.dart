import 'package:lacos_app/features/memories/domain/entities/client_memory.dart';

abstract class ClientMemoryRepository {
  Future<ClientMemory> create(ClientMemory memory);

  Future<ClientMemory> update(ClientMemory memory);

  Future<void> delete(String memoryId);

  Future<List<ClientMemory>> findByClient({
    required String clientId,
    bool includeArchived = false,
  });

  Future<void> touchMentioned({required List<String> memoryIds});

  Future<ClientMemory> setPinned({
    required String memoryId,
    required bool isPinned,
  });

  Future<ClientMemory> archive(String memoryId);
}
