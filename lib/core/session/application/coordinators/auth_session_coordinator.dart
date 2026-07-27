import 'package:flutter/foundation.dart';

import 'package:lacos_app/core/config/auth_feature_flags.dart';
import 'package:lacos_app/core/session/domain/exceptions/auth_session_exception.dart';
import 'package:lacos_app/core/session/domain/gateways/parse_user_session_gateway.dart';
import 'package:lacos_app/core/session/domain/models/auth_session_strategy_kind.dart';
import 'package:lacos_app/core/session/domain/models/auth_session_sync_result.dart';
import 'package:lacos_app/core/session/domain/strategies/auth_session_strategy.dart';
import 'package:lacos_app/features/auth/domain/entities/authenticated_user.dart';
import 'package:lacos_app/features/auth/domain/repositories/auth_repository.dart';

/// Ponto único que escolhe a estratégia de sessão (dual-run).
///
/// Flag ON + falha no exchange → NÃO faz fallback silencioso para o legado.
class AuthSessionCoordinator {
  AuthSessionCoordinator({
    required AuthRepository authRepository,
    required ParseUserSessionGateway parseGateway,
    required AuthSessionStrategy legacyStrategy,
    required AuthSessionStrategy exchangeStrategy,
    bool? useExchangeSession,
  }) : _authRepository = authRepository,
       _parseGateway = parseGateway,
       _legacyStrategy = legacyStrategy,
       _exchangeStrategy = exchangeStrategy,
       _useExchangeSession =
           useExchangeSession ?? AuthFeatureFlags.useExchangeSession;

  final AuthRepository _authRepository;
  final ParseUserSessionGateway _parseGateway;
  final AuthSessionStrategy _legacyStrategy;
  final AuthSessionStrategy _exchangeStrategy;
  final bool _useExchangeSession;

  bool get useExchangeSession => _useExchangeSession;

  AuthSessionStrategyKind get activeStrategyKind => _useExchangeSession
      ? AuthSessionStrategyKind.exchange
      : AuthSessionStrategyKind.legacy;

  /// Sincroniza a sessão Parse para o usuário Firebase atual.
  Future<AuthSessionSyncResult> syncAuthenticatedUser({
    bool forceRefreshIdToken = false,
  }) async {
    final startedAt = DateTime.now();
    final firebaseUser = _authRepository.currentUser;
    if (firebaseUser == null) {
      throw StateError('Não encontramos uma sessão ativa. Entre novamente.');
    }

    final strategy = _useExchangeSession ? _exchangeStrategy : _legacyStrategy;

    _log(
      'sync start strategy=${strategy.kind.telemetryLabel} '
      'flag=$_useExchangeSession',
    );

    final reused = await _tryReuseExistingSession(firebaseUser);
    if (reused != null) {
      _log(
        'sync reusedExistingSession strategy=${strategy.kind.telemetryLabel} '
        'durationMs=${_elapsedMs(startedAt)}',
      );
      return reused.copyWithStrategy(strategy.kind);
    }

    await _clearCrossUserSessionIfNeeded(firebaseUser.id);

    try {
      final result = await strategy.sync(
        AuthSessionSyncContext(
          firebaseUser: firebaseUser,
          forceRefreshIdToken: forceRefreshIdToken,
        ),
      );

      _log(
        'sync success strategy=${result.strategy.telemetryLabel} '
        'exchangeSuccess=$_useExchangeSession '
        'durationMs=${_elapsedMs(startedAt)}',
      );

      return result;
    } on AuthSessionException catch (error) {
      _log(
        'sync failed strategy=${strategy.kind.telemetryLabel} '
        'exchangeFailureCode=${error.code} '
        'durationMs=${_elapsedMs(startedAt)}',
      );
      // Sem fallback silencioso para legado.
      rethrow;
    } on Object catch (error) {
      _log(
        'sync failed strategy=${strategy.kind.telemetryLabel} '
        'durationMs=${_elapsedMs(startedAt)} errorType=${error.runtimeType}',
      );
      rethrow;
    }
  }

  Future<AuthSessionSyncResult?> _tryReuseExistingSession(
    AuthenticatedUser firebaseUser,
  ) async {
    final current = await _parseGateway.currentUser();
    if (current == null) return null;
    if (!current.sessionTokenPresent) return null;
    if (!current.matchesFirebaseUid(firebaseUser.id)) return null;

    return AuthSessionSyncResult(
      strategy: activeStrategyKind,
      parseUserId: current.objectId,
      firebaseUid: firebaseUser.id,
      reusedExistingSession: true,
    );
  }

  Future<void> _clearCrossUserSessionIfNeeded(String firebaseUid) async {
    final current = await _parseGateway.currentUser();
    if (current == null) return;
    if (current.matchesFirebaseUid(firebaseUid)) return;

    _log('clear cross-user Parse session');
    await _parseGateway.clearLocalSession();
  }

  static int _elapsedMs(DateTime startedAt) =>
      DateTime.now().difference(startedAt).inMilliseconds;

  static void _log(String message) {
    if (kDebugMode) {
      debugPrint('AuthSessionCoordinator: $message');
    }
  }
}

extension on AuthSessionSyncResult {
  AuthSessionSyncResult copyWithStrategy(AuthSessionStrategyKind strategy) {
    return AuthSessionSyncResult(
      strategy: strategy,
      parseUserId: parseUserId,
      firebaseUid: firebaseUid,
      isNewUser: isNewUser,
      reusedExistingSession: reusedExistingSession,
    );
  }
}
