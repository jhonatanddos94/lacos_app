import 'package:flutter_test/flutter_test.dart';
import 'package:lacos_app/core/config/app_environment.dart';
import 'package:lacos_app/features/memories/domain/entities/client_memory.dart';
import 'package:lacos_app/features/memories/domain/enums/client_memory_priority.dart';
import 'package:lacos_app/features/memories/domain/enums/client_memory_type.dart';
import 'package:lacos_app/features/memories/infrastructure/mappers/client_memory_mapper.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  group('ClientMemoryMapper', () {
    const mapper = ClientMemoryMapper();

    ParseObject memoryObject({Map<String, dynamic> fields = const {}}) {
      final object = ParseObject('ClientMemory')
        ..objectId = 'memory-1'
        ..set<ParseObject>(
          'client',
          (ParseObject('Client')..objectId = 'client-1'),
        )
        ..set<ParseObject>(
          'salon',
          (ParseObject('Salon')..objectId = 'salon-1'),
        )
        ..set<ParseUser>(
          'owner',
          (ParseUser.forQuery()..objectId = 'owner-1'),
        )
        ..set<String>('content', 'Prefere café sem açúcar')
        ..set<bool>('isActive', true);

      fields.forEach((key, value) {
        object.set<dynamic>(key, value);
      });

      return object;
    }

    test('toDomain aplica defaults para registros legados', () {
      final memory = mapper.toDomain(memoryObject());

      expect(memory.type, ClientMemoryType.other);
      expect(memory.priority, ClientMemoryPriority.normal);
      expect(memory.isPinned, isFalse);
      expect(memory.isArchived, isFalse);
      expect(memory.lastMentionedAt, isNull);
    });

    test('toDomain mapeia type legado general para other', () {
      final memory = mapper.toDomain(
        memoryObject(fields: {'type': 'general'}),
      );

      expect(memory.type, ClientMemoryType.other);
    });

    test('toDomain mapeia type legado conversation para personal', () {
      final memory = mapper.toDomain(
        memoryObject(fields: {'type': 'conversation'}),
      );

      expect(memory.type, ClientMemoryType.personal);
    });

    test('toDomain lê campos oficiais persistidos como String', () {
      final memory = mapper.toDomain(
        memoryObject(
          fields: {
            'type': 'health_attention',
            'priority': 'high',
            'isPinned': true,
            'isArchived': false,
            'lastMentionedAt': DateTime(2026, 7, 10, 14),
          },
        ),
      );

      expect(memory.type, ClientMemoryType.healthAttention);
      expect(memory.priority, ClientMemoryPriority.high);
      expect(memory.isPinned, isTrue);
      expect(memory.lastMentionedAt, DateTime(2026, 7, 10, 14));
    });

    test('toDomain lê priority legado numérico', () {
      final fromOne = mapper.toDomain(
        memoryObject(fields: {'priority': 1}),
      );
      final fromTwo = mapper.toDomain(
        memoryObject(fields: {'priority': 2}),
      );

      expect(fromOne.priority, ClientMemoryPriority.high);
      expect(fromTwo.priority, ClientMemoryPriority.high);
    });

    test('applyDomainFields persiste campos oficiais como String', () {
      final object = ParseObject('ClientMemory');
      final memory = ClientMemory(
        clientId: 'client-1',
        salonId: 'salon-1',
        ownerId: 'owner-1',
        content: 'Gosta de conversar sobre viagens',
        type: ClientMemoryType.personal,
        priority: ClientMemoryPriority.high,
        isPinned: true,
        lastMentionedAt: DateTime(2026, 7, 10, 9),
        isActive: true,
      );

      mapper.applyDomainFields(object: object, memory: memory);

      expect(object.get<String>('type'), 'personal');
      expect(object.get<String>('priority'), 'high');
      expect(object.get<bool>('isPinned'), isTrue);
      expect(object.get<bool>('isArchived'), isFalse);
      expect(object.get<DateTime>('lastMentionedAt'), DateTime(2026, 7, 10, 9));
    });

    test('applyDomainFields persiste health_attention com snake_case', () {
      final object = ParseObject('ClientMemory');
      final memory = ClientMemory(
        clientId: 'client-1',
        salonId: 'salon-1',
        ownerId: 'owner-1',
        content: 'Alergia a produto X',
        type: ClientMemoryType.healthAttention,
        isActive: true,
      );

      mapper.applyDomainFields(object: object, memory: memory);

      expect(object.get<String>('type'), 'health_attention');
    });
  });
}
