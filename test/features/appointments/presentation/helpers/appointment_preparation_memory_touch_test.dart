import 'package:flutter_test/flutter_test.dart';
import 'package:lacos_app/features/appointments/presentation/helpers/appointment_preparation_memory_touch.dart';

import '../../helpers/gated_client_memory_repository.dart';

void main() {
  test('não chama repositório quando a lista está vazia', () async {
    final repository = GatedClientMemoryRepository();

    await touchDisplayedPreparationMemories(
      repository: repository,
      memoryIds: const [],
    );

    expect(repository.touchCalls, 0);
  });

  test('engole exception do repositório', () async {
    final repository = GatedClientMemoryRepository(
      touchError: Exception('fail'),
    );

    await touchDisplayedPreparationMemories(
      repository: repository,
      memoryIds: const ['m1'],
    );

    expect(repository.touchCalls, 1);
  });

  test('encaminha ids para touchMentioned', () async {
    final repository = GatedClientMemoryRepository();

    await touchDisplayedPreparationMemories(
      repository: repository,
      memoryIds: const [' m1 ', '', 'm2'],
    );

    expect(repository.touchCalls, 1);
    expect(repository.lastTouchedIds, ['m1', 'm2']);
  });
}
