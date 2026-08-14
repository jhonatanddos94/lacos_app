import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:lacos_app/features/auth/infrastructure/repositories/shared_preferences_remember_me_preference_repository.dart';

void main() {
  late SharedPreferencesRememberMePreferenceRepository repository;

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    repository = SharedPreferencesRememberMePreferenceRepository();
  });

  test('A: default is false when the key is unset', () async {
    expect(await repository.read(), isFalse);
  });

  test('write then read persists only the boolean', () async {
    await repository.write(true);
    expect(await repository.read(), isTrue);

    await repository.write(false);
    expect(await repository.read(), isFalse);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getKeys(), {'auth.rememberMe'});
    expect(prefs.getBool('auth.rememberMe'), isFalse);
  });
}
