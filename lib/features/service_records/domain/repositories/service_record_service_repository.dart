import 'package:lacos_app/features/service_records/domain/entities/service_record_service.dart';

abstract interface class ServiceRecordServiceRepository {
  Future<List<ServiceRecordService>> findByServiceRecord(
    String serviceRecordId,
  );

  /// Carrega linhas de vários ServiceRecords em uma única query (evita N+1).
  Future<List<ServiceRecordService>> findByServiceRecordIds(
    List<String> serviceRecordIds,
  );

  Future<List<ServiceRecordService>> createMany({
    required String serviceRecordId,
    required List<ServiceRecordService> services,
  });
}
