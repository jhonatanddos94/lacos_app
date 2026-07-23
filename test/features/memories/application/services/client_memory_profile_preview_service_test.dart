import 'package:flutter_test/flutter_test.dart';
import 'package:lacos_app/features/memories/application/models/client_memory_profile_preview.dart';
import 'package:lacos_app/features/memories/application/services/client_memory_profile_preview_service.dart';
import 'package:lacos_app/features/memories/domain/entities/client_memory.dart';

void main() {
  group('ClientMemoryProfilePreviewService', () {
    test('retorna até 2 fixadas', () {
      final result = ClientMemoryProfilePreviewService.resolve([
        _memory(id: 'p1', isPinned: true),
        _memory(id: 'p2', isPinned: true),
        _memory(id: 'p3', isPinned: true),
      ]);

      expect(result.kind, ClientMemoryProfilePreviewKind.pinned);
      expect(result.items.map((memory) => memory.id), ['p1', 'p2']);
    });

    test('prioriza fixadas mesmo quando há recentes e comuns', () {
      final result = ClientMemoryProfilePreviewService.resolve([
        _memory(id: 'recent', lastMentionedAt: DateTime(2026, 7, 14)),
        _memory(id: 'common', createdAt: DateTime(2026, 7, 13)),
        _memory(id: 'pinned', isPinned: true),
      ]);

      expect(result.kind, ClientMemoryProfilePreviewKind.pinned);
      expect(result.items.single.id, 'pinned');
    });

    test('usa recentes quando não há fixadas', () {
      final result = ClientMemoryProfilePreviewService.resolve([
        _memory(id: 'old', lastMentionedAt: DateTime(2026, 7, 1)),
        _memory(id: 'new', lastMentionedAt: DateTime(2026, 7, 14)),
        _memory(id: 'common', createdAt: DateTime(2026, 7, 15)),
      ]);

      expect(result.kind, ClientMemoryProfilePreviewKind.recentlyMentioned);
      expect(result.items.map((memory) => memory.id), ['new', 'old']);
    });

    test('usa memórias mais novas quando não há fixadas nem recentes', () {
      final result = ClientMemoryProfilePreviewService.resolve([
        _memory(id: 'older', createdAt: DateTime(2026, 7, 1)),
        _memory(id: 'newer', createdAt: DateTime(2026, 7, 14)),
        _memory(id: 'middle', createdAt: DateTime(2026, 7, 8)),
      ]);

      expect(result.kind, ClientMemoryProfilePreviewKind.newest);
      expect(result.items.map((memory) => memory.id), ['newer', 'middle']);
    });

    test('limita o resultado a 2', () {
      final result = ClientMemoryProfilePreviewService.resolve([
        _memory(id: 'c1', createdAt: DateTime(2026, 7, 14)),
        _memory(id: 'c2', createdAt: DateTime(2026, 7, 13)),
        _memory(id: 'c3', createdAt: DateTime(2026, 7, 12)),
      ]);

      expect(result.items, hasLength(2));
    });

    test('ignora arquivadas', () {
      final result = ClientMemoryProfilePreviewService.resolve([
        _memory(id: 'archived', isArchived: true, isPinned: true),
        _memory(id: 'active', isPinned: true),
      ]);

      expect(result.items.map((memory) => memory.id), ['active']);
    });

    test('ignora inativas', () {
      final result = ClientMemoryProfilePreviewService.resolve([
        _memory(id: 'inactive', isActive: false, isPinned: true),
        _memory(id: 'active', isPinned: true),
      ]);

      expect(result.items.map((memory) => memory.id), ['active']);
    });

    test('retorna vazio sem memórias válidas', () {
      final result = ClientMemoryProfilePreviewService.resolve(const []);

      expect(result, ClientMemoryProfilePreview.empty);
      expect(result.hasContent, isFalse);
    });
  });
}

ClientMemory _memory({
  required String id,
  bool isPinned = false,
  bool isArchived = false,
  bool isActive = true,
  DateTime? lastMentionedAt,
  DateTime? createdAt,
}) {
  return ClientMemory(
    id: id,
    clientId: 'client-1',
    salonId: 'salon-1',
    ownerId: 'owner-1',
    content: 'Memory $id',
    isPinned: isPinned,
    isArchived: isArchived,
    isActive: isActive,
    lastMentionedAt: lastMentionedAt,
    createdAt: createdAt ?? DateTime(2026, 7, 1),
    updatedAt: createdAt ?? DateTime(2026, 7, 1),
  );
}
