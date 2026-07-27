import 'dart:convert';

import 'package:lacos_app/core/session/domain/exceptions/auth_session_exception.dart';

/// Mapeia códigos estáveis do Cloud Code para mensagens de UI.
class ExchangeSessionErrorMapper {
  const ExchangeSessionErrorMapper();

  static const validation = 'VALIDATION';
  static const unauthorized = 'UNAUTHORIZED';
  static const emailUnverified = 'EMAIL_UNVERIFIED';
  static const configurationError = 'CONFIGURATION_ERROR';
  static const conflict = 'CONFLICT';
  static const temporary = 'TEMPORARY';
  static const internal = 'INTERNAL';
  static const sessionConflict = 'SESSION_CONFLICT';
  static const becomeFailed = 'BECOME_FAILED';

  AuthSessionException fromCloudCode({
    required String code,
    String? remoteMessage,
  }) {
    final normalized = code.trim().toUpperCase();
    return AuthSessionException(
      code: normalized.isEmpty ? internal : normalized,
      message: _messageFor(normalized),
    );
  }

  /// Extrai `{code, message}` do `ParseError.message` (JSON do Cloud Code).
  AuthSessionException fromParseErrorMessage(String? rawMessage) {
    final parsed = _tryParseCloudBody(rawMessage);
    if (parsed != null) {
      final code = parsed['code'];
      if (code is String && code.isNotEmpty) {
        return fromCloudCode(code: code, remoteMessage: parsed['message']?.toString());
      }
    }

    return const AuthSessionException(
      code: internal,
      message: 'Não foi possível preparar sua sessão. Tente novamente.',
    );
  }

  AuthSessionException sessionConflictError() {
    return const AuthSessionException(
      code: sessionConflict,
      message: 'Não foi possível preparar sua sessão. Tente novamente.',
    );
  }

  AuthSessionException becomeFailedError() {
    return const AuthSessionException(
      code: becomeFailed,
      message: 'Não foi possível preparar sua sessão. Tente novamente.',
    );
  }

  String _messageFor(String code) {
    return switch (code) {
      validation => 'Não foi possível preparar sua sessão. Tente novamente.',
      unauthorized => 'Sua sessão expirou. Entre novamente.',
      emailUnverified =>
        'Confirme seu e-mail para continuar. Verifique sua caixa de entrada.',
      configurationError =>
        'Não foi possível preparar sua sessão. Tente novamente mais tarde.',
      conflict =>
        'Não foi possível vincular sua conta. Entre em contato com o suporte.',
      temporary => 'Verifique sua conexão com a internet.',
      internal => 'Não foi possível preparar sua sessão. Tente novamente.',
      _ => 'Não foi possível preparar sua sessão. Tente novamente.',
    };
  }

  Map<String, Object?>? _tryParseCloudBody(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    final trimmed = raw.trim();
    if (!trimmed.startsWith('{')) return null;
    try {
      final decoded = jsonDecode(trimmed);
      if (decoded is Map<String, dynamic>) {
        return decoded.cast<String, Object?>();
      }
      if (decoded is Map) {
        return decoded.map((key, value) => MapEntry(key.toString(), value));
      }
    } on Object {
      return null;
    }
    return null;
  }
}
