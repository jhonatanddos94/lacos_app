import 'package:flutter_test/flutter_test.dart';
import 'package:lacos_app/features/memories/application/models/client_memory_filters.dart';
import 'package:lacos_app/features/memories/application/services/client_memory_filter_service.dart';
import 'package:lacos_app/features/memories/domain/entities/client_memory.dart';
import 'package:lacos_app/features/memories/domain/enums/client_memory_priority.dart';
import 'package:lacos_app/features/memories/domain/enums/client_memory_type.dart';
import 'package:lacos_app/features/memories/application/models/client_memory_sort_order.dart';
import 'package:lacos_app/features/memories/application/models/client_memory_visibility_filter.dart';

void main() {
  group('ClientMemoryFilterService', () {
    final memories = _sampleMemories();

    test('padrão retorna somente memórias não arquivadas', () {
      final result = ClientMemoryFilterService.apply(
        memories: memories,
        filters: ClientMemoryFilters.defaults,
      );

      expect(result.every((memory) => !memory.isArchived), isTrue);
      expect(result.map((memory) => memory.id), ['m1', 'm4', 'm2', 'm3']);
    });

    test('apenas fixadas retorna somente fixadas e ativas', () {
      final result = ClientMemoryFilterService.apply(
        memories: memories,
        filters: const ClientMemoryFilters(
          visibility: ClientMemoryVisibilityFilter.pinned,
        ),
      );

      expect(result, hasLength(1));
      expect(result.single.id, 'm1');
    });

    test('apenas arquivadas retorna somente arquivadas', () {
      final result = ClientMemoryFilterService.apply(
        memories: memories,
        filters: const ClientMemoryFilters(
          visibility: ClientMemoryVisibilityFilter.archived,
        ),
      );

      expect(result, hasLength(1));
      expect(result.single.id, 'm5');
    });

    test('filtro por categoria', () {
      final result = ClientMemoryFilterService.apply(
        memories: memories,
        filters: const ClientMemoryFilters(type: ClientMemoryType.preference),
      );

      expect(result.map((memory) => memory.id), ['m2']);
    });

    test('filtro por prioridade', () {
      final result = ClientMemoryFilterService.apply(
        memories: memories,
        filters: const ClientMemoryFilters(priority: ClientMemoryPriority.high),
      );

      expect(result.map((memory) => memory.id), ['m1', 'm3']);
    });

    test('combina categoria e prioridade', () {
      final result = ClientMemoryFilterService.apply(
        memories: memories,
        filters: const ClientMemoryFilters(
          type: ClientMemoryType.personal,
          priority: ClientMemoryPriority.high,
        ),
      );

      expect(result.map((memory) => memory.id), ['m3']);
    });

    test('mais recentes ordena por createdAt desc', () {
      final result = ClientMemoryFilterService.apply(
        memories: memories,
        filters: const ClientMemoryFilters(
          visibility: ClientMemoryVisibilityFilter.all,
          sortOrder: ClientMemorySortOrder.newest,
        ),
      );

      expect(result.map((memory) => memory.id), ['m1', 'm4', 'm2', 'm3']);
    });

    test('mais antigas ordena por createdAt asc', () {
      final result = ClientMemoryFilterService.apply(
        memories: memories,
        filters: const ClientMemoryFilters(
          sortOrder: ClientMemorySortOrder.oldest,
        ),
      );

      expect(result.map((memory) => memory.id), ['m1', 'm3', 'm2', 'm4']);
    });

    test('mencionadas recentemente prioriza lastMentionedAt', () {
      final result = ClientMemoryFilterService.apply(
        memories: memories,
        filters: const ClientMemoryFilters(
          sortOrder: ClientMemorySortOrder.recentlyMentioned,
        ),
      );

      expect(result.map((memory) => memory.id), ['m1', 'm4', 'm2', 'm3']);
    });

    test('memórias sem lastMentionedAt ficam depois', () {
      final result = ClientMemoryFilterService.apply(
        memories: memories,
        filters: const ClientMemoryFilters(
          sortOrder: ClientMemorySortOrder.recentlyMentioned,
        ),
      );

      final withoutMention = result
          .where((memory) => memory.lastMentionedAt == null)
          .map((memory) => memory.id)
          .toList();

      expect(withoutMention, ['m1', 'm3']);
      expect(result.indexOfId('m4'), lessThan(result.indexOfId('m2')));
      expect(result.indexOfId('m2'), lessThan(result.indexOfId('m3')));
    });

    test('fixadas aparecem antes na lista ativa', () {
      final result = ClientMemoryFilterService.apply(
        memories: memories,
        filters: const ClientMemoryFilters(
          sortOrder: ClientMemorySortOrder.oldest,
        ),
      );

      expect(result.first.id, 'm1');
      expect(result.first.isPinned, isTrue);
    });

    test('arquivadas não são priorizadas por fixação', () {
      final archivedMemories = [
        _memory(
          id: 'a1',
          content: 'Arquivada comum',
          isArchived: true,
          createdAt: DateTime(2026, 7, 10),
        ),
        _memory(
          id: 'a2',
          content: 'Arquivada fixada',
          isPinned: true,
          isArchived: true,
          createdAt: DateTime(2026, 7, 1),
        ),
      ];

      final result = ClientMemoryFilterService.apply(
        memories: archivedMemories,
        filters: const ClientMemoryFilters(
          visibility: ClientMemoryVisibilityFilter.archived,
          sortOrder: ClientMemorySortOrder.newest,
        ),
      );

      expect(result.map((memory) => memory.id), ['a1', 'a2']);
    });

    test('lista de entrada não é modificada', () {
      final input = List<ClientMemory>.from(memories);
      final snapshot = List<ClientMemory>.from(memories);

      ClientMemoryFilterService.apply(
        memories: input,
        filters: const ClientMemoryFilters(type: ClientMemoryType.family),
      );

      expect(input, snapshot);
    });

    test('lista vazia retorna lista vazia', () {
      final result = ClientMemoryFilterService.apply(
        memories: const [],
        filters: ClientMemoryFilters.defaults,
      );

      expect(result, isEmpty);
    });
  });
}

