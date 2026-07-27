import 'package:flutter_test/flutter_test.dart';

import 'package:lacos_app/core/session/domain/exceptions/auth_session_exception.dart';
import 'package:lacos_app/core/session/domain/gateways/parse_user_session_gateway.dart';
import 'package:lacos_app/core/session/domain/models/auth_session_strategy_kind.dart';
import 'package:lacos_app/core/session/infrastructure/clients/exchange_session_client.dart';
import 'package:lacos_app/core/session/infrastructure/mappers/exchange_session_error_mapper.dart';
import 'package:lacos_app/core/session/infrastructure/strategies/firebase_exchange_session_strategy.dart';
import 'package:lacos_app/core/session/infrastructure/strategies/legacy_parse_session_strategy.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';

import 'fakes/session_test_fakes.dart';

void main() {
  group('LegacyParseSessionStrategy', () {
    test('logs in with derived password credentials path', () async {
      final gateway = FakeParseUserSessionGateway();
      final strategy = LegacyParseSessionStrategy(gateway: gateway);
      final auth = FakeAuthRepository(user: verifiedUser());

      final result = await strategy.sync(
        AuthSessionSyncContext(firebaseUser: auth.user!),
      );

      expect(result.strategy, AuthSessionStrategyKind.legacy);
      expect(result.parseUserId, 'parse-uid-1');
      expect(gateway.logins, ['uid-1']);
      expect(
        LegacyParseSessionStrategy.buildParsePassword('uid-1'),
        'lacos_parse_session_v1_uid-1',
      );
    });

    test('creates user when object not found and username free', () async {
      final gateway = FakeParseUserSessionGateway(
        loginError: objectNotFound,
      );
      final strategy = LegacyParseSessionStrategy(gateway: gateway);

      final result = await strategy.sync(
        AuthSessionSyncContext(firebaseUser: verifiedUser()),
      );

      expect(result.parseUserId, 'parse-uid-1');
      expect(gateway.signUps, ['uid-1']);
    });

    test('fails when object not found but username exists', () async {
      final gateway = FakeParseUserSessionGateway(
        loginError: objectNotFound,
      )..existingUsernames = {'uid-1'};
      final strategy = LegacyParseSessionStrategy(gateway: gateway);

      expect(
        () => strategy.sync(
          AuthSessionSyncContext(firebaseUser: verifiedUser()),
        ),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('FirebaseExchangeSessionStrategy', () {
    ExchangeSessionClient clientWithResult({
      String parseUserId = 'parse-1',
      String firebaseUid = 'uid-1',
      bool failUnauthorizedFirst = false,
    }) {
      var calls = 0;
      return ExchangeSessionClient(
        executor: (_) async {
          calls++;
          if (failUnauthorizedFirst && calls == 1) {
            return ParseResponse()
              ..success = false
              ..error = ParseError(
                code: 401,
                message: '{"code":"UNAUTHORIZED","message":"bad"}',
              );
          }
          return ParseResponse()
            ..success = true
            ..result = {
              'sessionToken': 'r:session',
              'parseUserId': parseUserId,
              'firebaseUid': firebaseUid,
              'email': 'a@test.com',
              'securityMode': 'permissive',
              'isNewUser': true,
            };
        },
      );
    }

    test('exchanges token and becomes parse user', () async {
      final auth = FakeAuthRepository(user: verifiedUser());
      final gateway = FakeParseUserSessionGateway(
        becomeObjectId: 'parse-1',
        becomeUsername: 'uid-1',
      );
      final strategy = FirebaseExchangeSessionStrategy(
        authRepository: auth,
        exchangeSessionClient: clientWithResult(),
        parseGateway: gateway,
        requestIdFactory: () => 'req-fixed',
      );

      final result = await strategy.sync(
        AuthSessionSyncContext(firebaseUser: verifiedUser()),
      );

      expect(result.strategy, AuthSessionStrategyKind.exchange);
      expect(result.parseUserId, 'parse-1');
      expect(result.isNewUser, isTrue);
      expect(auth.getIdTokenCalls, 1);
      expect(auth.lastForceRefresh, isFalse);
      expect(gateway.becomes, isNotEmpty);
    });

    test('fails when firebase user absent for token', () async {
      final auth = FakeAuthRepository(user: null);
      final strategy = FirebaseExchangeSessionStrategy(
        authRepository: auth,
        exchangeSessionClient: clientWithResult(),
        parseGateway: FakeParseUserSessionGateway(),
      );

      expect(
        () => strategy.sync(
          AuthSessionSyncContext(firebaseUser: verifiedUser()),
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('clears session and fails on become error', () async {
      final auth = FakeAuthRepository(user: verifiedUser());
      final gateway = FakeParseUserSessionGateway(
        becomeError: Exception('become failed'),
      );
      final strategy = FirebaseExchangeSessionStrategy(
        authRepository: auth,
        exchangeSessionClient: clientWithResult(),
        parseGateway: gateway,
      );

      await expectLater(
        strategy.sync(AuthSessionSyncContext(firebaseUser: verifiedUser())),
        throwsA(
          isA<AuthSessionException>().having(
            (e) => e.code,
            'code',
            ExchangeSessionErrorMapper.becomeFailed,
          ),
        ),
      );
      expect(gateway.clearLocalCalls, 1);
    });

    test('fails safely on objectId mismatch', () async {
      final auth = FakeAuthRepository(user: verifiedUser());
      final gateway = FakeParseUserSessionGateway(
        becomeObjectId: 'other-id',
        becomeUsername: 'uid-1',
      );
      final strategy = FirebaseExchangeSessionStrategy(
        authRepository: auth,
        exchangeSessionClient: clientWithResult(parseUserId: 'parse-1'),
        parseGateway: gateway,
      );

      await expectLater(
        strategy.sync(AuthSessionSyncContext(firebaseUser: verifiedUser())),
        throwsA(
          isA<AuthSessionException>().having(
            (e) => e.code,
            'code',
            ExchangeSessionErrorMapper.sessionConflict,
          ),
        ),
      );
      expect(gateway.clearLocalCalls, 1);
    });

    test('retries once with forceRefresh on UNAUTHORIZED', () async {
      final auth = FakeAuthRepository(user: verifiedUser());
      final gateway = FakeParseUserSessionGateway(
        becomeObjectId: 'parse-1',
        becomeUsername: 'uid-1',
      );
      final strategy = FirebaseExchangeSessionStrategy(
        authRepository: auth,
        exchangeSessionClient: clientWithResult(failUnauthorizedFirst: true),
        parseGateway: gateway,
      );

      final result = await strategy.sync(
        AuthSessionSyncContext(firebaseUser: verifiedUser()),
      );

      expect(result.parseUserId, 'parse-1');
      expect(auth.getIdTokenCalls, 2);
      expect(auth.lastForceRefresh, isTrue);
    });
  });
}
