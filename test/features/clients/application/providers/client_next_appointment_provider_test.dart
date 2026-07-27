import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lacos_app/features/appointments/domain/enums/appointment_operational_state.dart';
import 'package:lacos_app/features/appointments/domain/enums/appointment_status.dart';
import 'package:lacos_app/features/clients/application/models/client_next_appointment_preview.dart';
import 'package:lacos_app/features/clients/application/providers/client_next_appointment_providers.dart';

void main() {
  group('clientNextAppointmentProvider', () {
    test('retorna preview correto para clientId', () async {
      final startAt = DateTime(2026, 7, 14, 16);
      final endAt = startAt.add(const Duration(hours: 1));
      final preview = ClientNextAppointmentPreview(
        appointmentId: 'appointment-1',
        clientId: 'client-1',
        clientName: 'Ana',
        professionalName: 'Maria',
        servicesSummary: 'Corte',
        startAt: startAt,
        endAt: endAt,
        status: AppointmentStatus.confirmed,
        operationalState: AppointmentOperationalState.upcoming,
      );

      final container = ProviderContainer(
        overrides: [
          clientNextAppointmentProvider('client-1').overrideWith((ref) async {
            return preview;
          }),
        ],
      );
      addTearDown(container.dispose);

      final result = await container.read(
        clientNextAppointmentProvider('client-1').future,
      );

      expect(result?.appointmentId, 'appointment-1');
    });

    test('retorna null para clientId vazio', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final result = await container.read(
        clientNextAppointmentProvider('').future,
      );

      expect(result, isNull);
    });

    test('propaga erro do loader', () async {
      final container = ProviderContainer(
        overrides: [
          clientNextAppointmentProvider('client-1').overrideWith((ref) async {
            throw StateError('Falha simulada');
          }),
        ],
      );
      addTearDown(container.dispose);

      expect(
        container.read(clientNextAppointmentProvider('client-1').future),
        throwsA(isA<StateError>()),
      );
    });
  });
}
