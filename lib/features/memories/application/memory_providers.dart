import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lacos_app/features/memories/application/models/client_memory_filters.dart';
import 'package:lacos_app/features/memories/application/models/client_memory_highlights.dart';
import 'package:lacos_app/features/memories/application/models/client_memory_profile_preview.dart';
import 'package:lacos_app/features/memories/application/services/client_memory_filter_service.dart';
import 'package:lacos_app/features/memories/application/services/client_memory_highlights_service.dart';
import 'package:lacos_app/features/memories/application/services/client_memory_profile_preview_service.dart';
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
  return ParseClientMemoryRepository(salonRepository, professionalRepository);
});

final clientMemoriesProvider =
    FutureProvider.family<List<ClientMemory>, String>((ref, clientId) {
      final repository = ref.watch(clientMemoryRepositoryProvider);
      return repository.findByClient(clientId: clientId);
    });

final clientMemoryHighlightsProvider =
    Provider.family<ClientMemoryHighlights, String>((ref, clientId) {
      final memoriesAsync = ref.watch(clientMemoriesProvider(clientId));

      return memoriesAsync.maybeWhen(
        data: ClientMemoryHighlightsService.resolve,
        orElse: () => ClientMemoryHighlights.empty,
      );
    });

final clientMemoryProfilePreviewProvider =
    Provider.family<ClientMemoryProfilePreview, String>((ref, clientId) {
      final memoriesAsync = ref.watch(clientMemoriesProvider(clientId));

      return memoriesAsync.maybeWhen(
        data: ClientMemoryProfilePreviewService.resolve,
        orElse: () => ClientMemoryProfilePreview.empty,
      );
    });

final clientMemoriesCatalogProvider =
    FutureProvider.family<List<ClientMemory>, String>((ref, clientId) {
      final repository = ref.watch(clientMemoryRepositoryProvider);
      return repository.findByClient(clientId: clientId, includeArchived: true);
    });

final clientMemoryFiltersProvider =
    StateProvider.family<ClientMemoryFilters, String>(
      (ref, clientId) => ClientMemoryFilters.defaults,
    );

final filteredClientMemoriesProvider =
    Provider.family<AsyncValue<List<ClientMemory>>, String>((ref, clientId) {
      final catalogAsync = ref.watch(clientMemoriesCatalogProvider(clientId));
      final filters = ref.watch(clientMemoryFiltersProvider(clientId));

      return catalogAsync.whenData(
        (memories) => ClientMemoryFilterService.apply(
          memories: memories,
          filters: filters,
        ),
      );
    });

final memoryFormControllerProvider =
    StateNotifierProvider<MemoryFormController, MemoryFormState>((ref) {
      final repository = ref.watch(clientMemoryRepositoryProvider);
      return MemoryFormController(repository);
    });

final clientMemoryActionsControllerProvider =
    StateNotifierProvider<
      ClientMemoryActionsController,
      ClientMemoryActionsState
    >((ref) {
      final repository = ref.watch(clientMemoryRepositoryProvider);
      return ClientMemoryActionsController(repository);
    });
