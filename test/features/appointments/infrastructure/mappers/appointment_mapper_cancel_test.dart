import 'package:flutter_test/flutter_test.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:lacos_app/features/appointments/domain/enums/appointment_canceled_by.dart';
import 'package:lacos_app/features/appointments/domain/enums/appointment_status.dart';
import 'package:lacos_app/features/appointments/infrastructure/mappers/appointment_mapper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await Parse().initialize(
      'test-app-id',
      'https://test.example.com',
      clientKey: 'test-client-key',
      appName: 'lacos_app_test',
      appPackageName: 'com.lacos.app.test',
      appVersion: '1.0.0',
      fileDirectory: '/tmp/lacos_app_test',
    );
  });

  const mapper = AppointmentMapper();

  group('AppointmentMapper cancellation', () {
    test('mapeia canceledAt, canceledBy e cancellationReason', () {
      final canceledAt = DateTime.utc(2026, 7, 7, 18);
      final object = _appointmentObject(
        status: 'canceled',
        canceledAt: canceledAt,
        canceledBy: 'client',
        cancellationReason: 'Cliente desistiu',
      );

      final appointment = mapper.toDomain(object);

      expect(appointment.canceledAt, canceledAt.toLocal());
      expect(appointment.canceledBy, AppointmentCanceledBy.client);
      expect(appointment.cancellationReason, 'Cliente desistiu');
      expect(appointment.status, AppointmentStatus.canceled);
    });

    test('canceledBy desconhecido retorna null', () {
      final object = _appointmentObject(canceledBy: 'unknown');

      final appointment = mapper.toDomain(object);

      expect(appointment.canceledBy, isNull);
    });

    test('applyCancellation salva campos de cancelamento', () {
      final object = _appointmentObject();
      final canceledAt = DateTime(2026, 7, 7, 15, 30);

      mapper.applyCancellation(
        object: object,
        canceledBy: AppointmentCanceledBy.salon,
        canceledAt: canceledAt,
        cancellationReason: 'Profissional indisponível',
      );

      expect(object.get<String>('status'), 'canceled');
      expect(object.get<bool>('isActive'), isTrue);
      expect(object.get<DateTime>('canceledAt'), canceledAt);
      expect(object.get<String>('canceledBy'), 'salon');
      expect(
        object.get<String>('cancellationReason'),
        'Profissional indisponível',
      );
    });

    test('applyCancellation não persiste motivo vazio', () {
      final object = _appointmentObject()
        ..set<String>('cancellationReason', 'anterior');

      mapper.applyCancellation(
        object: object,
        canceledBy: AppointmentCanceledBy.client,
        canceledAt: DateTime(2026, 7, 7, 15, 30),
        cancellationReason: '   ',
      );

      expect(object.get<String>('cancellationReason'), isNull);
    });
  });
}

ParseObject _appointmentObject({
  String status = 'pending',
  DateTime? canceledAt,
  String? canceledBy,
  String? cancellationReason,
}) {
  final startAt = DateTime(2026, 7, 7, 10);
  final endAt = startAt.add(const Duration(hours: 1));
  final object = ParseObject('Appointment')
    ..objectId = 'appointment-1'
    ..set<ParseObject>('client', _pointer('Client', 'client-1'))
    ..set<ParseObject>('professional', _pointer('Professional', 'professional-1'))
    ..set<ParseObject>('salon', _pointer('Salon', 'salon-1'))
    ..set<ParseUser>(
      'owner',
      ParseUser.forQuery()..objectId = 'owner-1',
    )
    ..set<DateTime>('startAt', startAt)
    ..set<DateTime>('endAt', endAt)
    ..set<String>('status', status)
    ..set<bool>('isActive', true);

  if (canceledAt != null) {
    object.set<DateTime>('canceledAt', canceledAt);
  }
  if (canceledBy != null) {
    object.set<String>('canceledBy', canceledBy);
  }
  if (cancellationReason != null) {
    object.set<String>('cancellationReason', cancellationReason);
  }

  return object;
}

ParseObject _pointer(String className, String objectId) {
  return ParseObject(className)..objectId = objectId;
}
