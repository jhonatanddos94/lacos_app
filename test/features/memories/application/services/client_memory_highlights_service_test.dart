import 'package:flutter_test/flutter_test.dart';
import 'package:lacos_app/features/memories/application/models/client_memory_highlights.dart';
import 'package:lacos_app/features/memories/application/services/client_memory_highlights_service.dart';
import 'package:lacos_app/features/memories/domain/entities/client_memory.dart';

void main() {
  group('ClientMemoryHighlightsService', () {
    test('retorna vazio quando lista está vazia', () {
      final result = ClientMemoryHighlightsService.resolve(const []);

      expect(result, ClientMemoryHighlights.empty);
      expect(result.isEmpty, isTrue);
      expect(result.hasContent, isFalse);
    });

    test('retorna somente fixadas não arquivadas', () {
      final result = ClientMemoryHighlightsService.resolve([
        _memory(id: 'pinned-1', isPinned: true),
        _memory(id: 'pinned-2', isPinned: true),
        _memory(id: 'regular'),
      ]);

      expect(result.pinned.map((memory) => memory.id), [
        'pinned-1',
        'pinned-2',
      ]);
      expect(result.recent, isEmpty);
      expect(result.hasContent, isTrue);
    });

    test('retorna somente recentes mencionadas', () {
      final result = ClientMemoryHighlightsService.resolve([
        _memory(id: 'recent-1', lastMentionedAt: DateTime(2026, 7, 10)),
        _memory(id: 'recent-2', lastMentionedAt: DateTime(2026, 7, 8)),
        _memory(id: 'never-mentioned'),
      ]);

      expect(result.pinned, isEmpty);
      expect(result.recent.map((memory) => memory.id), [
        'recent-1',
        'recent-2',
      ]);
    });

    test('combina fixadas e recentes sem duplicatas', () {
      final result = ClientMemoryHighlightsService.resolve([
        _memory(
          id: 'pinned-mentioned',
          isPinned: true,
          lastMentionedAt: DateTime(2026, 7, 12),
        ),
        _memory(id: 'recent-1', lastMentionedAt: DateTime(2026, 7, 11)),
      ]);

      expect(result.pinned.map((memory) => memory.id), ['pinned-mentioned']);
      expect(result.recent.map((memory) => memory.id), ['recent-1']);
    });

    test('ignora memórias arquivadas', () {
      final result = ClientMemoryHighlightsService.resolve([
        _memory(id: 'pinned-archived', isPinned: true, isArchived: true),
        _memory(
          id: 'recent-archived',
          isArchived: true,
          lastMentionedAt: DateTime(2026, 7, 11),
        ),
        _memory(id: 'active-pinned', isPinned: true),
      ]);

      expect(result.pinned.map((memory) => memory.id), ['active-pinned']);
      expect(result.recent, isEmpty);
    });

    test('limita recentes a três memórias', () {
      final result = ClientMemoryHighlightsService.resolve([
        _memory(id: 'r1', lastMentionedAt: DateTime(2026, 7, 14)),
        _memory(id: 'r2', lastMentionedAt: DateTime(2026, 7, 13)),
        _memory(id: 'r3', lastMentionedAt: DateTime(2026, 7, 12)),
        _memory(id: 'r4', lastMentionedAt: DateTime(2026, 7, 11)),
        _memory(id: 'r5', lastMentionedAt: DateTime(2026, 7, 10)),
      ]);

      expect(result.recent.map((memory) => memory.id), ['r1', 'r2', 'r3']);
    });

    test('ordena recentes da mais recente para a menos recente', () {
      final result = ClientMemoryHighlightsService.resolve([
        _memory(id: 'old', lastMentionedAt: DateTime(2026, 7, 1)),
        _memory(id: 'new', lastMentionedAt: DateTime(2026, 7, 15)),
        _memory(id: 'mid', lastMentionedAt: DateTime(2026, 7, 8)),
      ]);

      expect(result.recent.map((memory) => memory.id), ['new', 'mid', 'old']);
    });

    test('ignora memórias inativas', () {
      final result = ClientMemoryHighlightsService.resolve([
        _memory(id: 'inactive', isActive: false, isPinned: true),
        _memory(id: 'active', isPinned: true),
      ]);

      expect(result.pinned.map((memory) => memory.id), ['active']);
    });
  });
}

ClientMemory _memory({
  required String id,
  bool isPinned = false,
  bool isArchived = false,
  bool isActive = true,
  DateTime? lastMentionedAt,
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
    createdAt: DateTime(2026, 7, 1),
    updatedAt: DateTime(2026, 7, 1),
  );
}
