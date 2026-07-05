import 'package:lacos_app/features/memories/domain/entities/client_memory.dart';

abstract class ClientMemoryRepository {
  Future<ClientMemory> create(ClientMemory memory);

  Future<List<ClientMemory>> findByClient({
    required String clientId,
  });
}
