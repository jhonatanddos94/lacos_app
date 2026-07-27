import 'package:flutter/foundation.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';

import 'package:lacos_app/core/config/app_environment.dart';
import 'package:lacos_app/core/session/domain/exceptions/auth_session_exception.dart';
import 'package:lacos_app/core/session/domain/models/exchange_session_result.dart';
import 'package:lacos_app/core/session/infrastructure/mappers/exchange_session_error_mapper.dart';

/// Cliente da Cloud Function `exchangeSession`.
///
/// Responsabilidade única: chamar a function e validar/mapear a resposta.
/// Não estabelece sessão Parse.
class ExchangeSessionClient {
  ExchangeSessionClient({
    ExchangeSessionErrorMapper? errorMapper,
    Future<ParseResponse> Function(Map<String, dynamic> parameters)? executor,
    String? appVersion,
    String? platform,
  }) : _errorMapper = errorMapper ?? const ExchangeSessionErrorMapper(),
       _executor = executor ?? _defaultExecutor,
       _appVersion = appVersion ?? AppEnvironment.appVersion,
       _platform = platform ?? defaultTargetPlatform.name;

  final ExchangeSessionErrorMapper _errorMapper;
  final Future<ParseResponse> Function(Map<String, dynamic> parameters)
  _executor;
  final String _appVersion;
  final String _platform;

  Future<ExchangeSessionResult> exchange({
    required String idToken,
    required String expectedFirebaseUid,
    required String requestId,
  }) async {
    final response = await _executor({
      'idToken': idToken,
      'requestId': requestId,
      'appVersion': _appVersion,
      'platform': _platform,
    });

    if (!response.success) {
      throw _errorMapper.fromParseErrorMessage(response.error?.message);
    }

    try {
      return ExchangeSessionResult.fromDynamic(
        response.result,
        expectedFirebaseUid: expectedFirebaseUid,
      );
    } on FormatException {
      throw const AuthSessionException(
        code: ExchangeSessionErrorMapper.internal,
        message: 'Não foi possível preparar sua sessão. Tente novamente.',
      );
    }
  }

  static Future<ParseResponse> _defaultExecutor(
    Map<String, dynamic> parameters,
  ) {
    return ParseCloudFunction('exchangeSession').execute(parameters: parameters);
  }
}
