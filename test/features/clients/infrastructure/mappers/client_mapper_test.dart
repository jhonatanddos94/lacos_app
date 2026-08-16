import 'package:flutter_test/flutter_test.dart';
import 'package:lacos_app/core/config/app_environment.dart';
import 'package:lacos_app/features/clients/infrastructure/mappers/client_mapper.dart';
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

  group('ClientMapper isFavorite', () {
    const mapper = ClientMapper();

    ParseObject clientObject({bool? isFavorite}) {
      final object = ParseObject('Client')
        ..objectId = 'client-1'
        ..set<String>('name', 'Maria')
        ..set<String>('phone', '11999990000')
        ..set<bool>('isActive', true);

      if (isFavorite != null) {
        object.set<bool>('isFavorite', isFavorite);
      }

      return object;
    }

    test('Q: isFavorite ausente = false', () {
      final client = mapper.toDomain(clientObject());
      expect(client.isFavorite, isFalse);
    });

    test('lê isFavorite true persistido', () {
      final client = mapper.toDomain(clientObject(isFavorite: true));
      expect(client.isFavorite, isTrue);
    });
  });
}
