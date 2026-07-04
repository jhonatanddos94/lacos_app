class ClientsDashboardData {
  const ClientsDashboardData({required this.shortcuts, required this.clients});

  final List<ClientShortcutPreview> shortcuts;
  final List<ClientPreview> clients;
}

class ClientShortcutPreview {
  const ClientShortcutPreview({
    required this.title,
    required this.subtitle,
    required this.type,
  });

  final String title;
  final String subtitle;
  final ClientShortcutType type;
}

enum ClientShortcutType { today, birthdays, reconnect }

class ClientPreview {
  const ClientPreview({
    required this.name,
    required this.phone,
    required this.sinceLabel,
    required this.memoryLabel,
    required this.lastAppointmentDate,
    required this.lastAppointmentService,
    required this.isFavorite,
    required this.isActive,
  });

  final String name;
  final String phone;
  final String sinceLabel;
  final String memoryLabel;
  final String lastAppointmentDate;
  final String lastAppointmentService;
  final bool isFavorite;
  final bool isActive;
}
