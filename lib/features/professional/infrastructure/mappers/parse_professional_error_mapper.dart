import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';

import 'package:lacos_app/core/config/app_strings.dart';
import 'package:lacos_app/core/network/parse_temporary_error_mapper.dart';

class ParseProfessionalErrorMapper {
  const ParseProfessionalErrorMapper();

  String toMessage(ParseError? error, {bool forLoad = false}) {
    if (ParseTemporaryErrorMapper.isTemporaryParseError(error)) {
      return AppStrings.temporaryLoadError;
    }

    final fallback = forLoad
        ? AppStrings.professionalsLoadError
        : 'Não foi possível salvar seu perfil profissional. Tente novamente.';

    if (error == null) {
      return fallback;
    }

    return switch (error.code) {
      ParseError.connectionFailed => AppStrings.temporaryLoadError,
      ParseError.invalidSessionToken => 'Sua sessão expirou. Entre novamente.',
      ParseError.objectNotFound ||
      ParseError.invalidQuery ||
      ParseError.invalidClassName => fallback,
      _ => fallback,
    };
  }
}
