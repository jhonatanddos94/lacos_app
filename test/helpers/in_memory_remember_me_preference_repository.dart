import 'package:lacos_app/features/auth/domain/repositories/remember_me_preference_repository.dart';

class InMemoryRememberMePreferenceRepository
    implements RememberMePreferenceRepository {
  InMemoryRememberMePreferenceRepository({this.value = false});

  bool value;
  int writeCalls = 0;

  @override
  Future<bool> read() async => value;

  @override
  Future<void> write(bool rememberMe) async {
    writeCalls++;
    value = rememberMe;
  }
}
