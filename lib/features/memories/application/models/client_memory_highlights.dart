import 'package:lacos_app/features/memories/domain/entities/client_memory.dart';

class ClientMemoryHighlights {
  const ClientMemoryHighlights({
    this.pinned = const [],
    this.recent = const [],
  });

  static const empty = ClientMemoryHighlights();

  final List<ClientMemory> pinned;
  final List<ClientMemory> recent;

  bool get isEmpty => pinned.isEmpty && recent.isEmpty;

  bool get hasContent => !isEmpty;

  List<ClientMemory> get previewItems {
    if (pinned.isNotEmpty) {
      return pinned.take(2).toList(growable: false);
    }

    return recent.take(2).toList(growable: false);
  }
}
