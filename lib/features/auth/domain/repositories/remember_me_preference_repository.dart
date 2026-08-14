/// Persists only the "Lembrar-me" boolean. Never credentials or tokens.
abstract interface class RememberMePreferenceRepository {
  /// Default when unset: `false` (do not restore on next launch).
  Future<bool> read();

  Future<void> write(bool rememberMe);
}
