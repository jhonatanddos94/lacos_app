import 'package:lacos_app/core/session/domain/exceptions/parse_object_not_found_exception.dart';
import 'package:lacos_app/core/session/domain/gateways/parse_user_session_gateway.dart';
import 'package:lacos_app/core/session/domain/models/auth_session_strategy_kind.dart';
import 'package:lacos_app/core/session/domain/models/auth_session_sync_result.dart';
import 'package:lacos_app/core/session/domain/strategies/auth_session_strategy.dart';

/// Fluxo legado com senha Parse derivável.
///
/// Deprecated para migração: mantido para dual-run / rollback.
/// Não remover nesta sprint. Não emitir warning ao usuário.
class LegacyParseSessionStrategy implements AuthSessionStrategy {
  LegacyParseSessionStrategy({required ParseUserSessionGateway gateway})
    : _gateway = gateway;

  final ParseUserSessionGateway _gateway;

  @override
  AuthSessionStrategyKind get kind => AuthSessionStrategyKind.legacy;

  @override
  Future<AuthSessionSyncResult> sync(AuthSessionSyncContext context) async {
    final firebaseUser = context.firebaseUser;
    final username = firebaseUser.id;
    final password = buildParsePassword(username);

    try {
      await _gateway.login(username: username, password: password);
    } on ParseObjectNotFoundException {
      final userExists = await _gateway.userExistsByUsername(username);
      if (userExists) {
        throw const FormatException(
          'Não foi possível preparar sua sessão. Tente novamente.',
        );
      }

      await _gateway.signUp(
        username: username,
        password: password,
        email: firebaseUser.email,
      );
    }

    final current = await _gateway.currentUser();
    if (current == null || !current.matchesFirebaseUid(firebaseUser.id)) {
      throw const FormatException(
        'Não foi possível preparar sua sessão. Tente novamente.',
      );
    }

    return AuthSessionSyncResult(
      strategy: kind,
      parseUserId: current.objectId,
      firebaseUid: firebaseUser.id,
    );
  }

  /// Senha derivável legada — NÃO usar no fluxo exchange.
  static String buildParsePassword(String uid) {
    // TODO(T1.4+): remover após cutover e rotação controlada.
    return 'lacos_parse_session_v1_$uid';
  }
}
