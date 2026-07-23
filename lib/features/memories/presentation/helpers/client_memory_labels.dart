import 'package:lacos_app/core/config/app_strings.dart';
import 'package:lacos_app/features/memories/domain/enums/client_memory_priority.dart';
import 'package:lacos_app/features/memories/domain/enums/client_memory_type.dart';
import 'package:lacos_app/features/memories/application/models/client_memory_sort_order.dart';
import 'package:lacos_app/features/memories/application/models/client_memory_visibility_filter.dart';

class ClientMemoryLabels {
  const ClientMemoryLabels._();

  static String typeLabel(ClientMemoryType type) {
    return switch (type) {
      ClientMemoryType.personal => AppStrings.memoryTypePersonal,
      ClientMemoryType.preference => AppStrings.memoryTypePreference,
      ClientMemoryType.family => AppStrings.memoryTypeFamily,
      ClientMemoryType.work => AppStrings.memoryTypeWork,
      ClientMemoryType.event => AppStrings.memoryTypeEvent,
      ClientMemoryType.healthAttention => AppStrings.memoryTypeHealthAttention,
      ClientMemoryType.other => AppStrings.memoryTypeOther,
    };
  }

  static String priorityLabel(ClientMemoryPriority priority) {
    return switch (priority) {
      ClientMemoryPriority.low => AppStrings.memoryPriorityLow,
      ClientMemoryPriority.normal => AppStrings.memoryPriorityNormal,
      ClientMemoryPriority.high => AppStrings.memoryPriorityHigh,
    };
  }

  static String visibilityLabel(ClientMemoryVisibilityFilter visibility) {
    return switch (visibility) {
      ClientMemoryVisibilityFilter.all => AppStrings.memoryFilterAll,
      ClientMemoryVisibilityFilter.pinned => AppStrings.memoryFilterPinnedOnly,
      ClientMemoryVisibilityFilter.archived =>
        AppStrings.memoryFilterArchivedOnly,
    };
  }

  static String sortOrderLabel(ClientMemorySortOrder sortOrder) {
    return switch (sortOrder) {
      ClientMemorySortOrder.newest => AppStrings.memoryFilterNewest,
      ClientMemorySortOrder.oldest => AppStrings.memoryFilterOldest,
      ClientMemorySortOrder.recentlyMentioned =>
        AppStrings.memoryFilterRecentlyMentioned,
    };
  }

  static bool shouldHighlightPriority(ClientMemoryPriority priority) {
    return priority != ClientMemoryPriority.normal;
  }
}
