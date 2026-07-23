import 'package:lacos_app/features/memories/domain/entities/client_memory.dart';

class ClientMemoryAvailabilityPolicy {
  const ClientMemoryAvailabilityPolicy._();

  static bool canPin(ClientMemory memory) {
    return memory.isActive && !memory.isArchived;
  }

  static bool canMention(ClientMemory memory) {
    return memory.isActive && !memory.isArchived;
  }

  static bool canHighlight(ClientMemory memory) {
    return memory.isActive && !memory.isArchived;
  }

  static bool canArchive(ClientMemory memory) {
    return memory.isActive && !memory.isArchived;
  }

  static bool canRestore(ClientMemory memory) {
    return memory.isActive && memory.isArchived;
  }
}
