import 'package:flutter_test/flutter_test.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';

import 'package:lacos_app/core/session/application/coordinators/auth_session_coordinator.dart';
import 'package:lacos_app/core/session/domain/exceptions/auth_session_exception.dart';
import 'package:lacos_app/core/session/domain/gateways/parse_user_session_gateway.dart';
import 'package:lacos_app/core/session/domain/models/auth_session_strategy_kind.dart';
import 'package:lacos_app/core/session/infrastructure/clients/exchange_session_client.dart';
import 'package:lacos_app/core/session/infrastructure/mappers/exchange_session_error_mapper.dart';
import 'package:lacos_app/core/session/infrastructure/strategies/firebase_exchange_session_strategy.dart';
import 'package:lacos_app/core/session/infrastructure/strategies/legacy_parse_session_strategy.dart';

import 'fakes/session_test_fakes.dart';

void main() {
  group('AuthSessionCoordinator', () {
    test('flag OFF uses legacy strategy', () async {
      final auth = FakeAuthRepository(user: verifiedUser());
      final gateway = FakeParseUserSessionGateway();
      final legacy = LegacyParseSessionStrategy(gateway: gateway);
      final exchange = FirebaseExchangeSessionStrategy(
        authRepository: auth,
        exchangeSessionClient: ExchangeSessionClient(
          executor: (_) async => ParseResponse()..success = false,
        ),
        parseGateway: gateway,
      );

      final coordinator = AuthSessionCoordinator(
        authRepository: auth,
        parseGateway: gateway,
        legacyStrategy: legacy,
        exchangeStrategy: exchange,
        useExchangeSession: false,
      );

      final result = await coordinator.syncAuthenticatedUser();

      expect(result.strategy, AuthSessionStrategyKind.legacy);
      expect(gateway.logins, isNotEmpty);
      expect(gateway.becomes, isEmpty);
    });

    test('flag ON uses exchange strategy', () async {
      final auth = FakeAuthRepository(user: verifiedUser());
      final gateway = FakeParseUserSessionGateway(
        becomeObjectId: 'parse-1',
        becomeUsername: 'uid-1',
      );
      final coordinator = AuthSessionCoordinator(
        authRepository: auth,
        parseGateway: gateway,
        legacyStrategy: LegacyParseSessionStrategy(gateway: gateway),
        exchangeStrategy: FirebaseExchangeSessionStrategy(
          authRepository: auth,
          exchangeSessionClient: ExchangeSessionClient(
            executor: (_) async => ParseResponse()
              ..success = true
              ..result = {
                'sessionToken': 'r:tok',
                'parseUserId': 'parse-1',
                'firebaseUid': 'uid-1',
                'email': 'a@test.com',
                'securityMode': 'permissive',
                'isNewUser': false,
              },
          ),
          parseGateway: gateway,
        ),
        useExchangeSession: true,
      );

      final result = await coordinator.syncAuthenticatedUser();

      expect(result.strategy, AuthSessionStrategyKind.exchange);
      expect(gateway.becomes, isNotEmpty);
      expect(gateway.logins, isEmpty);
    });

    test('exchange failure does not fall back to legacy', () async {
      final auth = FakeAuthRepository(user: verifiedUser());
      final gateway = FakeParseUserSessionGateway();
      final coordinator = AuthSessionCoordinator(
        authRepository: auth,
        parseGateway: gateway,
        legacyStrategy: LegacyParseSessionStrategy(gateway: gateway),
        exchangeStrategy: FirebaseExchangeSessionStrategy(
          authRepository: auth,
          exchangeSessionClient: ExchangeSessionClient(
            executor: (_) async => ParseResponse()
              ..success = false
              ..error = ParseError(
                code: 500,
                message: '{"code":"INTERNAL","message":"boom"}',
              ),
          ),
          parseGateway: gateway,
        ),
        useExchangeSession: true,
      );

      await expectLater(
        coordinator.syncAuthenticatedUser(),
        throwsA(
          isA<AuthSessionException>().having(
            (e) => e.code,
            'code',
            ExchangeSessionErrorMapper.internal,
          ),
        ),
      );
      expect(gateway.logins, isEmpty);
    });

    test('reuses valid existing Parse session', () async {
      final auth = FakeAuthRepository(user: verifiedUser());
      final gateway = FakeParseUserSessionGateway(
        current: const ParseUserSnapshot(
          objectId: 'parse-1',
          username: 'uid-1',
          sessionTokenPresent: true,
          firebaseUid: 'uid-1',
        ),
      );
      final coordinator = AuthSessionCoordinator(
        authRepository: auth,
        parseGateway: gateway,
        legacyStrategy: LegacyParseSessionStrategy(gateway: gateway),
        exchangeStrategy: FirebaseExchangeSessionStrategy(
          authRepository: auth,
          exchangeSessionClient: ExchangeSessionClient(
            executor: (_) async => fail('should not exchange'),
          ),
          parseGateway: gateway,
        ),
        useExchangeSession: true,
      );

      final result = await coordinator.syncAuthenticatedUser();

      expect(result.reusedExistingSession, isTrue);
      expect(result.parseUserId, 'parse-1');
      expect(gateway.becomes, isEmpty);
      expect(gateway.logins, isEmpty);
    });

    test('clears cross-user Parse session before sync', () async {
      final auth = FakeAuthRepository(user: verifiedUser(id: 'uid-2'));
      final gateway = FakeParseUserSessionGateway(
        current: const ParseUserSnapshot(
          objectId: 'parse-old',
          username: 'uid-1',
          sessionTokenPresent: true,
          firebaseUid: 'uid-1',
        ),
      );
      final coordinator = AuthSessionCoordinator(
        authRepository: auth,
        parseGateway: gateway,
        legacyStrategy: LegacyParseSessionStrategy(gateway: gateway),
        exchangeStrategy: FirebaseExchangeSessionStrategy(
          authRepository: auth,
          exchangeSessionClient: ExchangeSessionClient(
            executor: (_) async => ParseResponse()
              ..success = true
              ..result = {
                'sessionToken': 'r:tok',
                'parseUserId': 'parse-2',
                'firebaseUid': 'uid-2',
                'email': 'a@test.com',
                'securityMode': 'permissive',
                'isNewUser': false,
              },
          ),
          parseGateway: gateway,
        ),
        useExchangeSession: true,
      );
      gateway.becomeObjectId = 'parse-2';
      gateway.becomeUsername = 'uid-2';
      gateway.becomeFirebaseUid = 'uid-2';

      final result = await coordinator.syncAuthenticatedUser();

      expect(gateway.clearLocalCalls, greaterThanOrEqualTo(1));
      expect(result.parseUserId, 'parse-2');
    });

    test('fails when firebase user absent', () async {
      final auth = FakeAuthRepository(user: null);
      final gateway = FakeParseUserSessionGateway();
      final coordinator = AuthSessionCoordinator(
        authRepository: auth,
        parseGateway: gateway,
        legacyStrategy: LegacyParseSessionStrategy(gateway: gateway),
        exchangeStrategy: FirebaseExchangeSessionStrategy(
          authRepository: auth,
          exchangeSessionClient: ExchangeSessionClient(
            executor: (_) async => ParseResponse()..success = false,
          ),
          parseGateway: gateway,
        ),
        useExchangeSession: false,
      );

      expect(
        coordinator.syncAuthenticatedUser(),
        throwsA(isA<StateError>()),
      );
    });
  });
}
