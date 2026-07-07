import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lacos_app/features/salon/application/providers/salon_providers.dart';
import 'package:lacos_app/features/service_records/domain/entities/service_record_service.dart';
import 'package:lacos_app/features/service_records/domain/repositories/service_record_service_repository.dart';
import 'package:lacos_app/features/service_records/infrastructure/repositories/parse_service_record_service_repository.dart';

final serviceRecordServiceRepositoryProvider =
    Provider<ServiceRecordServiceRepository>((ref) {
      final salonRepository = ref.watch(salonRepositoryProvider);
      return ParseServiceRecordServiceRepository(salonRepository);
    });

final serviceRecordServicesByServiceRecordProvider =
    FutureProvider.family<List<ServiceRecordService>, String>((
      ref,
      serviceRecordId,
    ) {
      final repository = ref.watch(serviceRecordServiceRepositoryProvider);
      return repository.findByServiceRecord(serviceRecordId);
    });
