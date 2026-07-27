import 'package:flutter_test/flutter_test.dart';

import 'package:lacos_app/core/session/infrastructure/mappers/exchange_session_error_mapper.dart';

void main() {
  const mapper = ExchangeSessionErrorMapper();

  test('maps known cloud codes to stable AuthSessionException', () {
    for (final code in [
      'VALIDATION',
      'UNAUTHORIZED',
      'EMAIL_UNVERIFIED',
      'CONFIGURATION_ERROR',
      'CONFLICT',
      'TEMPORARY',
      'INTERNAL',
    ]) {
      final error = mapper.fromCloudCode(code: code);
      expect(error.code, code);
      expect(error.message, isNotEmpty);
      expect(error.message.toLowerCase(), isNot(contains('token')));
      expect(error.message.toLowerCase(), isNot(contains('master')));
    }
  });

  test('parses JSON Parse error message', () {
    final error = mapper.fromParseErrorMessage(
      '{"code":"CONFLICT","message":"dup"}',
    );
    expect(error.code, 'CONFLICT');
    expect(error.message, contains('vincular'));
  });
}
