import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lacos_app/features/appointments/application/providers/appointment_providers.dart';
import 'package:lacos_app/features/clients/application/loaders/client_service_history_loader.dart';
import 'package:lacos_app/features/clients/application/models/client_service_history_item.dart';
import 'package:lacos_app/features/clients/application/models/client_service_history_month_group.dart';
import 'package:lacos_app/features/clients/application/models/client_service_history_preview.dart';
import 'package:lacos_app/features/clients/application/services/client_service_history_formatters.dart';
import 'package:lacos_app/features/clients/application/services/client_service_history_preview_service.dart';
import 'package:lacos_app/features/professional/application/providers/professional_providers.dart';
import 'package:lacos_app/features/service_records/application/providers/service_record_providers.dart';
import 'package:lacos_app/features/service_records/application/providers/service_record_service_providers.dart';
import 'package:lacos_app/features/services/application/providers/service_providers.dart';

final clientServiceHistoryLoaderProvider = Provider<ClientServiceHistoryLoader>((
  ref,
) {
  return ClientServiceHistoryLoader(
    serviceRecordRepository: ref.watch(serviceRecordRepositoryProvider),
    serviceRecordServiceRepository: ref.watch(
      serviceRecordServiceRepositoryProvider,
    ),
    appointmentRepository: ref.watch(appointmentRepositoryProvider),
    appointmentServiceRepository: ref.watch(
      appointmentServiceRepositoryProvider,
    ),
    professionalRepository: ref.watch(professionalRepositoryProvider),
    serviceRepository: ref.watch(serviceRepositoryProvider),
  );
});

/// Histórico completo: concluídos (ServiceRecord) + cancelados (Appointment).
final clientServiceHistoryProvider =
    FutureProvider.autoDispose.family<List<ClientServiceHistoryItem>, String>((
      ref,
      clientId,
    ) {
      if (clientId.trim().isEmpty) {
        return Future.value(const []);
      }

      final loader = ref.watch(clientServiceHistoryLoaderProvider);
      return loader.load(clientId: clientId);
    });

/// Prévia da ficha: até 3 concluídos recentes (ignora cancelados).
final clientServiceHistoryPreviewProvider =
    Provider.autoDispose.family<AsyncValue<ClientServiceHistoryPreview>, String>((
      ref,
      clientId,
    ) {
      final historyAsync = ref.watch(clientServiceHistoryProvider(clientId));

      return historyAsync.when(
        loading: () => const AsyncValue.loading(),
        error: AsyncValue.error,
        data: (items) => AsyncValue.data(
          ClientServiceHistoryPreviewService.resolve(items),
        ),
      );
    });

/// Agrupamento completo sem filtro (usado quando a UI filtra localmente).
final clientServiceHistoryGroupedProvider =
    Provider.autoDispose
        .family<AsyncValue<List<ClientServiceHistoryMonthGroup>>, String>((
          ref,
          clientId,
        ) {
          final historyAsync = ref.watch(clientServiceHistoryProvider(clientId));

          return historyAsync.when(
            loading: () => const AsyncValue.loading(),
            error: AsyncValue.error,
            data: (items) =>
                AsyncValue.data(ClientServiceHistoryGrouper.groupByMonth(items)),
          );
        });
