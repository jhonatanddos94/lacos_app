abstract final class AppEnvironment {
  // TODO: migrar configurações sensíveis para --dart-define ou flavors.
  static const parseApplicationId = 'gg8QDOwG2FI0lRFQ79cFDYxh61mRx2ECqGZSqhWb';

  static const parseClientKey = 'BsYEXvMqMXO3ltsjAVZSSJAazPM33alWiOVVfz4i';

  static const parseServerUrl = 'https://parseapi.back4app.com';

  /// Versão reportada ao Cloud Code (`exchangeSession`). Override via dart-define.
  static const appVersion = String.fromEnvironment(
    'APP_VERSION',
    defaultValue: '1.0.0',
  );
}
