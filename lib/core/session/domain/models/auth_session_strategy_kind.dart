/// Estratégia de sincronização de sessão Parse.
enum AuthSessionStrategyKind {
  /// @Deprecated — login Parse com senha derivável. Mantido para dual-run.
  legacy,

  /// Firebase ID Token → Cloud Code `exchangeSession` → sessão Parse.
  exchange,
}

extension AuthSessionStrategyKindLabel on AuthSessionStrategyKind {
  String get telemetryLabel => switch (this) {
    AuthSessionStrategyKind.legacy => 'legacy',
    AuthSessionStrategyKind.exchange => 'exchange',
  };
}
