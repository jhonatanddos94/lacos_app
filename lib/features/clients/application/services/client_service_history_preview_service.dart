import 'package:lacos_app/features/clients/application/models/client_service_history_item.dart';
import 'package:lacos_app/features/clients/application/models/client_service_history_kind.dart';
import 'package:lacos_app/features/clients/application/models/client_service_history_preview.dart';

/// Seleciona até [ClientServiceHistoryPreview.maxItems] concluídos recentes.
class ClientServiceHistoryPreviewService {
  const ClientServiceHistoryPreviewService._();

  static ClientServiceHistoryPreview resolve(
    List<ClientServiceHistoryItem> items,
  ) {
    final completed =
        items
            .where((item) => item.kind == ClientServiceHistoryKind.completed)
            .toList(growable: false)
          ..sort((a, b) => b.occurredAt.compareTo(a.occurredAt));

    if (completed.isEmpty) {
      return ClientServiceHistoryPreview.empty;
    }

    return ClientServiceHistoryPreview(
      items: completed
          .take(ClientServiceHistoryPreview.maxItems)
          .toList(growable: false),
    );
  }
}
