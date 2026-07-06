import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lacos_app/features/services/application/controllers/service_form_controller.dart';
import 'package:lacos_app/features/services/domain/entities/service.dart';
import 'package:lacos_app/features/services/domain/repositories/service_repository.dart';
import 'package:lacos_app/features/services/infrastructure/repositories/parse_service_repository.dart';
import 'package:lacos_app/features/salon/application/providers/salon_providers.dart';

final serviceRepositoryProvider = Provider<ServiceRepository>((ref) {
  final salonRepository = ref.watch(salonRepositoryProvider);
  return ParseServiceRepository(salonRepository);
});

final servicesProvider = FutureProvider<List<Service>>((ref) {
  final repository = ref.watch(serviceRepositoryProvider);
  return repository.findAll();
});

final serviceFormControllerProvider =
    StateNotifierProvider<ServiceFormController, AsyncValue<Service?>>((ref) {
      final repository = ref.watch(serviceRepositoryProvider);
      return ServiceFormController(repository);
    });
