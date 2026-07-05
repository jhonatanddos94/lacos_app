class ClientShortcutPreview {
  const ClientShortcutPreview({
    required this.label,
    required this.type,
    this.isSelected = false,
    this.isEnabled = true,
  });

  final String label;
  final ClientShortcutType type;
  final bool isSelected;
  final bool isEnabled;
}

enum ClientShortcutType { all, favorites, recent, withoutReturn }
