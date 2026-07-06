import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';

import 'package:lacos_app/core/config/app_strings.dart';
import 'package:lacos_app/core/network/parse_temporary_error_mapper.dart';

class ParseAppointmentErrorMapper {
  const ParseAppointmentErrorMapper();

  String toMessage(ParseError? error) {
    if (ParseTemporaryErrorMapper.isTemporaryParseError(error)) {
      return AppStrings.temporaryLoadError;
    }

    if (error == null) {
      return AppStrings.temporaryLoadError;
    }

    return switch (error.code) {
      ParseError.connectionFailed => AppStrings.temporaryLoadError,
      ParseError.invalidSessionToken => 'Sua sessão expirou. Entre novamente.',
      ParseError.objectNotFound ||
      ParseError.invalidQuery ||
      ParseError.invalidClassName =>
        'Não foi possível carregar os agendamentos. Tente novamente.',
      _ => 'Não foi possível carregar os agendamentos. Tente novamente.',
    };
  }
}
