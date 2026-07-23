import 'package:flutter_test/flutter_test.dart';
import 'package:lacos_app/features/appointments/presentation/controllers/appointment_memory_usage_controller.dart';

void main() {
  group('AppointmentMemoryUsageController', () {
    late AppointmentMemoryUsageController controller;

    setUp(() {
      controller = AppointmentMemoryUsageController();
    });

    test('marca memória utilizada', () {
      controller.markUsed('memory-1');

      expect(controller.state.usedMemoryIds, {'memory-1'});
    });

    test('desmarca memória utilizada', () {
      controller
        ..markUsed('memory-1')
        ..unmarkUsed('memory-1');

      expect(controller.state.usedMemoryIds, isEmpty);
    });

    test('toggle alterna marcação', () {
      controller.toggleUsed('memory-1');
      expect(controller.state.usedMemoryIds, {'memory-1'});

      controller.toggleUsed('memory-1');
      expect(controller.state.usedMemoryIds, isEmpty);
    });

    test('clear remove todas as marcações', () {
      controller
        ..markUsed('memory-1')
        ..markUsed('memory-2')
        ..clear();

      expect(controller.state.usedMemoryIds, isEmpty);
    });

    test('ignora ids vazios e duplicatas', () {
      controller
        ..markUsed('')
        ..markUsed('memory-1')
        ..markUsed('memory-1');

      expect(controller.state.usedMemoryIds, {'memory-1'});
    });

    test('unmarkUsed ignora id inexistente', () {
      controller.unmarkUsed('missing');

      expect(controller.state.usedMemoryIds, isEmpty);
    });
  });
}
