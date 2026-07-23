import 'package:lacos_app/features/appointments/application/models/complete_appointment_params.dart';
import 'package:lacos_app/features/services/domain/entities/service.dart';

List<CompletedServiceParams> mapPlannedServicesToCompletedParams(
  List<Service> services,
) {
  return services
      .map((service) => CompletedServiceParams(serviceId: service.id))
      .toList(growable: false);
}
