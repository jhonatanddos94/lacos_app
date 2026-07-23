import 'package:lacos_app/features/service_records/domain/entities/service_record_service.dart';

abstract interface class ServiceRecordServiceRepository {
  Future<List<ServiceRecordService>> findByServiceRecord(
    String serviceRecordId,
  );

  Future<List<ServiceRecordService>> createMany({
    required String serviceRecordId,
    required List<ServiceRecordService> services,
  });
}
