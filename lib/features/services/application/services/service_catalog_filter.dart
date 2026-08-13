import 'package:lacos_app/features/services/domain/entities/service.dart';

List<Service> filterServicesByName(List<Service> services, String query) {
  final normalized = query.trim().toLowerCase();
  if (normalized.isEmpty) {
    return List<Service>.unmodifiable(services);
  }

  return services
      .where((service) => service.name.toLowerCase().contains(normalized))
      .toList(growable: false);
}
