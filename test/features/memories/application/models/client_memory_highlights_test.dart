import 'package:flutter_test/flutter_test.dart';
import 'package:lacos_app/features/memories/application/models/client_memory_highlights.dart';
import 'package:lacos_app/features/memories/domain/entities/client_memory.dart';

void main() {
  group('ClientMemoryHighlights', () {
    test('isEmpty quando pinned e recent estão vazios', () {
      const highlights = ClientMemoryHighlights();

      expect(highlights.isEmpty, isTrue);
      expect(highlights.hasContent, isFalse);
    });

    test('hasContent quando pinned possui itens', () {
      final highlights = ClientMemoryHighlights(
        pinned: [_sampleMemory(id: 'm1')],
      );

      expect(highlights.isEmpty, isFalse);
      expect(highlights.hasContent, isTrue);
    });

    test('previewItems retorna até duas fixadas', () {
      final highlights = ClientMemoryHighlights(
        pinned: [
          _sampleMemory(id: 'm1'),
          _sampleMemory(id: 'm2'),
          _sampleMemory(id: 'm3'),
        ],
        recent: [_sampleMemory(id: 'r1')],
      );

      expect(highlights.previewItems.map((memory) => memory.id), ['m1', 'm2']);
    });

    test('previewItems retorna recentes quando não há fixadas', () {
      final highlights = ClientMemoryHighlights(
        recent: [
          _sampleMemory(id: 'r1'),
          _sampleMemory(id: 'r2'),
          _sampleMemory(id: 'r3'),
        ],
      );

      expect(highlights.previewItems.map((memory) => memory.id), ['r1', 'r2']);
    });
  });
}

ClientMemory _sampleMemory({required String id}) {
  return ClientMemory(
    id: id,
    clientId: 'client-1',
    salonId: 'salon-1',
    ownerId: 'owner-1',
    content: 'Memory $id',
    isActive: true,
  );
}
