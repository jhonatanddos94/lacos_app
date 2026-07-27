/// Resposta tipada da Cloud Function `exchangeSession`.
class ExchangeSessionResult {
  const ExchangeSessionResult({
    required this.sessionToken,
    required this.parseUserId,
    required this.firebaseUid,
    required this.email,
    required this.securityMode,
    required this.isNewUser,
    this.expiresAt,
  });

  final String sessionToken;
  final String parseUserId;
  final String firebaseUid;
  final String email;
  final String securityMode;
  final bool isNewUser;
  final DateTime? expiresAt;

  /// Converte e valida o payload dinâmico retornado pelo Parse SDK.
  factory ExchangeSessionResult.fromDynamic(
    Object? raw, {
    required String expectedFirebaseUid,
  }) {
    if (raw is! Map) {
      throw const FormatException(
        'Não foi possível preparar sua sessão. Tente novamente.',
      );
    }

    final map = Map<Object?, Object?>.from(raw);

    final sessionToken = _requiredNonEmptyString(map, 'sessionToken');
    final parseUserId = _requiredNonEmptyString(map, 'parseUserId');
    final firebaseUid = _requiredNonEmptyString(map, 'firebaseUid');
    final email = _optionalString(map, 'email') ?? '';
    final securityMode = _optionalString(map, 'securityMode') ?? 'permissive';
    final isNewUser = _optionalBool(map, 'isNewUser') ?? false;
    final expiresAt = _optionalDateTime(map, 'expiresAt');

    if (firebaseUid != expectedFirebaseUid) {
      throw const FormatException(
        'Não foi possível preparar sua sessão. Tente novamente.',
      );
    }

    return ExchangeSessionResult(
      sessionToken: sessionToken,
      parseUserId: parseUserId,
      firebaseUid: firebaseUid,
      email: email,
      securityMode: securityMode,
      isNewUser: isNewUser,
      expiresAt: expiresAt,
    );
  }
}

String _requiredNonEmptyString(Map<Object?, Object?> map, String key) {
  final value = map[key];
  if (value is! String || value.trim().isEmpty) {
    throw const FormatException(
      'Não foi possível preparar sua sessão. Tente novamente.',
    );
  }
  return value.trim();
}

String? _optionalString(Map<Object?, Object?> map, String key) {
  final value = map[key];
  if (value == null) return null;
  if (value is! String) {
    throw const FormatException(
      'Não foi possível preparar sua sessão. Tente novamente.',
    );
  }
  return value;
}

bool? _optionalBool(Map<Object?, Object?> map, String key) {
  final value = map[key];
  if (value == null) return null;
  if (value is bool) return value;
  throw const FormatException(
    'Não foi possível preparar sua sessão. Tente novamente.',
  );
}

DateTime? _optionalDateTime(Map<Object?, Object?> map, String key) {
  final value = map[key];
  if (value == null) return null;
  if (value is DateTime) return value;
  if (value is String && value.isNotEmpty) {
    return DateTime.tryParse(value);
  }
  if (value is Map && value['iso'] is String) {
    return DateTime.tryParse(value['iso'] as String);
  }
  return null;
}
