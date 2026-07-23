import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lacos_app/features/memories/domain/entities/client_memory.dart';
import 'package:lacos_app/features/memories/domain/repositories/client_memory_repository.dart';
import 'package:lacos_app/features/memories/infrastructure/repositories/parse_client_memory_repository.dart';
import 'package:lacos_app/features/memories/presentation/controllers/client_memory_actions_controller.dart';
import 'package:lacos_app/features/memories/presentation/controllers/memory_form_controller.dart';
import 'package:lacos_app/features/memories/presentation/controllers/memory_form_state.dart';
import 'package:lacos_app/features/professional/application/providers/professional_providers.dart';
import 'package:lacos_app/features/salon/application/providers/salon_providers.dart';

final clientMemoryRepositoryProvider = Provider<ClientMemoryRepository>((ref) {
  final salonRepository = ref.watch(salonRepositoryProvider);
  final professionalRepository = ref.watch(professionalRepositoryProvider);
  return ParseClientMemoryRepository(
    salonRepository,
    professionalRepository,
  );
});

final clientMemoriesProvider =
    FutureProvider.family<List<ClientMemory>, String>((ref, clientId) {
      final repository = ref.watch(clientMemoryRepositoryProvider);
      return repository.findByClient(clientId: clientId);
    });

final memoryFormControllerProvider =
    StateNotifierProvider<MemoryFormController, MemoryFormState>(
      (ref) {
        final repository = ref.watch(clientMemoryRepositoryProvider);
        return MemoryFormController(repository);
      },
    );

final clientMemoryActionsControllerProvider =
    StateNotifierProvider<ClientMemoryActionsController, ClientMemoryActionsState>(
      (ref) {
        final repository = ref.watch(clientMemoryRepositoryProvider);
        return ClientMemoryActionsController(repository);
      },
    );
