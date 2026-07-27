import 'package:flutter_test/flutter_test.dart';

import 'package:lacos_app/core/session/domain/gateways/parse_user_session_gateway.dart';
import 'package:lacos_app/core/session/infrastructure/repositories/parse_session_repository.dart';
import 'package:lacos_app/core/session/application/coordinators/auth_session_coordinator.dart';
import 'package:lacos_app/core/session/infrastructure/strategies/legacy_parse_session_strategy.dart';
import 'package:lacos_app/core/session/infrastructure/strategies/firebase_exchange_session_strategy.dart';
import 'package:lacos_app/core/session/infrastructure/clients/exchange_session_client.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';

import 'fakes/session_test_fakes.dart';

void main() {
  group('ParseSessionRepository.signOut', () {
    test('logs out parse gateway', () async {
      final auth = FakeAuthRepository(user: verifiedUser());
      final gateway = FakeParseUserSessionGateway(
        current: const ParseUserSnapshot(
          objectId: 'p1',
          username: 'uid-1',
          sessionTokenPresent: true,
        ),
      );
      final repo = ParseSessionRepository(
        coordinator: AuthSessionCoordinator(
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
        ),
        parseGateway: gateway,
      );

      await repo.signOut();

      expect(gateway.logoutCalls, 1);
      expect(gateway.current, isNull);
    });

    test('clears local session when logout fails', () async {
      final auth = FakeAuthRepository(user: verifiedUser());
      final gateway = FakeParseUserSessionGateway(
        current: const ParseUserSnapshot(
          objectId: 'p1',
          username: 'uid-1',
          sessionTokenPresent: true,
        ),
        logoutError: const FormatException('logout failed'),
      );
      final repo = ParseSessionRepository(
        coordinator: AuthSessionCoordinator(
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
        ),
        parseGateway: gateway,
      );

      await expectLater(repo.signOut(), throwsA(isA<FormatException>()));
      expect(gateway.clearLocalCalls, 1);
    });
  });
}
