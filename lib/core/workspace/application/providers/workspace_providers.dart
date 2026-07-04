import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lacos_app/core/session/application/providers/session_providers.dart';
import 'package:lacos_app/core/workspace/domain/entities/workspace.dart';
import 'package:lacos_app/features/auth/application/providers/auth_providers.dart';
import 'package:lacos_app/features/professional/application/providers/professional_providers.dart';
import 'package:lacos_app/features/salon/application/providers/salon_providers.dart';

final workspaceProvider = FutureProvider<Workspace?>((ref) async {
  final authRepository = ref.watch(authRepositoryProvider);
  final user = authRepository.currentUser;

  if (user == null) {
    return null;
  }

  if (!user.isEmailVerified) {
    return Workspace(user: user, salon: null, professional: null);
  }

  final sessionRepository = ref.watch(sessionRepositoryProvider);
  final salonRepository = ref.watch(salonRepositoryProvider);
  final professionalRepository = ref.watch(professionalRepositoryProvider);

  await sessionRepository.syncAuthenticatedUser();

  final salon = await salonRepository.getCurrentSalon();
  final professional = salon == null
      ? null
      : await professionalRepository.getCurrentProfessional();

  return Workspace(user: user, salon: salon, professional: professional);
});
