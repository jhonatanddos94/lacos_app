import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';

import 'package:lacos_app/core/config/app_strings.dart';

class ParseClientMemoryErrorMapper {
  const ParseClientMemoryErrorMapper();

  String toMessage(ParseError? error) {
    if (error == null) {
      return AppStrings.memorySaveError;
    }

    return switch (error.code) {
      ParseError.connectionFailed => 'Verifique sua conexão com a internet.',
      ParseError.invalidSessionToken => 'Sua sessão expirou. Entre novamente.',
      ParseError.objectNotFound ||
      ParseError.invalidQuery ||
      ParseError.invalidClassName =>
        'Não foi possível carregar as memórias. Tente novamente.',
      _ => AppStrings.memorySaveError,
    };
  }
}
