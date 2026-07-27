import 'package:flutter_test/flutter_test.dart';
import 'package:lacos_app/features/memories/presentation/controllers/client_memory_preview_cycle_controller.dart';

void main() {
  group('ClientMemoryPreviewCycleController', () {
    test('lista vazia não rotaciona', () {
      final cycle = ClientMemoryPreviewCycleController(itemIds: const []);

      expect(cycle.isEmpty, isTrue);
      expect(cycle.shouldAutoRotate, isFalse);
      expect(cycle.advance(), isFalse);
      expect(cycle.currentIndex, 0);
    });

    test('uma memória não rotaciona nem mostra múltiplos', () {
      final cycle = ClientMemoryPreviewCycleController(itemIds: const ['a']);

      expect(cycle.hasMultipleItems, isFalse);
      expect(cycle.shouldAutoRotate, isFalse);
      expect(cycle.advance(), isFalse);
      expect(cycle.currentIndex, 0);
      expect(cycle.currentItemId, 'a');
    });

    test('múltiplas memórias avançam ciclicamente', () {
      final cycle = ClientMemoryPreviewCycleController(
        itemIds: const ['a', 'b', 'c'],
      );

      expect(cycle.shouldAutoRotate, isTrue);
      expect(cycle.currentItemId, 'a');

      expect(cycle.advance(), isTrue);
      expect(cycle.currentIndex, 1);
      expect(cycle.currentItemId, 'b');

      expect(cycle.advance(), isTrue);
      expect(cycle.currentIndex, 2);

      expect(cycle.advance(), isTrue);
      expect(cycle.currentIndex, 0);
    });

    test('navegação manual anterior é cíclica', () {
      final cycle = ClientMemoryPreviewCycleController(
        itemIds: const ['a', 'b', 'c'],
      );

      expect(cycle.goToPrevious(), isTrue);
      expect(cycle.currentIndex, 2);
      expect(cycle.goToPrevious(), isTrue);
      expect(cycle.currentIndex, 1);
    });

    test('goTo respeita limites', () {
      final cycle = ClientMemoryPreviewCycleController(
        itemIds: const ['a', 'b'],
      );

      expect(cycle.goTo(1), isTrue);
      expect(cycle.currentIndex, 1);
      expect(cycle.goTo(1), isFalse);
      expect(cycle.goTo(5), isFalse);
      expect(cycle.goTo(-1), isFalse);
    });

    test('updateItems preserva índice quando item atual permanece', () {
      final cycle = ClientMemoryPreviewCycleController(
        itemIds: const ['a', 'b', 'c'],
      );
      cycle.advance();

      cycle.updateItems(const ['a', 'b', 'c', 'd']);

      expect(cycle.currentIndex, 1);
      expect(cycle.currentItemId, 'b');
      expect(cycle.itemCount, 4);
    });

    test('updateItems normaliza quando item atual é removido', () {
      final cycle = ClientMemoryPreviewCycleController(
        itemIds: const ['a', 'b', 'c'],
      );
      cycle.advance();
      cycle.advance();
      expect(cycle.currentItemId, 'c');

      cycle.updateItems(const ['a', 'b']);

      expect(cycle.currentItemId, isNot('c'));
      expect(cycle.currentIndex, lessThan(2));
      expect(cycle.itemCount, 2);
    });

    test('updateItems para lista vazia zera índice', () {
      final cycle = ClientMemoryPreviewCycleController(
        itemIds: const ['a', 'b'],
      );
      cycle.advance();

      cycle.updateItems(const []);

      expect(cycle.isEmpty, isTrue);
      expect(cycle.currentIndex, 0);
      expect(cycle.shouldAutoRotate, isFalse);
    });

    test('updateItems com um item desliga auto-rotação', () {
      final cycle = ClientMemoryPreviewCycleController(
        itemIds: const ['a', 'b'],
      );
      cycle.advance();

      cycle.updateItems(const ['b']);

      expect(cycle.currentItemId, 'b');
      expect(cycle.shouldAutoRotate, isFalse);
    });
  });
}
