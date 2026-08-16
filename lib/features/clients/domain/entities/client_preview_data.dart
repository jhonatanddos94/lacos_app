import 'package:lacos_app/features/clients/domain/enums/client_list_filter.dart';

class ClientShortcutPreview {
  const ClientShortcutPreview({
    required this.label,
    required this.type,
    this.isSelected = false,
    this.isEnabled = true,
  });

  final String label;
  final ClientListFilter type;
  final bool isSelected;
  final bool isEnabled;
}
