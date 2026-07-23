import 'package:flutter_test/flutter_test.dart';
import 'package:lacos_app/features/memories/domain/entities/client_memory.dart';
import 'package:lacos_app/features/memories/domain/enums/client_memory_priority.dart';
import 'package:lacos_app/features/memories/domain/enums/client_memory_type.dart';
import 'package:lacos_app/features/memories/domain/services/client_memory_rank_resolver.dart';

void main() {
  group('ClientMemoryType', () {
    test('valor ausente retorna other', () {
      expect(ClientMemoryType.fromParse(null), ClientMemoryType.other);
      expect(ClientMemoryType.fromParse(''), ClientMemoryType.other);
    });

    test('valor desconhecido retorna other', () {
      expect(ClientMemoryType.fromParse('invalid'), ClientMemoryType.other);
    });

    test('healthAttention usa snake_case no Parse', () {
      expect(ClientMemoryType.healthAttention.parseValue, 'health_attention');
      expect(
        ClientMemoryType.fromParse('health_attention'),
        ClientMemoryType.healthAttention,
      );
    });
  });

  group('ClientMemoryPriority', () {
    test('valor ausente retorna normal', () {
      expect(ClientMemoryPriority.fromParse(null), ClientMemoryPriority.normal);
    });

    test('valor desconhecido retorna normal', () {
      expect(
        ClientMemoryPriority.fromParse('invalid'),
        ClientMemoryPriority.normal,
      );
    });

    test('legado numérico mapeia para normal ou high', () {
      expect(ClientMemoryPriority.fromParse(0), ClientMemoryPriority.normal);
      expect(ClientMemoryPriority.fromParse(1), ClientMemoryPriority.high);
      expect(ClientMemoryPriority.fromParse(2), ClientMemoryPriority.high);
    });
  });

  group('ClientMemoryRankResolver', () {
    ClientMemory memory({
      bool isPinned = false,
      ClientMemoryPriority priority = ClientMemoryPriority.normal,
      DateTime? lastMentionedAt,
      DateTime? updatedAt,
      DateTime? createdAt,
    }) {
      return ClientMemory(
        id: 'memory-1',
        clientId: 'client-1',
        salonId: 'salon-1',
        ownerId: 'owner-1',
        content: 'Conteúdo',
        isPinned: isPinned,
        priority: priority,
        lastMentionedAt: lastMentionedAt,
        isActive: true,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
    }

    test('usa isPinned e priority do domínio', () {
      final rank = ClientMemoryRankResolver.resolve(
        memory(isPinned: true, priority: ClientMemoryPriority.high),
      );

      expect(rank.isPinned, isTrue);
      expect(rank.priorityWeight, ClientMemoryPriority.high.sortWeight);
    });

    test('prioriza lastMentionedAt para relevância temporal', () {
      final rank = ClientMemoryRankResolver.resolve(
        memory(
          lastMentionedAt: DateTime(2026, 7, 10, 15),
          updatedAt: DateTime(2026, 7, 9),
          createdAt: DateTime(2026, 7, 1),
        ),
      );

      expect(rank.sortAt, DateTime(2026, 7, 10, 15));
    });

    test('cai para updatedAt e depois createdAt', () {
      final fromUpdated = ClientMemoryRankResolver.resolve(
        memory(
          updatedAt: DateTime(2026, 7, 8),
          createdAt: DateTime(2026, 7, 1),
        ),
      );
      final fromCreated = ClientMemoryRankResolver.resolve(
        memory(createdAt: DateTime(2026, 7, 2)),
      );

      expect(fromUpdated.sortAt, DateTime(2026, 7, 8));
      expect(fromCreated.sortAt, DateTime(2026, 7, 2));
    });
  });

  group('ClientMemory', () {
    test('isVisible exige ativa e não arquivada', () {
      const active = ClientMemory(
        clientId: 'client-1',
        salonId: 'salon-1',
        ownerId: 'owner-1',
        content: 'Ativa',
        isActive: true,
      );
      const archived = ClientMemory(
        clientId: 'client-1',
        salonId: 'salon-1',
        ownerId: 'owner-1',
        content: 'Arquivada',
        isArchived: true,
        isActive: true,
      );
      const deleted = ClientMemory(
        clientId: 'client-1',
        salonId: 'salon-1',
        ownerId: 'owner-1',
        content: 'Excluída',
        isActive: false,
      );

      expect(active.isVisible, isTrue);
      expect(archived.isVisible, isFalse);
      expect(deleted.isVisible, isFalse);
    });

    test('draft aplica defaults oficiais', () {
      final memory = ClientMemory.draft(
        clientId: 'client-1',
        content: 'Prefere água com gás',
      );

      expect(memory.type, ClientMemoryType.other);
      expect(memory.priority, ClientMemoryPriority.normal);
      expect(memory.isPinned, isFalse);
      expect(memory.isArchived, isFalse);
      expect(memory.isActive, isTrue);
    });
  });
}
