import 'package:lacos_app/features/memories/domain/entities/client_memory.dart';

class ClientMemoryRank {
  const ClientMemoryRank({
    required this.isPinned,
    required this.priorityWeight,
    required this.sortAt,
  });

  final bool isPinned;
  final int priorityWeight;
  final DateTime sortAt;
}

class ClientMemoryRankResolver {
  const ClientMemoryRankResolver._();

  static ClientMemoryRank resolve(ClientMemory memory) {
    return ClientMemoryRank(
      isPinned: memory.isPinned,
      priorityWeight: memory.priority.sortWeight,
      sortAt:
          memory.lastMentionedAt ??
          memory.updatedAt ??
          memory.createdAt ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}
