import 'package:lacos_app/core/session/domain/exceptions/parse_object_not_found_exception.dart';
import 'package:lacos_app/core/session/domain/gateways/parse_user_session_gateway.dart';
import 'package:lacos_app/features/auth/domain/entities/authenticated_user.dart';
import 'package:lacos_app/features/auth/domain/repositories/auth_repository.dart';

class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({
    this.user,
    this.idToken = 'fake-id-token',
    this.getIdTokenError,
  });

  AuthenticatedUser? user;
  String idToken;
  Object? getIdTokenError;
  int getIdTokenCalls = 0;
  bool? lastForceRefresh;

  @override
  Stream<AuthenticatedUser?> get authenticatedUser => Stream.value(user);

  @override
  AuthenticatedUser? get currentUser => user;

  @override
  Future<AuthenticatedUser> createAccount({
    required String email,
    required String password,
  }) => throw UnimplementedError();

  @override
  Future<void> deleteCurrentUser() async {}

  @override
  Future<String> getIdToken({bool forceRefresh = false}) async {
    getIdTokenCalls++;
    lastForceRefresh = forceRefresh;
    if (getIdTokenError != null) {
      throw getIdTokenError!;
    }
    if (user == null) {
      throw StateError('Não encontramos uma sessão ativa. Entre novamente.');
    }
    return idToken;
  }

  @override
  Future<AuthenticatedUser?> reloadUser() async => user;

  @override
  Future<void> sendEmailVerification() async {}

  @override
  Future<AuthenticatedUser> signIn({
    required String email,
    required String password,
  }) => throw UnimplementedError();

  @override
  Future<void> signOut() async {
    user = null;
  }
}

class FakeParseUserSessionGateway implements ParseUserSessionGateway {
  FakeParseUserSessionGateway({
    this.current,
    this.loginError,
    this.becomeError,
    this.logoutError,
    this.becomeObjectId,
    this.becomeUsername,
    this.becomeFirebaseUid,
  });

  ParseUserSnapshot? current;
  final List<String> logins = [];
  final List<String> signUps = [];
  final List<String> becomes = [];
  int logoutCalls = 0;
  int clearLocalCalls = 0;
  Object? loginError;
  Object? becomeError;
  Object? logoutError;
  Set<String> existingUsernames = {};
  String? becomeObjectId;
  String? becomeUsername;
  String? becomeFirebaseUid;

  @override
  Future<ParseUserSnapshot?> currentUser() async => current;

  @override
  Future<void> login({
    required String username,
    required String password,
  }) async {
    logins.add(username);
    if (loginError != null) {
      throw loginError!;
    }
    current = ParseUserSnapshot(
      objectId: 'parse-$username',
      username: username,
      sessionTokenPresent: true,
      firebaseUid: username,
    );
  }

  @override
  Future<void> signUp({
    required String username,
    required String password,
    required String email,
  }) async {
    signUps.add(username);
    current = ParseUserSnapshot(
      objectId: 'parse-$username',
      username: username,
      sessionTokenPresent: true,
      firebaseUid: username,
    );
  }

  @override
  Future<ParseUserSnapshot> becomeWithSessionToken(String sessionToken) async {
    becomes.add('token-len:${sessionToken.length}');
    if (becomeError != null) {
      throw becomeError!;
    }
    final snapshot = ParseUserSnapshot(
      objectId: becomeObjectId ?? 'parse-1',
      username: becomeUsername ?? 'uid-1',
      sessionTokenPresent: true,
      firebaseUid: becomeFirebaseUid ?? becomeUsername ?? 'uid-1',
    );
    current = snapshot;
    return snapshot;
  }

  @override
  Future<void> logout() async {
    logoutCalls++;
    if (logoutError != null) {
      throw logoutError!;
    }
    current = null;
  }

  @override
  Future<bool> userExistsByUsername(String username) async {
    return existingUsernames.contains(username);
  }

  @override
  Future<void> clearLocalSession() async {
    clearLocalCalls++;
    current = null;
  }
}

AuthenticatedUser verifiedUser({
  String id = 'uid-1',
  String email = 'a@test.com',
}) {
  return AuthenticatedUser(id: id, email: email, isEmailVerified: true);
}

AuthenticatedUser unverifiedUser({
  String id = 'uid-1',
  String email = 'a@test.com',
}) {
  return AuthenticatedUser(id: id, email: email, isEmailVerified: false);
}

/// Helper: login throws object-not-found once then succeeds via signUp path.
Object get objectNotFound => const ParseObjectNotFoundException();
