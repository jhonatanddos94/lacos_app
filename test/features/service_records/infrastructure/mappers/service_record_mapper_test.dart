import 'package:flutter_test/flutter_test.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:lacos_app/core/config/app_environment.dart';
import 'package:lacos_app/features/service_records/domain/entities/service_record.dart';
import 'package:lacos_app/features/service_records/infrastructure/mappers/service_record_mapper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await Parse().initialize(
      AppEnvironment.parseApplicationId,
      AppEnvironment.parseServerUrl,
      clientKey: AppEnvironment.parseClientKey,
      autoSendSessionId: true,
      appName: 'lacos_app_test',
      appPackageName: 'com.lacos.app.test',
      appVersion: '1.0.0',
      fileDirectory: '/tmp/lacos_app_test',
    );
  });

  const mapper = ServiceRecordMapper();

  group('ServiceRecordMapper.toDomain', () {
    test('mapeia campos novos corretamente', () {
      final serviceDate = DateTime.utc(2026, 7, 6, 15, 30);
      final object = _parseServiceRecord(
        id: 'record-1',
        fields: {
          'appointment': _pointer('Appointment', 'appointment-1'),
          'client': _pointer('Client', 'client-1'),
          'professional': _pointer('Professional', 'professional-1'),
          'salon': _pointer('Salon', 'salon-1'),
          'owner': (ParseUser.forQuery()..objectId = 'owner-1'),
          'serviceDate': serviceDate,
          'procedureSummary': 'Corte e hidratação',
          'technicalNotes': 'Observação técnica geral',
          'result': 'Cliente satisfeita',
          'finalAmount': 180.5,
          'productsUsed': 'Máscara hidratante',
          'isActive': true,
        },
      );

      final record = mapper.toDomain(object);

      expect(record.id, 'record-1');
      expect(record.appointmentId, 'appointment-1');
      expect(record.clientId, 'client-1');
      expect(record.professionalId, 'professional-1');
      expect(record.salonId, 'salon-1');
      expect(record.ownerId, 'owner-1');
      expect(record.serviceDate, serviceDate.toLocal());
      expect(record.procedureSummary, 'Corte e hidratação');
      expect(record.technicalNotes, 'Observação técnica geral');
      expect(record.result, 'Cliente satisfeita');
      expect(record.finalAmount, 180.5);
      expect(record.productsUsed, 'Máscara hidratante');
      expect(record.isActive, isTrue);
    });

    test('usa performedProcedure como fallback de procedureSummary', () {
      final object = _parseServiceRecord(
        id: 'record-2',
        fields: {
          'client': _pointer('Client', 'client-1'),
          'professional': _pointer('Professional', 'professional-1'),
          'salon': _pointer('Salon', 'salon-1'),
          'owner': (ParseUser.forQuery()..objectId = 'owner-1'),
          'performedProcedure': 'Escova modelada',
        },
      );

      final record = mapper.toDomain(object);

      expect(record.procedureSummary, 'Escova modelada');
    });

    test('prioriza procedureSummary sobre performedProcedure', () {
      final object = _parseServiceRecord(
        id: 'record-3',
        fields: {
          'client': _pointer('Client', 'client-1'),
          'professional': _pointer('Professional', 'professional-1'),
          'salon': _pointer('Salon', 'salon-1'),
          'owner': (ParseUser.forQuery()..objectId = 'owner-1'),
          'procedureSummary': 'Coloração',
          'performedProcedure': 'Escova',
        },
      );

      final record = mapper.toDomain(object);

      expect(record.procedureSummary, 'Coloração');
    });

    test('usa chargedAmount como fallback de finalAmount', () {
      final object = _parseServiceRecord(
        id: 'record-4',
        fields: {
          'client': _pointer('Client', 'client-1'),
          'professional': _pointer('Professional', 'professional-1'),
          'salon': _pointer('Salon', 'salon-1'),
          'owner': (ParseUser.forQuery()..objectId = 'owner-1'),
          'chargedAmount': 250,
        },
      );

      final record = mapper.toDomain(object);

      expect(record.finalAmount, 250);
    });

    test('prioriza finalAmount sobre chargedAmount', () {
      final object = _parseServiceRecord(
        id: 'record-5',
        fields: {
          'client': _pointer('Client', 'client-1'),
          'professional': _pointer('Professional', 'professional-1'),
          'salon': _pointer('Salon', 'salon-1'),
          'owner': (ParseUser.forQuery()..objectId = 'owner-1'),
          'finalAmount': 300,
          'chargedAmount': 250,
        },
      );

      final record = mapper.toDomain(object);

      expect(record.finalAmount, 300);
    });
  });

  group('ServiceRecordMapper.applyToParse', () {
    test('escreve apenas campos novos', () {
      final object = ParseObject('ServiceRecord');
      final serviceDate = DateTime(2026, 7, 6, 10);
      final owner = ParseUser.forQuery()..objectId = 'owner-1';

      mapper.applyToParse(
        object: object,
        record: ServiceRecord(
          id: '',
          appointmentId: 'appointment-1',
          clientId: 'client-1',
          professionalId: 'professional-1',
          salonId: 'salon-1',
          ownerId: 'owner-1',
          serviceDate: serviceDate,
          procedureSummary: 'Corte',
          technicalNotes: 'Notas técnicas',
          result: 'Resultado positivo',
          finalAmount: 120,
          productsUsed: 'Shampoo profissional',
          isActive: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        salonId: 'salon-1',
        owner: owner,
      );

      expect(object.get<ParseObject>('appointment')?.objectId, 'appointment-1');
      expect(object.get<ParseObject>('client')?.objectId, 'client-1');
      expect(object.get<ParseObject>('professional')?.objectId, 'professional-1');
      expect(object.get<ParseObject>('salon')?.objectId, 'salon-1');
      expect(object.get<ParseUser>('owner')?.objectId, 'owner-1');
      expect(object.get<DateTime>('serviceDate'), serviceDate);
      expect(object.get<String>('procedureSummary'), 'Corte');
      expect(object.get<String>('technicalNotes'), 'Notas técnicas');
      expect(object.get<String>('result'), 'Resultado positivo');
      expect(object.get<num>('finalAmount'), 120);
      expect(object.get<String>('productsUsed'), 'Shampoo profissional');
      expect(object.get<bool>('isActive'), isTrue);
    });

    test('não escreve performedProcedure nem chargedAmount', () {
      final object = ParseObject('ServiceRecord');
      final owner = ParseUser.forQuery()..objectId = 'owner-1';

      mapper.applyToParse(
        object: object,
        record: ServiceRecord(
          id: '',
          clientId: 'client-1',
          professionalId: 'professional-1',
          salonId: 'salon-1',
          ownerId: 'owner-1',
          procedureSummary: 'Hidratação',
          finalAmount: 90,
          isActive: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        salonId: 'salon-1',
        owner: owner,
      );

      expect(object.get<String>('performedProcedure'), isNull);
      expect(object.get<num>('chargedAmount'), isNull);
      expect(object.get<ParseObject>('service'), isNull);
    });

    test('escreve service legado quando legacyPrimaryServiceId é informado', () {
      final object = ParseObject('ServiceRecord');
      final owner = ParseUser.forQuery()..objectId = 'owner-1';

      mapper.applyToParse(
        object: object,
        record: ServiceRecord(
          id: '',
          clientId: 'client-1',
          professionalId: 'professional-1',
          salonId: 'salon-1',
          ownerId: 'owner-1',
          isActive: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        salonId: 'salon-1',
        owner: owner,
        legacyPrimaryServiceId: 'service-1',
      );

      expect(object.get<ParseObject>('service')?.objectId, 'service-1');
    });

    test('remove appointment quando appointmentId é nulo', () {
      final object = ParseObject('ServiceRecord')
        ..set<ParseObject>(
          'appointment',
          _pointer('Appointment', 'old-appointment'),
        );
      final owner = ParseUser.forQuery()..objectId = 'owner-1';

      mapper.applyToParse(
        object: object,
        record: ServiceRecord(
          id: '',
          clientId: 'client-1',
          professionalId: 'professional-1',
          salonId: 'salon-1',
          ownerId: 'owner-1',
          isActive: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        salonId: 'salon-1',
        owner: owner,
      );

      expect(object.get<ParseObject>('appointment'), isNull);
    });
  });
}

ParseObject _parseServiceRecord({
  required String id,
  required Map<String, dynamic> fields,
}) {
  final object = ParseObject('ServiceRecord')..objectId = id;

  for (final entry in fields.entries) {
    object.set<dynamic>(entry.key, entry.value);
  }

  return object;
}

ParseObject _pointer(String className, String objectId) {
  return ParseObject(className)..objectId = objectId;
}
