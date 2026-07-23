import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lacos_app/features/salon/application/providers/salon_providers.dart';
import 'package:lacos_app/features/service_records/domain/entities/service_record.dart';
import 'package:lacos_app/features/service_records/domain/repositories/service_record_repository.dart';
import 'package:lacos_app/features/service_records/infrastructure/repositories/parse_service_record_repository.dart';

final serviceRecordRepositoryProvider = Provider<ServiceRecordRepository>((
  ref,
) {
  final salonRepository = ref.watch(salonRepositoryProvider);
  return ParseServiceRecordRepository(salonRepository);
});

final serviceRecordByAppointmentProvider =
    FutureProvider.family<ServiceRecord?, String>((ref, appointmentId) {
      final repository = ref.watch(serviceRecordRepositoryProvider);
      return repository.findByAppointmentId(appointmentId);
    });

final serviceRecordsByClientProvider =
    FutureProvider.family<List<ServiceRecord>, String>((ref, clientId) {
      final repository = ref.watch(serviceRecordRepositoryProvider);
      return repository.findByClientId(clientId);
    });
