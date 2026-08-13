import 'package:lacos_app/features/memories/domain/repositories/client_memory_repository.dart';

/// Atualiza recência das memórias exibidas. Best-effort: erros são engolidos.
Future<void> touchDisplayedPreparationMemories({
  required ClientMemoryRepository repository,
  required List<String> memoryIds,
}) async {
  final ids = memoryIds
      .map((id) => id.trim())
      .where((id) => id.isNotEmpty)
      .toList(growable: false);

  if (ids.isEmpty) {
    return;
  }

  try {
    await repository.touchMentioned(memoryIds: ids);
  } on Object {
    return;
  }
}
