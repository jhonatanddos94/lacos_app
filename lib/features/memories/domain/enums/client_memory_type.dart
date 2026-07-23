enum ClientMemoryType {
  personal,
  preference,
  family,
  work,
  event,
  healthAttention,
  other;

  String get parseValue => switch (this) {
    ClientMemoryType.healthAttention => 'health_attention',
    _ => name,
  };

  static ClientMemoryType fromParse(String? value) {
    if (value == null || value.isEmpty) {
      return ClientMemoryType.other;
    }

    return switch (value) {
      'personal' => ClientMemoryType.personal,
      'preference' => ClientMemoryType.preference,
      'family' => ClientMemoryType.family,
      'work' => ClientMemoryType.work,
      'event' => ClientMemoryType.event,
      'health_attention' => ClientMemoryType.healthAttention,
      'other' => ClientMemoryType.other,
      'general' => ClientMemoryType.other,
      'conversation' => ClientMemoryType.personal,
      _ => ClientMemoryType.other,
    };
  }
}
