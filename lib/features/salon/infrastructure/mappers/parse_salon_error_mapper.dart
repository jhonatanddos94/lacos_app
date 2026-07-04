import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';

/// Converte erros do Parse em mensagens amigáveis para o Laços.
class ParseSalonErrorMapper {
  const ParseSalonErrorMapper();

  String toMessage(ParseError? error) {
    if (error == null) {
      return 'Não foi possível criar seu salão. Tente novamente.';
    }

    return switch (error.code) {
      ParseError.connectionFailed => 'Verifique sua conexão com a internet.',
      ParseError.invalidSessionToken => 'Sua sessão expirou. Entre novamente.',
      ParseError.objectNotFound ||
      ParseError.invalidQuery ||
      ParseError.invalidClassName =>
        'Não foi possível criar seu salão. Tente novamente.',
      _ => 'Não foi possível criar seu salão. Tente novamente.',
    };
  }
}
