enum ClientMemoryPriority {
  low,
  normal,
  high;

  String get parseValue => name;

  /// Peso interno para ordenação; não é persistido no Parse.
  int get sortWeight => switch (this) {
    ClientMemoryPriority.low => 0,
    ClientMemoryPriority.normal => 1,
    ClientMemoryPriority.high => 2,
  };

  static ClientMemoryPriority fromParse(dynamic value) {
    if (value == null) {
      return ClientMemoryPriority.normal;
    }

    if (value is String) {
      return switch (value) {
        'low' => ClientMemoryPriority.low,
        'normal' => ClientMemoryPriority.normal,
        'high' => ClientMemoryPriority.high,
        _ => _fromLegacyNumeric(int.tryParse(value)),
      };
    }

    if (value is int) {
      return _fromLegacyNumeric(value);
    }

    return ClientMemoryPriority.normal;
  }

  static ClientMemoryPriority _fromLegacyNumeric(int? value) {
    return switch (value) {
      0 => ClientMemoryPriority.normal,
      1 || 2 => ClientMemoryPriority.high,
      _ => ClientMemoryPriority.normal,
    };
  }
}
