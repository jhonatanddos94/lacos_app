import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';

import 'package:lacos_app/core/config/app_strings.dart';
import 'package:lacos_app/core/network/parse_temporary_error_mapper.dart';

class ParseServiceRecordServiceErrorMapper {
  const ParseServiceRecordServiceErrorMapper();

  String toMessage(ParseError? error, {bool forSave = false}) {
    if (ParseTemporaryErrorMapper.isTemporaryParseError(error)) {
      return forSave
          ? AppStrings.temporarySaveError
          : AppStrings.temporaryLoadError;
    }

    final fallback = forSave
        ? AppStrings.serviceRecordServiceSaveError
        : AppStrings.serviceRecordServiceLoadError;

    if (error == null) {
      return fallback;
    }

    return switch (error.code) {
      ParseError.connectionFailed ||
      ParseError.internalServerError ||
      ParseError.timeout ||
      ParseError.otherCause =>
        forSave ? AppStrings.temporarySaveError : AppStrings.temporaryLoadError,
      ParseError.invalidSessionToken => 'Sua sessão expirou. Entre novamente.',
      ParseError.objectNotFound ||
      ParseError.invalidQuery ||
      ParseError.invalidClassName => fallback,
      _ => _messageFromErrorText(
        error.message,
        forSave: forSave,
        fallback: fallback,
      ),
    };
  }

  String _messageFromErrorText(
    String? message, {
    required bool forSave,
    required String fallback,
  }) {
    if (ParseTemporaryErrorMapper.isTemporaryThrowable(
      FormatException(message ?? ''),
    )) {
      return forSave
          ? AppStrings.temporarySaveError
          : AppStrings.temporaryLoadError;
    }

    return fallback;
  }
}