List<ClientMemory> _sampleMemories() {
  return [
    _memory(
      id: 'm1',
      content: 'Fixada recente',
      type: ClientMemoryType.family,
      priority: ClientMemoryPriority.high,
      isPinned: true,
      createdAt: DateTime(2026, 7, 8, 12),
    ),
    _memory(
      id: 'm2',
      content: 'Preferência mencionada',
      type: ClientMemoryType.preference,
      priority: ClientMemoryPriority.normal,
      createdAt: DateTime(2026, 7, 5, 10),
      lastMentionedAt: DateTime(2026, 7, 7, 9),
    ),
    _memory(
      id: 'm3',
      content: 'Mais antiga',
      type: ClientMemoryType.personal,
      priority: ClientMemoryPriority.high,
      createdAt: DateTime(2026, 7, 1, 8),
    ),
    _memory(
      id: 'm4',
      content: 'Mencionada recentemente',
      type: ClientMemoryType.work,
      priority: ClientMemoryPriority.low,
      createdAt: DateTime(2026, 7, 6, 15),
      lastMentionedAt: DateTime(2026, 7, 9, 11),
    ),
    _memory(
      id: 'm5',
      content: 'Arquivada',
      type: ClientMemoryType.other,
      isArchived: true,
      createdAt: DateTime(2026, 6, 20),
    ),
  ];
}

ClientMemory _memory({
  required String id,
  required String content,
  ClientMemoryType type = ClientMemoryType.other,
  ClientMemoryPriority priority = ClientMemoryPriority.normal,
  bool isPinned = false,
  bool isArchived = false,
  DateTime? createdAt,
  DateTime? lastMentionedAt,
}) {
  return ClientMemory(
    id: id,
    clientId: 'client-1',
    salonId: 'salon-1',
    ownerId: 'owner-1',
    content: content,
    type: type,
    priority: priority,
    isPinned: isPinned,
    isArchived: isArchived,
    lastMentionedAt: lastMentionedAt,
    isActive: true,
    createdAt: createdAt,
  );
}

extension on List<ClientMemory> {
  int indexOfId(String id) => indexWhere((memory) => memory.id == id);
}
