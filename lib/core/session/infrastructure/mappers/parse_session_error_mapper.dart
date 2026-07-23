import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';

/// Converte erros de sessão Parse em mensagens amigáveis.
class ParseSessionErrorMapper {
  const ParseSessionErrorMapper();

  String toMessage(ParseError? error) {
    if (error == null) {
      return 'Não foi possível preparar sua sessão. Tente novamente.';
    }

    return switch (error.code) {
      ParseError.connectionFailed => 'Verifique sua conexão com a internet.',
      ParseError.invalidSessionToken ||
      ParseError.sessionMissing => 'Sua sessão expirou. Entre novamente.',
      ParseError.notInitialized =>
        'Não foi possível preparar sua sessão. Tente novamente.',
      ParseError.objectNotFound ||
      ParseError.usernameTaken ||
      ParseError.emailTaken ||
      ParseError.invalidEmailAddress =>
        'Não foi possível preparar sua sessão. Tente novamente.',
      _ => 'Não foi possível preparar sua sessão. Tente novamente.',
    };
  }
}
