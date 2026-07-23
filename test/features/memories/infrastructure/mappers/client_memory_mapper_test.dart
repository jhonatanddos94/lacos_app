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

    test('toDomain aplica defaults para registros legados', () {
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

      final memory = mapper.toDomain(object);

      expect(memory.type, ClientMemoryType.general);
      expect(memory.priority, ClientMemoryPriority.normal);
      expect(memory.isPinned, isFalse);
      expect(memory.isArchived, isFalse);
      expect(memory.lastMentionedAt, isNull);
    });

    test('toDomain lê campos oficiais persistidos', () {
      final object = ParseObject('ClientMemory')
        ..objectId = 'memory-2'
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
        ..set<String>('content', 'Vai casar em novembro')
        ..set<String>('type', 'personal')
        ..set<int>('priority', 2)
        ..set<bool>('isPinned', true)
        ..set<bool>('isArchived', false)
        ..set<bool>('isActive', true)
        ..set<DateTime>('lastMentionedAt', DateTime(2026, 7, 10, 14));

      final memory = mapper.toDomain(object);

      expect(memory.type, ClientMemoryType.personal);
      expect(memory.priority, ClientMemoryPriority.critical);
      expect(memory.isPinned, isTrue);
      expect(memory.lastMentionedAt, DateTime(2026, 7, 10, 14));
    });

    test('applyDomainFields persiste campos oficiais', () {
      final object = ParseObject('ClientMemory');
      final memory = ClientMemory(
        clientId: 'client-1',
        salonId: 'salon-1',
        ownerId: 'owner-1',
        content: 'Gosta de conversar sobre viagens',
        type: ClientMemoryType.conversation,
        priority: ClientMemoryPriority.high,
        isPinned: true,
        lastMentionedAt: DateTime(2026, 7, 10, 9),
        isActive: true,
      );

      mapper.applyDomainFields(object: object, memory: memory);

      expect(object.get<String>('type'), 'conversation');
      expect(object.get<int>('priority'), 1);
      expect(object.get<bool>('isPinned'), isTrue);
      expect(object.get<bool>('isArchived'), isFalse);
      expect(object.get<DateTime>('lastMentionedAt'), DateTime(2026, 7, 10, 9));
    });
  });
}
