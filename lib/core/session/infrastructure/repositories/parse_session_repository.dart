import 'package:lacos_app/core/config/app_strings.dart';
import 'package:lacos_app/core/session/application/coordinators/auth_session_coordinator.dart';
import 'package:lacos_app/core/session/domain/exceptions/auth_session_exception.dart';
import 'package:lacos_app/core/session/domain/gateways/parse_user_session_gateway.dart';
import 'package:lacos_app/core/session/domain/repositories/session_repository.dart';

/// Fachada de sessão Parse — delega ao [AuthSessionCoordinator] (dual-run).
class ParseSessionRepository implements SessionRepository {
  ParseSessionRepository({
    required AuthSessionCoordinator coordinator,
    required ParseUserSessionGateway parseGateway,
  }) : _coordinator = coordinator,
       _parseGateway = parseGateway;

  final AuthSessionCoordinator _coordinator;
  final ParseUserSessionGateway _parseGateway;

  @override
  Future<void> syncAuthenticatedUser({bool forceRefreshIdToken = false}) async {
    try {
      await _coordinator.syncAuthenticatedUser(
        forceRefreshIdToken: forceRefreshIdToken,
      );
    } on AuthSessionException {
      rethrow;
    } on StateError {
      rethrow;
    } on FormatException {
      rethrow;
    } on Object {
      throw const FormatException(
        'Não foi possível preparar sua sessão. Tente novamente.',
      );
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _parseGateway.logout();
    } on FormatException {
      // Tenta limpeza local mesmo se logout remoto falhar.
      await _parseGateway.clearLocalSession();
      rethrow;
    } on Object {
      await _parseGateway.clearLocalSession();
      throw const FormatException(AppStrings.logoutError);
    }
  }
}
