import 'package:lacos_app/features/memories/application/models/client_memory_filters.dart';
import 'package:lacos_app/features/memories/application/models/client_memory_sort_order.dart';
import 'package:lacos_app/features/memories/application/models/client_memory_visibility_filter.dart';
import 'package:lacos_app/features/memories/domain/entities/client_memory.dart';

class ClientMemoryFilterService {
  const ClientMemoryFilterService._();

  static List<ClientMemory> apply({
    required List<ClientMemory> memories,
    required ClientMemoryFilters filters,
  }) {
    if (memories.isEmpty) {
      return const [];
    }

    final filtered = memories
        .where((memory) {
          if (!_matchesVisibility(memory, filters.visibility)) {
            return false;
          }

          if (filters.type != null && memory.type != filters.type) {
            return false;
          }

          if (filters.priority != null && memory.priority != filters.priority) {
            return false;
          }

          return true;
        })
        .toList(growable: false);

    final sorted = List<ClientMemory>.from(filtered);
    sorted.sort((a, b) => _compareMemories(a, b, filters));
    return List<ClientMemory>.unmodifiable(sorted);
  }

  static bool _matchesVisibility(
    ClientMemory memory,
    ClientMemoryVisibilityFilter visibility,
  ) {
    return switch (visibility) {
      ClientMemoryVisibilityFilter.all => !memory.isArchived,
      ClientMemoryVisibilityFilter.pinned =>
        memory.isPinned && !memory.isArchived,
      ClientMemoryVisibilityFilter.archived => memory.isArchived,
    };
  }

  static int _compareMemories(
    ClientMemory a,
    ClientMemory b,
    ClientMemoryFilters filters,
  ) {
    if (filters.visibility != ClientMemoryVisibilityFilter.archived) {
      final pinnedCompare = (b.isPinned ? 1 : 0).compareTo(a.isPinned ? 1 : 0);
      if (pinnedCompare != 0) {
        return pinnedCompare;
      }
    }

    return switch (filters.sortOrder) {
      ClientMemorySortOrder.newest => _compareByCreatedAt(
        a,
        b,
        newestFirst: true,
      ),
      ClientMemorySortOrder.oldest => _compareByCreatedAt(
        a,
        b,
        newestFirst: false,
      ),
      ClientMemorySortOrder.recentlyMentioned => _compareByRecentlyMentioned(
        a,
        b,
      ),
    };
  }

  static int _compareByCreatedAt(
    ClientMemory a,
    ClientMemory b, {
    required bool newestFirst,
  }) {
    final aDate = _createdAtOrEpoch(a);
    final bDate = _createdAtOrEpoch(b);
    final compare = bDate.compareTo(aDate);
    return newestFirst ? compare : -compare;
  }

  static int _compareByRecentlyMentioned(ClientMemory a, ClientMemory b) {
    final aMentioned = a.lastMentionedAt;
    final bMentioned = b.lastMentionedAt;

    if (aMentioned != null && bMentioned != null) {
      final compare = bMentioned.compareTo(aMentioned);
      if (compare != 0) {
        return compare;
      }
    } else if (aMentioned != null) {
      return -1;
    } else if (bMentioned != null) {
      return 1;
    }

    return _compareByCreatedAt(a, b, newestFirst: true);
  }

  static DateTime _createdAtOrEpoch(ClientMemory memory) {
    return memory.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
  }
}
