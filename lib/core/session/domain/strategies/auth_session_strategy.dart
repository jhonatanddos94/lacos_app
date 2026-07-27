import 'package:lacos_app/core/session/domain/gateways/parse_user_session_gateway.dart';
import 'package:lacos_app/core/session/domain/models/auth_session_strategy_kind.dart';
import 'package:lacos_app/core/session/domain/models/auth_session_sync_result.dart';

/// Contrato de estratégia de estabelecimento de sessão Parse.
abstract interface class AuthSessionStrategy {
  AuthSessionStrategyKind get kind;

  Future<AuthSessionSyncResult> sync(AuthSessionSyncContext context);
}
