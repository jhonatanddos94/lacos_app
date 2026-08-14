/// Cold-start rule for "Lembrar-me".
///
/// `true`: keep persisted Firebase/Parse sessions and restore.
/// `false`: discard persisted sessions before any authenticated route.
///
/// Does not run on background/resume. Does not sign out after a successful
/// in-process login.
class RememberMeStartupPolicy {
  const RememberMeStartupPolicy();

  /// Applies Parse then Firebase sign-out when a persisted session must not
  /// be restored. Always prefers an unauthenticated end state.
  Future<void> apply({
    required bool rememberMe,
    required bool hasFirebaseSession,
    required bool hasParseSession,
    required Future<void> Function() signOutParse,
    required Future<void> Function() signOutFirebase,
    void Function(String message)? onSanitizedError,
  }) async {
    if (rememberMe) return;
    if (!hasFirebaseSession && !hasParseSession) return;

    try {
      await signOutParse();
    } on Object catch (error) {
      onSanitizedError?.call('Parse signOut failed: ${error.runtimeType}');
    }

    try {
      await signOutFirebase();
    } on Object catch (error) {
      onSanitizedError?.call('Firebase signOut failed: ${error.runtimeType}');
    }
  }
}
