import 'package:lacos_app/core/session/domain/models/auth_session_strategy_kind.dart';

/// Resultado tipado do estabelecimento de sessão Parse.
class AuthSessionSyncResult {
  const AuthSessionSyncResult({
    required this.strategy,
    required this.parseUserId,
    required this.firebaseUid,
    this.isNewUser,
    this.reusedExistingSession = false,
  });

  final AuthSessionStrategyKind strategy;
  final String parseUserId;
  final String firebaseUid;
  final bool? isNewUser;
  final bool reusedExistingSession;
}
