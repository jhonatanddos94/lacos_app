import 'package:lacos_app/features/services/domain/entities/service.dart';

abstract interface class ServiceRepository {
  Future<List<Service>> findAll();

  Future<Service> create({
    required String name,
    required int durationMinutes,
    String? category,
    double? price,
    String? description,
  });

  Future<Service> update(Service service);

  Future<void> delete(String serviceId);
}
