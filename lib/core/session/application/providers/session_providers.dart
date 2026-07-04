import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lacos_app/core/session/domain/repositories/session_repository.dart';
import 'package:lacos_app/core/session/infrastructure/repositories/parse_session_repository.dart';
import 'package:lacos_app/features/auth/application/providers/auth_providers.dart';

final sessionRepositoryProvider = Provider<SessionRepository>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  return ParseSessionRepository(authRepository);
});
