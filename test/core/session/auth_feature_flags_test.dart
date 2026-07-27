import 'package:flutter_test/flutter_test.dart';
import 'package:lacos_app/core/config/auth_feature_flags.dart';

void main() {
  group('AuthFeatureFlags', () {
    test('useExchangeSession defaults to false', () {
      expect(AuthFeatureFlags.useExchangeSession, isFalse);
    });

    test('authStrategyLabel is legacy when flag is off', () {
      expect(AuthFeatureFlags.authStrategyLabel, 'legacy');
    });
  });
}
