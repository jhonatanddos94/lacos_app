import 'package:lacos_app/features/clients/application/models/client_service_history_item.dart';

class ClientServiceHistoryPreview {
  const ClientServiceHistoryPreview({this.items = const []});

  static const empty = ClientServiceHistoryPreview();
  static const maxItems = 3;

  final List<ClientServiceHistoryItem> items;

  bool get isEmpty => items.isEmpty;
  bool get hasContent => items.isNotEmpty;
}
