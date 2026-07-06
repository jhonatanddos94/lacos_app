class ServiceDurationOption {
  const ServiceDurationOption({
    required this.label,
    required this.minutes,
  });

  final String label;
  final int minutes;
}

abstract final class ServiceDurationOptions {
  static const List<ServiceDurationOption> values = [
    ServiceDurationOption(label: '15 min', minutes: 15),
    ServiceDurationOption(label: '30 min', minutes: 30),
    ServiceDurationOption(label: '45 min', minutes: 45),
    ServiceDurationOption(label: '1 hora', minutes: 60),
    ServiceDurationOption(label: '1h30', minutes: 90),
    ServiceDurationOption(label: '2h', minutes: 120),
    ServiceDurationOption(label: '2h30', minutes: 150),
    ServiceDurationOption(label: '3h', minutes: 180),
  ];
}
