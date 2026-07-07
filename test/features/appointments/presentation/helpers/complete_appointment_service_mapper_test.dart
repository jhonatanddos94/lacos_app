import 'package:flutter_test/flutter_test.dart';
import 'package:lacos_app/features/appointments/presentation/helpers/complete_appointment_service_mapper.dart';
import 'package:lacos_app/features/services/domain/entities/service.dart';

Service _service({required String id, required String name}) {
  final now = DateTime(2026, 7, 6);

  return Service(
    id: id,
    name: name,
    isActive: true,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  group('mapPlannedServicesToCompletedParams', () {
    test('copia serviceId e deixa finalAmount e notes nulos', () {
      final params = mapPlannedServicesToCompletedParams([
        _service(id: 'service-1', name: 'Corte'),
        _service(id: 'service-2', name: 'Escova'),
      ]);

      expect(params, hasLength(2));
      expect(params[0].serviceId, 'service-1');
      expect(params[0].finalAmount, isNull);
      expect(params[0].notes, isNull);
      expect(params[1].serviceId, 'service-2');
    });
  });
}
