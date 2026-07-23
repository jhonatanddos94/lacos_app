enum ClientMemoryPriority {
  normal(0),
  high(1),
  critical(2);

  const ClientMemoryPriority(this.weight);

  final int weight;

  static ClientMemoryPriority fromParse(dynamic value) {
    final intValue = switch (value) {
      final int v => v,
      final String v => int.tryParse(v) ?? 0,
      _ => 0,
    };

    return switch (intValue) {
      >= 2 => ClientMemoryPriority.critical,
      1 => ClientMemoryPriority.high,
      _ => ClientMemoryPriority.normal,
    };
  }

  int toParse() => weight;
}
