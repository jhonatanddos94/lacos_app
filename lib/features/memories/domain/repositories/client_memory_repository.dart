import 'package:lacos_app/features/memories/domain/entities/client_memory.dart';

abstract class ClientMemoryRepository {
  Future<ClientMemory> create(ClientMemory memory);

  Future<ClientMemory> update(ClientMemory memory);

  Future<void> delete(String memoryId);

  Future<List<ClientMemory>> findByClient({
    required String clientId,
  });

  Future<void> touchMentioned({
    required List<String> memoryIds,
  });
}
