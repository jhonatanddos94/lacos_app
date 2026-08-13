import 'package:lacos_app/features/clients/application/models/client_service_history_item.dart';

class ClientServiceHistoryMonthGroup {
  const ClientServiceHistoryMonthGroup({
    required this.year,
    required this.month,
    required this.label,
    required this.items,
  });

  final int year;
  final int month;
  final String label;
  final List<ClientServiceHistoryItem> items;
}
