import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';

class ParseProfessionalErrorMapper {
  const ParseProfessionalErrorMapper();

  String toMessage(ParseError? error) {
    if (error == null) {
      return 'Não foi possível salvar seu perfil profissional. Tente novamente.';
    }

    return switch (error.code) {
      ParseError.connectionFailed => 'Verifique sua conexão com a internet.',
      ParseError.invalidSessionToken => 'Sua sessão expirou. Entre novamente.',
      ParseError.objectNotFound ||
      ParseError.invalidQuery ||
      ParseError.invalidClassName =>
        'Não foi possível salvar seu perfil profissional. Tente novamente.',
      _ => 'Não foi possível salvar seu perfil profissional. Tente novamente.',
    };
  }
}
