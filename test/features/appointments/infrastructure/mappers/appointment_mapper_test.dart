import 'package:flutter_test/flutter_test.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  group('AppointmentMapper', () {
    test('mapeia completedAt quando presente', () {
      final completedAt = DateTime.utc(2026, 7, 6, 18);
      final object = _appointmentObject(completedAt: completedAt);

      final appointment = mapper.toDomain(object);

      expect(appointment.completedAt, completedAt.toLocal());
      expect(appointment.status, AppointmentStatus.pending);
    });

    test('retorna completedAt nulo quando ausente', () {
      final object = _appointmentObject();

      final appointment = mapper.toDomain(object);

      expect(appointment.completedAt, isNull);
    });
  });
}

ParseObject _appointmentObject({DateTime? completedAt}) {
  final startAt = DateTime(2026, 7, 6, 10);
  final endAt = startAt.add(const Duration(hours: 1));
  final object = ParseObject('Appointment')
    ..objectId = 'appointment-1'
    ..set<ParseObject>('client', _pointer('Client', 'client-1'))
    ..set<ParseObject>(
      'professional',
      _pointer('Professional', 'professional-1'),
    )
    ..set<ParseObject>('salon', _pointer('Salon', 'salon-1'))
    ..set<ParseUser>('owner', ParseUser.forQuery()..objectId = 'owner-1')
    ..set<DateTime>('startAt', startAt)
    ..set<DateTime>('endAt', endAt)
    ..set<String>('status', 'pending')
    ..set<bool>('isActive', true);

  if (completedAt != null) {
    object.set<DateTime>('completedAt', completedAt);
  }

  return object;
}

ParseObject _pointer(String className, String objectId) {
  return ParseObject(className)..objectId = objectId;
}
