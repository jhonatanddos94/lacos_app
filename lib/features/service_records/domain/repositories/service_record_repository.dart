import 'package:lacos_app/features/service_records/domain/entities/service_record.dart';

abstract interface class ServiceRecordRepository {
  Future<ServiceRecord> create(
    ServiceRecord record, {
    String? legacyPrimaryServiceId,
  });

  Future<ServiceRecord?> findByAppointmentId(String appointmentId);

  Future<List<ServiceRecord>> findByClientId(String clientId);
}
