import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lacos_app/features/professional/application/controllers/create_professional_controller.dart';
import 'package:lacos_app/features/professional/domain/entities/professional.dart';
import 'package:lacos_app/features/professional/domain/repositories/professional_repository.dart';
import 'package:lacos_app/features/professional/infrastructure/repositories/parse_professional_repository.dart';
import 'package:lacos_app/features/salon/application/providers/salon_providers.dart';

final professionalRepositoryProvider = Provider<ProfessionalRepository>((ref) {
  final salonRepository = ref.watch(salonRepositoryProvider);
  return ParseProfessionalRepository(salonRepository);
});

final createProfessionalControllerProvider =
    StateNotifierProvider<
      CreateProfessionalController,
      AsyncValue<Professional?>
    >((ref) {
      final repository = ref.watch(professionalRepositoryProvider);
      return CreateProfessionalController(repository);
    });
