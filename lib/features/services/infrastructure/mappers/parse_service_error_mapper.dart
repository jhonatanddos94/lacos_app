import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';

import 'package:lacos_app/core/config/app_strings.dart';
import 'package:lacos_app/core/network/parse_temporary_error_mapper.dart';

class ParseServiceErrorMapper {
  const ParseServiceErrorMapper();

  String toMessage(ParseError? error, {bool forSave = false}) {
    if (ParseTemporaryErrorMapper.isTemporaryParseError(error)) {
      return AppStrings.temporaryLoadError;
    }

    final fallback = forSave
        ? 'Não foi possível salvar o serviço. Tente novamente.'
        : 'Não foi possível carregar os serviços. Tente novamente.';

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
