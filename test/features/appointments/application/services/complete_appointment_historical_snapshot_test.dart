import 'package:flutter_test/flutter_test.dart';
import 'package:lacos_app/features/appointments/application/models/complete_appointment_params.dart';
import 'package:lacos_app/features/appointments/application/services/complete_appointment_historical_snapshot.dart';
import 'package:lacos_app/features/appointments/domain/entities/appointment_service.dart';
import 'package:lacos_app/features/services/domain/entities/service.dart';

void main() {
  group('CompleteAppointmentHistoricalSnapshot', () {
    final stamp = DateTime(2026, 1, 1);

    final catalog = [
      Service(
        id: 'service-1',
        name: 'Corte feminino',
        durationMinutes: 60,
        price: 80,
        isActive: true,
        createdAt: stamp,
        updatedAt: stamp,
      ),
      Service(
        id: 'service-2',
        name: 'Hidratação',
        durationMinutes: 45,
        price: 100,
        isActive: true,
        createdAt: stamp,
        updatedAt: stamp,
      ),
    ];

    final bookingLines = [
      AppointmentService(
        id: 'as-1',
        appointmentId: 'appointment-1',
        serviceId: 'service-1',
        salonId: 'salon-1',
        ownerId: 'owner-1',
        priceAtBooking: 80,
        durationMinutesAtBooking: 60,
        displayOrder: 0,
        isActive: true,
        createdAt: stamp,
        updatedAt: stamp,
      ),
      AppointmentService(
        id: 'as-2',
        appointmentId: 'appointment-1',
        serviceId: 'service-2',
        salonId: 'salon-1',
        ownerId: 'owner-1',
        priceAtBooking: 100,
        durationMinutesAtBooking: 45,
        displayOrder: 1,
        isActive: true,
        createdAt: stamp,
        updatedAt: stamp,
      ),
    ];

    test('preenche procedureSummary e finalAmount quando ausentes', () {
      final enriched = CompleteAppointmentHistoricalSnapshot.enrich(
        params: const CompleteAppointmentParams(
          appointmentId: 'appointment-1',
          services: [
            CompletedServiceParams(serviceId: 'service-1'),
            CompletedServiceParams(serviceId: 'service-2'),
          ],
        ),
        appointmentServices: bookingLines,
        catalogServices: catalog,
      );

      expect(enriched.procedureSummary, 'Corte feminino + Hidratação');
      expect(enriched.finalAmount, 180);
      expect(enriched.services.map((s) => s.finalAmount), [80.0, 100.0]);
    });

    test('preserva procedureSummary e finalAmount explícitos', () {
      final enriched = CompleteAppointmentHistoricalSnapshot.enrich(
        params: const CompleteAppointmentParams(
          appointmentId: 'appointment-1',
          procedureSummary: 'Resumo custom',
          finalAmount: 50,
          services: [
            CompletedServiceParams(serviceId: 'service-1', finalAmount: 50),
          ],
        ),
        appointmentServices: bookingLines,
        catalogServices: catalog,
      );

      expect(enriched.procedureSummary, 'Resumo custom');
      expect(enriched.finalAmount, 50);
      expect(enriched.services.single.finalAmount, 50);
    });

    test('não usa preço atual do catálogo quando booking tem preço', () {
      final expensiveCatalog = [
        Service(
          id: 'service-1',
          name: 'Corte feminino',
          durationMinutes: 90,
          price: 999,
          isActive: true,
          createdAt: stamp,
          updatedAt: stamp,
        ),
      ];

      final enriched = CompleteAppointmentHistoricalSnapshot.enrich(
        params: const CompleteAppointmentParams(
          appointmentId: 'appointment-1',
          services: [CompletedServiceParams(serviceId: 'service-1')],
        ),
        appointmentServices: [bookingLines.first],
        catalogServices: expensiveCatalog,
      );

      expect(enriched.finalAmount, 80);
      expect(enriched.services.single.finalAmount, 80);
    });
  });
}
