import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lacos_app/core/session/application/providers/session_providers.dart';
import 'package:lacos_app/features/auth/application/policies/remember_me_startup_policy.dart';
import 'package:lacos_app/features/auth/application/providers/auth_providers.dart';
import 'package:lacos_app/features/auth/domain/repositories/remember_me_preference_repository.dart';
import 'package:lacos_app/features/auth/infrastructure/repositories/shared_preferences_remember_me_preference_repository.dart';

final rememberMePreferenceRepositoryProvider =
    Provider<RememberMePreferenceRepository>((ref) {
      return SharedPreferencesRememberMePreferenceRepository();
    });

/// Runs once per process, before [workspaceProvider] resolves a route.
///
/// When rememberMe is false and a persisted session exists, signs out Parse
/// then Firebase so Splash never mounts the Shell.
final sessionRestoreProvider = FutureProvider<void>((ref) async {
  final rememberMe = await ref
      .read(rememberMePreferenceRepositoryProvider)
      .read();
  final authRepository = ref.read(authRepositoryProvider);
  final sessionRepository = ref.read(sessionRepositoryProvider);
  final parseGateway = ref.read(parseUserSessionGatewayProvider);

  var hasParseSession = false;
  try {
    final parseUser = await parseGateway.currentUser();
    hasParseSession = parseUser != null;
  } on Object catch (error) {
    _debugLog('Parse currentUser failed: ${error.runtimeType}');
  }

  await const RememberMeStartupPolicy().apply(
    rememberMe: rememberMe,
    hasFirebaseSession: authRepository.currentUser != null,
    hasParseSession: hasParseSession,
    signOutParse: sessionRepository.signOut,
    signOutFirebase: authRepository.signOut,
    onSanitizedError: _debugLog,
  );
});

void _debugLog(String message) {
  if (kDebugMode) {
    debugPrint('RememberMeStartup: $message');
  }
}
