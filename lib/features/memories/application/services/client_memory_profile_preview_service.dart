import 'package:lacos_app/features/memories/application/models/client_memory_profile_preview.dart';
import 'package:lacos_app/features/memories/application/policies/client_memory_availability_policy.dart';
import 'package:lacos_app/features/memories/domain/entities/client_memory.dart';

class ClientMemoryProfilePreviewService {
  const ClientMemoryProfilePreviewService._();

  static const maxItems = 2;

  static ClientMemoryProfilePreview resolve(List<ClientMemory> memories) {
    if (memories.isEmpty) {
      return ClientMemoryProfilePreview.empty;
    }

    final eligibleMemories = memories
        .where(ClientMemoryAvailabilityPolicy.canHighlight)
        .toList(growable: false);

    if (eligibleMemories.isEmpty) {
      return ClientMemoryProfilePreview.empty;
    }

    final pinnedMemories = eligibleMemories
        .where((memory) => memory.isPinned)
        .toList(growable: false);

    if (pinnedMemories.isNotEmpty) {
      return ClientMemoryProfilePreview(
        kind: ClientMemoryProfilePreviewKind.pinned,
        items: pinnedMemories.take(maxItems).toList(growable: false),
      );
    }

    final recentlyMentionedMemories =
        eligibleMemories
            .where((memory) => memory.lastMentionedAt != null)
            .toList(growable: false)
          ..sort(_compareByLastMentionedDesc);

    if (recentlyMentionedMemories.isNotEmpty) {
      return ClientMemoryProfilePreview(
        kind: ClientMemoryProfilePreviewKind.recentlyMentioned,
        items: recentlyMentionedMemories.take(maxItems).toList(growable: false),
      );
    }

    final newestMemories = List<ClientMemory>.from(eligibleMemories)
      ..sort(_compareByCreatedAtDesc);

    return ClientMemoryProfilePreview(
      kind: ClientMemoryProfilePreviewKind.newest,
      items: newestMemories.take(maxItems).toList(growable: false),
    );
  }

  static int _compareByLastMentionedDesc(ClientMemory a, ClientMemory b) {
    return b.lastMentionedAt!.compareTo(a.lastMentionedAt!);
  }

  static int _compareByCreatedAtDesc(ClientMemory a, ClientMemory b) {
    final aCreatedAt = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
    final bCreatedAt = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
    return bCreatedAt.compareTo(aCreatedAt);
  }
}
