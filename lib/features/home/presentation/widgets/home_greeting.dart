class HomeGreeting {
  const HomeGreeting._();

  static String resolve(DateTime dateTime, {required String professionalName}) {
    final hour = dateTime.hour;
    final greeting = switch (hour) {
      >= 5 && < 12 => 'Bom dia',
      >= 12 && < 18 => 'Boa tarde',
      _ => 'Boa noite',
    };
    final emoji = switch (hour) {
      >= 5 && < 12 => '☀️',
      >= 12 && < 18 => '🌿',
      _ => '🌙',
    };

    return '$greeting, $professionalName $emoji';
  }
}
