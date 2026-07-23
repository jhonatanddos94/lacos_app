enum ClientMemoryType {
  general,
  preference,
  personal,
  conversation;

  static ClientMemoryType fromParse(String? value) {
    return switch (value) {
      'preference' => ClientMemoryType.preference,
      'personal' => ClientMemoryType.personal,
      'conversation' => ClientMemoryType.conversation,
      'general' || null || '' => ClientMemoryType.general,
      _ => ClientMemoryType.general,
    };
  }

  String toParse() => name;
}
