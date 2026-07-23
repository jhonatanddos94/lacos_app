import 'package:lacos_app/features/memories/application/models/client_memory_sort_order.dart';
import 'package:lacos_app/features/memories/application/models/client_memory_visibility_filter.dart';
import 'package:lacos_app/features/memories/domain/enums/client_memory_priority.dart';
import 'package:lacos_app/features/memories/domain/enums/client_memory_type.dart';

class ClientMemoryFilters {
  const ClientMemoryFilters({
    this.visibility = ClientMemoryVisibilityFilter.all,
    this.type,
    this.priority,
    this.sortOrder = ClientMemorySortOrder.newest,
  });

  static const defaults = ClientMemoryFilters();

  final ClientMemoryVisibilityFilter visibility;
  final ClientMemoryType? type;
  final ClientMemoryPriority? priority;
  final ClientMemorySortOrder sortOrder;

  bool get hasActiveFilters {
    return visibility != ClientMemoryVisibilityFilter.all ||
        type != null ||
        priority != null ||
        sortOrder != ClientMemorySortOrder.newest;
  }

  ClientMemoryFilters copyWith({
    ClientMemoryVisibilityFilter? visibility,
    ClientMemoryType? type,
    bool clearType = false,
    ClientMemoryPriority? priority,
    bool clearPriority = false,
    ClientMemorySortOrder? sortOrder,
  }) {
    return ClientMemoryFilters(
      visibility: visibility ?? this.visibility,
      type: clearType ? null : (type ?? this.type),
      priority: clearPriority ? null : (priority ?? this.priority),
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  ClientMemoryFilters cleared() => defaults;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is ClientMemoryFilters &&
            visibility == other.visibility &&
            type == other.type &&
            priority == other.priority &&
            sortOrder == other.sortOrder;
  }

  @override
  int get hashCode => Object.hash(visibility, type, priority, sortOrder);
}
