import 'package:lacos_app/features/appointments/application/models/appointment_preparation_memory_item.dart';
import 'package:lacos_app/features/memories/domain/entities/client_memory.dart';
import 'package:lacos_app/features/memories/domain/services/client_memory_rank_resolver.dart';

class AppointmentPreparationMemorySorter {
  const AppointmentPreparationMemorySorter._();

  static const displayLimit = 3;

  static List<AppointmentPreparationMemoryItem> selectTop({
    required List<ClientMemory> memories,
    ClientMemoryRank Function(ClientMemory memory)? rankFor,
    String Function(int index)? emojiForIndex,
  }) {
    if (memories.isEmpty) {
      return const [];
    }

    final resolveRank = rankFor ?? _defaultRank;
    final resolveEmoji = emojiForIndex ?? _defaultEmojiForIndex;

    final rankedMemories = memories
        .where((memory) => memory.isVisible && memory.content.trim().isNotEmpty)
        .map((memory) {
          final rank = resolveRank(memory);
          return (memory: memory, rank: rank);
        })
        .toList(growable: false);

    rankedMemories.sort((a, b) {
      final pinnedCompare = (b.rank.isPinned ? 1 : 0).compareTo(
        a.rank.isPinned ? 1 : 0,
      );
      if (pinnedCompare != 0) {
        return pinnedCompare;
      }

      final priorityCompare = b.rank.priorityWeight.compareTo(
        a.rank.priorityWeight,
      );
      if (priorityCompare != 0) {
        return priorityCompare;
      }

      return b.rank.sortAt.compareTo(a.rank.sortAt);
    });

    return rankedMemories
        .take(displayLimit)
        .toList(growable: false)
        .asMap()
        .entries
        .map(
          (entry) => AppointmentPreparationMemoryItem(
            memoryId: entry.value.memory.id,
            content: entry.value.memory.content.trim(),
            displayEmoji: resolveEmoji(entry.key),
            isPinned: entry.value.rank.isPinned,
            priorityWeight: entry.value.rank.priorityWeight,
            sortAt: entry.value.rank.sortAt,
          ),
        )
        .toList(growable: false);
  }

  static ClientMemoryRank _defaultRank(ClientMemory memory) {
    return ClientMemoryRankResolver.resolve(memory);
  }

  static String _defaultEmojiForIndex(int index) {
    const emojis = ['💜', '☕', '✈️'];
    return emojis[index % emojis.length];
  }
}
