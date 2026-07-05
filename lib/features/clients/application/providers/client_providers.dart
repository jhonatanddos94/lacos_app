import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lacos_app/features/clients/application/controllers/client_form_controller.dart';
import 'package:lacos_app/features/clients/domain/entities/client.dart';
import 'package:lacos_app/features/clients/domain/repositories/client_repository.dart';
import 'package:lacos_app/features/clients/infrastructure/repositories/parse_client_repository.dart';
import 'package:lacos_app/features/salon/application/providers/salon_providers.dart';

final clientRepositoryProvider = Provider<ClientRepository>((ref) {
  final salonRepository = ref.watch(salonRepositoryProvider);
  return ParseClientRepository(salonRepository);
});

final clientsProvider = FutureProvider<List<Client>>((ref) {
  final repository = ref.watch(clientRepositoryProvider);
  return repository.findAll();
});

final clientFormControllerProvider =
    StateNotifierProvider<ClientFormController, AsyncValue<Client?>>((ref) {
      final repository = ref.watch(clientRepositoryProvider);
      return ClientFormController(repository);
    });
