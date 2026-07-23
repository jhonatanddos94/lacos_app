import 'package:lacos_app/features/memories/domain/entities/client_memory.dart';

enum ClientMemoryProfilePreviewKind { pinned, recentlyMentioned, newest }

class ClientMemoryProfilePreview {
  const ClientMemoryProfilePreview({
    this.items = const [],
    this.kind = ClientMemoryProfilePreviewKind.newest,
  });

  static const empty = ClientMemoryProfilePreview();

  final List<ClientMemory> items;
  final ClientMemoryProfilePreviewKind kind;

  bool get isEmpty => items.isEmpty;

  bool get hasContent => !isEmpty;
}
