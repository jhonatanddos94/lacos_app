import 'package:lacos_app/features/memories/application/models/client_memory_highlights.dart';
import 'package:lacos_app/features/memories/application/policies/client_memory_availability_policy.dart';
import 'package:lacos_app/features/memories/domain/entities/client_memory.dart';

class ClientMemoryHighlightsService {
  const ClientMemoryHighlightsService._();

  static const maxRecentCount = 3;

  static ClientMemoryHighlights resolve(List<ClientMemory> memories) {
    if (memories.isEmpty) {
      return ClientMemoryHighlights.empty;
    }

    final activeMemories = memories
        .where(ClientMemoryAvailabilityPolicy.canHighlight)
        .toList(growable: false);

    if (activeMemories.isEmpty) {
      return ClientMemoryHighlights.empty;
    }

    final pinned = activeMemories
        .where((memory) => memory.isPinned)
        .toList(growable: false);

    final pinnedIds = pinned
        .map((memory) => memory.id)
        .whereType<String>()
        .toSet();

    final recentCandidates =
        activeMemories
            .where(
              (memory) =>
                  memory.lastMentionedAt != null &&
                  !pinnedIds.contains(memory.id),
            )
            .toList(growable: false)
          ..sort(_compareByLastMentionedDesc);

    final recent = recentCandidates
        .take(maxRecentCount)
        .toList(growable: false);

    return ClientMemoryHighlights(
      pinned: List<ClientMemory>.unmodifiable(pinned),
      recent: List<ClientMemory>.unmodifiable(recent),
    );
  }

  static int _compareByLastMentionedDesc(ClientMemory a, ClientMemory b) {
    final aMentioned = a.lastMentionedAt!;
    final bMentioned = b.lastMentionedAt!;
    return bMentioned.compareTo(aMentioned);
  }
}
