import 'package:lacos_app/features/clients/application/models/client_service_history_item.dart';
import 'package:lacos_app/features/clients/application/models/client_service_history_kind.dart';

/// Filtra a lista já carregada do histórico (sem nova query).
class ClientServiceHistoryFilterService {
  const ClientServiceHistoryFilterService._();

  static List<ClientServiceHistoryItem> apply({
    required List<ClientServiceHistoryItem> items,
    required ClientServiceHistoryFilter filter,
  }) {
    return switch (filter) {
      ClientServiceHistoryFilter.all => List<ClientServiceHistoryItem>.unmodifiable(
        items,
      ),
      ClientServiceHistoryFilter.completed => List<ClientServiceHistoryItem>.unmodifiable(
        items.where((item) => item.kind == ClientServiceHistoryKind.completed),
      ),
      ClientServiceHistoryFilter.canceled => List<ClientServiceHistoryItem>.unmodifiable(
        items.where((item) => item.kind == ClientServiceHistoryKind.canceled),
      ),
    };
  }
}
