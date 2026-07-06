import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';

import 'package:lacos_app/core/config/app_strings.dart';
import 'package:lacos_app/core/network/parse_temporary_error_mapper.dart';

class ParseClientErrorMapper {
  const ParseClientErrorMapper();

  String toMessage(ParseError? error) {
    if (ParseTemporaryErrorMapper.isTemporaryParseError(error)) {
      return AppStrings.temporaryLoadError;
    }

    if (error == null) {
      return 'Não foi possível salvar a cliente. Tente novamente.';
    }

    return switch (error.code) {
      ParseError.connectionFailed => AppStrings.temporaryLoadError,
      ParseError.invalidSessionToken => 'Sua sessão expirou. Entre novamente.',
      ParseError.objectNotFound ||
      ParseError.invalidQuery ||
      ParseError.invalidClassName =>
        'Não foi possível carregar as clientes. Tente novamente.',
      _ => 'Não foi possível salvar a cliente. Tente novamente.',
    };
  }
}
