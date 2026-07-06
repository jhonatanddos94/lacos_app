import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';

import 'package:lacos_app/core/config/app_strings.dart';

abstract final class ParseTemporaryErrorMapper {
  static bool isTemporaryParseError(ParseError? error) {
    if (error == null) {
      return false;
    }

    if (error.code == ParseError.otherCause ||
        error.code == ParseError.connectionFailed ||
        error.code == ParseError.internalServerError ||
        error.code == ParseError.timeout) {
      return true;
    }

    return _isTemporaryMessage(error.message);
  }

  static bool isTemporaryThrowable(Object error) {
    if (error is ParseError) {
      return isTemporaryParseError(error);
    }

    if (error is FormatException) {
      return _isTemporaryMessage(error.message);
    }

    return _isTemporaryMessage(error.toString());
  }

  static String messageForThrowable(
    Object error, {
    required String fallback,
  }) {
    if (isTemporaryThrowable(error)) {
      return AppStrings.temporaryLoadError;
    }

    return switch (error) {
      FormatException(message: final message) when message.isNotEmpty => message,
      StateError(message: final message) => message,
      _ => fallback,
    };
  }

  static bool _isTemporaryMessage(String? message) {
    final normalized = message?.toLowerCase() ?? '';

    return normalized.contains('502') ||
        normalized.contains('bad gateway') ||
        normalized.contains('invalid response format') ||
        normalized.contains('othercause');
  }
}
