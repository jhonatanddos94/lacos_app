import 'package:shared_preferences/shared_preferences.dart';

import 'package:lacos_app/features/auth/domain/repositories/remember_me_preference_repository.dart';

class SharedPreferencesRememberMePreferenceRepository
    implements RememberMePreferenceRepository {
  SharedPreferencesRememberMePreferenceRepository({
    Future<SharedPreferences> Function()? preferences,
  }) : _preferences = preferences ?? SharedPreferences.getInstance;

  static const key = 'auth.rememberMe';

  final Future<SharedPreferences> Function() _preferences;

  @override
  Future<bool> read() async {
    final prefs = await _preferences();
    return prefs.getBool(key) ?? false;
  }

  @override
  Future<void> write(bool rememberMe) async {
    final prefs = await _preferences();
    await prefs.setBool(key, rememberMe);
  }
}
