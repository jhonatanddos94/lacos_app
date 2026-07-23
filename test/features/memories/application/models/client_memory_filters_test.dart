import 'package:flutter_test/flutter_test.dart';
import 'package:lacos_app/features/memories/application/models/client_memory_filters.dart';
import 'package:lacos_app/features/memories/domain/enums/client_memory_priority.dart';
import 'package:lacos_app/features/memories/domain/enums/client_memory_type.dart';
import 'package:lacos_app/features/memories/application/models/client_memory_sort_order.dart';
import 'package:lacos_app/features/memories/application/models/client_memory_visibility_filter.dart';

void main() {
  group('ClientMemoryFilters', () {
    test('defaults seguem valores oficiais', () {
      const filters = ClientMemoryFilters.defaults;

      expect(filters.visibility, ClientMemoryVisibilityFilter.all);
      expect(filters.type, isNull);
      expect(filters.priority, isNull);
      expect(filters.sortOrder, ClientMemorySortOrder.newest);
      expect(filters.hasActiveFilters, isFalse);
    });

    test('copyWith altera somente campos informados', () {
      const original = ClientMemoryFilters.defaults;
      final updated = original.copyWith(
        visibility: ClientMemoryVisibilityFilter.pinned,
        type: ClientMemoryType.family,
        priority: ClientMemoryPriority.high,
        sortOrder: ClientMemorySortOrder.oldest,
      );

      expect(updated.visibility, ClientMemoryVisibilityFilter.pinned);
      expect(updated.type, ClientMemoryType.family);
      expect(updated.priority, ClientMemoryPriority.high);
      expect(updated.sortOrder, ClientMemorySortOrder.oldest);
    });

    test('clearType e clearPriority removem seleção', () {
      const filters = ClientMemoryFilters(
        type: ClientMemoryType.work,
        priority: ClientMemoryPriority.low,
      );

      final clearedType = filters.copyWith(clearType: true);
      final clearedPriority = filters.copyWith(clearPriority: true);

      expect(clearedType.type, isNull);
      expect(clearedType.priority, ClientMemoryPriority.low);
      expect(clearedPriority.type, ClientMemoryType.work);
      expect(clearedPriority.priority, isNull);
    });

    test('cleared restaura valores padrão', () {
      const filters = ClientMemoryFilters(
        visibility: ClientMemoryVisibilityFilter.archived,
        type: ClientMemoryType.event,
        priority: ClientMemoryPriority.high,
        sortOrder: ClientMemorySortOrder.recentlyMentioned,
      );

      expect(filters.cleared(), ClientMemoryFilters.defaults);
    });

    test('hasActiveFilters detecta visibilidade diferente do padrão', () {
      const filters = ClientMemoryFilters(
        visibility: ClientMemoryVisibilityFilter.pinned,
      );

      expect(filters.hasActiveFilters, isTrue);
    });

    test('hasActiveFilters detecta categoria e prioridade', () {
      expect(
        const ClientMemoryFilters(
          type: ClientMemoryType.personal,
        ).hasActiveFilters,
        isTrue,
      );
      expect(
        const ClientMemoryFilters(
          priority: ClientMemoryPriority.normal,
        ).hasActiveFilters,
        isTrue,
      );
    });

    test('hasActiveFilters detecta ordenação não padrão', () {
      const filters = ClientMemoryFilters(
        sortOrder: ClientMemorySortOrder.recentlyMentioned,
      );

      expect(filters.hasActiveFilters, isTrue);
    });

    test('igualdade considera todos os campos', () {
      const first = ClientMemoryFilters(
        visibility: ClientMemoryVisibilityFilter.pinned,
        type: ClientMemoryType.family,
        priority: ClientMemoryPriority.high,
        sortOrder: ClientMemorySortOrder.oldest,
      );
      const second = ClientMemoryFilters(
        visibility: ClientMemoryVisibilityFilter.pinned,
        type: ClientMemoryType.family,
        priority: ClientMemoryPriority.high,
        sortOrder: ClientMemorySortOrder.oldest,
      );
      const different = ClientMemoryFilters(
        sortOrder: ClientMemorySortOrder.newest,
      );

      expect(first, second);
      expect(first == different, isFalse);
      expect(first.hashCode, second.hashCode);
    });
  });
}
