import 'dart:math';

import 'package:flutter/foundation.dart';

import 'package:lacos_app/core/session/domain/exceptions/auth_session_exception.dart';
import 'package:lacos_app/core/session/domain/gateways/parse_user_session_gateway.dart';
import 'package:lacos_app/core/session/domain/models/auth_session_strategy_kind.dart';
import 'package:lacos_app/core/session/domain/models/auth_session_sync_result.dart';
import 'package:lacos_app/core/session/domain/strategies/auth_session_strategy.dart';
import 'package:lacos_app/core/session/infrastructure/clients/exchange_session_client.dart';
import 'package:lacos_app/core/session/infrastructure/mappers/exchange_session_error_mapper.dart';
import 'package:lacos_app/features/auth/domain/repositories/auth_repository.dart';

/// Estratégia: Firebase ID Token → `exchangeSession` → Parse session (become).
class FirebaseExchangeSessionStrategy implements AuthSessionStrategy {
  FirebaseExchangeSessionStrategy({
    required AuthRepository authRepository,
    required ExchangeSessionClient exchangeSessionClient,
    required ParseUserSessionGateway parseGateway,
    ExchangeSessionErrorMapper? errorMapper,
    String Function()? requestIdFactory,
  }) : _authRepository = authRepository,
       _exchangeSessionClient = exchangeSessionClient,
       _parseGateway = parseGateway,
       _errorMapper = errorMapper ?? const ExchangeSessionErrorMapper(),
       _requestIdFactory = requestIdFactory ?? _defaultRequestId;

  final AuthRepository _authRepository;
  final ExchangeSessionClient _exchangeSessionClient;
  final ParseUserSessionGateway _parseGateway;
  final ExchangeSessionErrorMapper _errorMapper;
  final String Function() _requestIdFactory;

  @override
  AuthSessionStrategyKind get kind => AuthSessionStrategyKind.exchange;

  @override
  Future<AuthSessionSyncResult> sync(AuthSessionSyncContext context) async {
    final firebaseUser = context.firebaseUser;
    final startedAt = DateTime.now();
    final requestId = _requestIdFactory();

    _log(
      'exchange start requestId=$requestId '
      'strategy=exchange forceRefresh=${context.forceRefreshIdToken}',
    );

    try {
      var forceRefresh = context.forceRefreshIdToken;
      try {
        return await _exchangeAndBecome(
          firebaseUserId: firebaseUser.id,
          forceRefresh: forceRefresh,
          requestId: requestId,
          startedAt: startedAt,
        );
      } on AuthSessionException catch (error) {
        // Um retry com token fresco apenas para UNAUTHORIZED (token stale).
        if (error.code == ExchangeSessionErrorMapper.unauthorized &&
            !forceRefresh) {
          _log(
            'exchange retry with forceRefresh '
            'requestId=$requestId code=${error.code}',
          );
          forceRefresh = true;
          return await _exchangeAndBecome(
            firebaseUserId: firebaseUser.id,
            forceRefresh: forceRefresh,
            requestId: requestId,
            startedAt: startedAt,
          );
        }
        rethrow;
      }
    } on AuthSessionException catch (error) {
      _log(
        'exchange failed requestId=$requestId code=${error.code} '
        'durationMs=${_elapsedMs(startedAt)}',
      );
      rethrow;
    } on Object catch (error) {
      _log(
        'exchange failed requestId=$requestId code=INTERNAL '
        'durationMs=${_elapsedMs(startedAt)}',
      );
      if (error is FormatException || error is StateError) {
        rethrow;
      }
      throw const AuthSessionException(
        code: ExchangeSessionErrorMapper.internal,
        message: 'Não foi possível preparar sua sessão. Tente novamente.',
      );
    }
  }

  Future<AuthSessionSyncResult> _exchangeAndBecome({
    required String firebaseUserId,
    required bool forceRefresh,
    required String requestId,
    required DateTime startedAt,
  }) async {
    final idToken = await _authRepository.getIdToken(
      forceRefresh: forceRefresh,
    );

    final exchange = await _exchangeSessionClient.exchange(
      idToken: idToken,
      expectedFirebaseUid: firebaseUserId,
      requestId: requestId,
    );

    ParseUserSnapshot becomeUser;
    try {
      becomeUser = await _parseGateway.becomeWithSessionToken(
        exchange.sessionToken,
      );
    } on Object {
      await _parseGateway.clearLocalSession();
      throw _errorMapper.becomeFailedError();
    }

    if (becomeUser.objectId != exchange.parseUserId) {
      await _parseGateway.clearLocalSession();
      throw _errorMapper.sessionConflictError();
    }

    if (!becomeUser.matchesFirebaseUid(firebaseUserId)) {
      await _parseGateway.clearLocalSession();
      throw _errorMapper.sessionConflictError();
    }

    if (!becomeUser.sessionTokenPresent) {
      await _parseGateway.clearLocalSession();
      throw _errorMapper.becomeFailedError();
    }

    _log(
      'exchange success requestId=$requestId '
      'isNewUser=${exchange.isNewUser} becomeSuccess=true '
      'durationMs=${_elapsedMs(startedAt)}',
    );

    return AuthSessionSyncResult(
      strategy: kind,
      parseUserId: becomeUser.objectId,
      firebaseUid: firebaseUserId,
      isNewUser: exchange.isNewUser,
    );
  }

  static String _defaultRequestId() {
    final random = Random.secure().nextInt(0x7fffffff).toRadixString(16);
    return '${DateTime.now().millisecondsSinceEpoch}-$random';
  }

  static int _elapsedMs(DateTime startedAt) =>
      DateTime.now().difference(startedAt).inMilliseconds;

  static void _log(String message) {
    if (kDebugMode) {
      debugPrint('AuthSession: $message');
    }
  }
}
