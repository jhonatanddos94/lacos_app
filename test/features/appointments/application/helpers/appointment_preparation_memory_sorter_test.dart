import 'package:flutter_test/flutter_test.dart';
import 'package:lacos_app/features/appointments/application/helpers/appointment_preparation_memory_sorter.dart';
import 'package:lacos_app/features/memories/domain/entities/client_memory.dart';
import 'package:lacos_app/features/memories/domain/enums/client_memory_priority.dart';

void main() {
  group('AppointmentPreparationMemorySorter', () {
    ClientMemory memory({
      required String id,
      required String content,
      bool isPinned = false,
      ClientMemoryPriority priority = ClientMemoryPriority.normal,
      DateTime? createdAt,
      DateTime? lastMentionedAt,
      bool isArchived = false,
      bool isActive = true,
    }) {
      return ClientMemory(
        id: id,
        clientId: 'client-1',
        salonId: 'salon-1',
        ownerId: 'owner-1',
        content: content,
        isPinned: isPinned,
        priority: priority,
        lastMentionedAt: lastMentionedAt,
        isArchived: isArchived,
        isActive: isActive,
        createdAt: createdAt,
      );
    }

    test('limita a 3 memórias', () {
      final result = AppointmentPreparationMemorySorter.selectTop(
        memories: List.generate(
          5,
          (index) => memory(
            id: 'memory-$index',
            content: 'Memória $index',
            createdAt: DateTime(2026, 7, 10, index + 1),
          ),
        ),
      );

      expect(result, hasLength(3));
    });

    test('ordena por fixadas, prioridade alta e mais recentes', () {
      final result = AppointmentPreparationMemorySorter.selectTop(
        memories: [
          memory(
            id: '1',
            content: 'Mais antiga',
            createdAt: DateTime(2026, 7, 1),
          ),
          memory(
            id: '2',
            content: 'Prioridade alta',
            priority: ClientMemoryPriority.critical,
            createdAt: DateTime(2026, 7, 2),
          ),
          memory(
            id: '3',
            content: 'Fixada',
            isPinned: true,
            createdAt: DateTime(2026, 7, 3),
          ),
          memory(
            id: '4',
            content: 'Mais recente',
            createdAt: DateTime(2026, 7, 10),
          ),
        ],
      );

      expect(result.map((item) => item.content), [
        'Fixada',
        'Prioridade alta',
        'Mais recente',
      ]);
    });

    test('ignora memórias inativas, arquivadas ou vazias', () {
      final result = AppointmentPreparationMemorySorter.selectTop(
        memories: [
          memory(
            id: 'inactive',
            content: 'Inativa',
            isActive: false,
          ),
          memory(
            id: 'archived',
            content: 'Arquivada',
            isArchived: true,
          ),
          memory(
            id: 'empty',
            content: '   ',
            createdAt: DateTime(2026, 7, 10),
          ),
          memory(
            id: 'valid',
            content: 'Válida',
            createdAt: DateTime(2026, 7, 10, 12),
          ),
        ],
      );

      expect(result, hasLength(1));
      expect(result.first.content, 'Válida');
    });

    test('propaga memoryId para rastrear menções', () {
      final result = AppointmentPreparationMemorySorter.selectTop(
        memories: [
          memory(
            id: 'memory-42',
            content: 'Detalhe importante',
            createdAt: DateTime(2026, 7, 10),
          ),
        ],
      );

      expect(result.single.memoryId, 'memory-42');
    });
  });
}
