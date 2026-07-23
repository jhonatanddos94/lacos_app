import 'package:flutter_test/flutter_test.dart';
import 'package:lacos_app/features/memories/application/policies/client_memory_availability_policy.dart';
import 'package:lacos_app/features/memories/domain/entities/client_memory.dart';

void main() {
  group('ClientMemoryAvailabilityPolicy', () {
    test('memória ativa permite pin, mention e highlight', () {
      final memory = _memory(isArchived: false);

      expect(ClientMemoryAvailabilityPolicy.canPin(memory), isTrue);
      expect(ClientMemoryAvailabilityPolicy.canMention(memory), isTrue);
      expect(ClientMemoryAvailabilityPolicy.canHighlight(memory), isTrue);
      expect(ClientMemoryAvailabilityPolicy.canArchive(memory), isTrue);
      expect(ClientMemoryAvailabilityPolicy.canRestore(memory), isFalse);
    });

    test('memória arquivada não pode ser utilizada no atendimento', () {
      final memory = _memory(isArchived: true);

      expect(ClientMemoryAvailabilityPolicy.canPin(memory), isFalse);
      expect(ClientMemoryAvailabilityPolicy.canMention(memory), isFalse);
      expect(ClientMemoryAvailabilityPolicy.canHighlight(memory), isFalse);
      expect(ClientMemoryAvailabilityPolicy.canArchive(memory), isFalse);
      expect(ClientMemoryAvailabilityPolicy.canRestore(memory), isTrue);
    });

    test('memória inativa não participa de nenhuma ação operacional', () {
      final memory = _memory(isActive: false);

      expect(ClientMemoryAvailabilityPolicy.canPin(memory), isFalse);
      expect(ClientMemoryAvailabilityPolicy.canMention(memory), isFalse);
      expect(ClientMemoryAvailabilityPolicy.canHighlight(memory), isFalse);
      expect(ClientMemoryAvailabilityPolicy.canArchive(memory), isFalse);
      expect(ClientMemoryAvailabilityPolicy.canRestore(memory), isFalse);
    });
  });
}

ClientMemory _memory({bool isArchived = false, bool isActive = true}) {
  return ClientMemory(
    id: 'memory-1',
    clientId: 'client-1',
    salonId: 'salon-1',
    ownerId: 'owner-1',
    content: 'Conteúdo',
    isArchived: isArchived,
    isActive: isActive,
  );
}
