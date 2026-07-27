import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lacos_app/core/config/auth_feature_flags.dart';
import 'package:lacos_app/core/session/application/coordinators/auth_session_coordinator.dart';
import 'package:lacos_app/core/session/domain/gateways/parse_user_session_gateway.dart';
import 'package:lacos_app/core/session/domain/repositories/session_repository.dart';
import 'package:lacos_app/core/session/domain/strategies/auth_session_strategy.dart';
import 'package:lacos_app/core/session/infrastructure/clients/exchange_session_client.dart';
import 'package:lacos_app/core/session/infrastructure/gateways/parse_sdk_user_session_gateway.dart';
import 'package:lacos_app/core/session/infrastructure/repositories/parse_session_repository.dart';
import 'package:lacos_app/core/session/infrastructure/strategies/firebase_exchange_session_strategy.dart';
import 'package:lacos_app/core/session/infrastructure/strategies/legacy_parse_session_strategy.dart';
import 'package:lacos_app/features/auth/application/providers/auth_providers.dart';

final authFeatureFlagsProvider = Provider<bool>((ref) {
  return AuthFeatureFlags.useExchangeSession;
});

final parseUserSessionGatewayProvider = Provider<ParseUserSessionGateway>((
  ref,
) {
  return ParseSdkUserSessionGateway();
});

final exchangeSessionClientProvider = Provider<ExchangeSessionClient>((ref) {
  return ExchangeSessionClient();
});

final legacyParseSessionStrategyProvider = Provider<AuthSessionStrategy>((ref) {
  final gateway = ref.watch(parseUserSessionGatewayProvider);
  return LegacyParseSessionStrategy(gateway: gateway);
});

final firebaseExchangeSessionStrategyProvider = Provider<AuthSessionStrategy>((
  ref,
) {
  return FirebaseExchangeSessionStrategy(
    authRepository: ref.watch(authRepositoryProvider),
    exchangeSessionClient: ref.watch(exchangeSessionClientProvider),
    parseGateway: ref.watch(parseUserSessionGatewayProvider),
  );
});

final authSessionCoordinatorProvider = Provider<AuthSessionCoordinator>((ref) {
  return AuthSessionCoordinator(
    authRepository: ref.watch(authRepositoryProvider),
    parseGateway: ref.watch(parseUserSessionGatewayProvider),
    legacyStrategy: ref.watch(legacyParseSessionStrategyProvider),
    exchangeStrategy: ref.watch(firebaseExchangeSessionStrategyProvider),
    useExchangeSession: ref.watch(authFeatureFlagsProvider),
  );
});

final sessionRepositoryProvider = Provider<SessionRepository>((ref) {
  return ParseSessionRepository(
    coordinator: ref.watch(authSessionCoordinatorProvider),
    parseGateway: ref.watch(parseUserSessionGatewayProvider),
  );
});
