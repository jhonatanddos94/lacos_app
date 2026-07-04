import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lacos_app/features/salon/application/controllers/create_salon_controller.dart';
import 'package:lacos_app/features/salon/domain/entities/salon.dart';
import 'package:lacos_app/features/salon/domain/repositories/salon_repository.dart';
import 'package:lacos_app/features/salon/infrastructure/repositories/parse_salon_repository.dart';

final salonRepositoryProvider = Provider<SalonRepository>((ref) {
  return ParseSalonRepository();
});

final createSalonControllerProvider =
    StateNotifierProvider<CreateSalonController, AsyncValue<Salon?>>((ref) {
  final repository = ref.watch(salonRepositoryProvider);
  return CreateSalonController(repository);
});
