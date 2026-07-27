/// Feature flags de autenticação (build-time).
///
/// Ativação local:
/// `flutter run --dart-define=LACOS_USE_EXCHANGE_SESSION=true`
///
/// Padrão: OFF — fluxo legado com senha Parse derivável.
/// Não ativar em distribuição real antes da conclusão da T1.3.2.1.
abstract final class AuthFeatureFlags {
  /// Quando `true`, sincroniza sessão Parse via Cloud Function `exchangeSession`.
  /// Quando `false` (padrão), usa o fluxo legado.
  static const bool useExchangeSession = bool.fromEnvironment(
    'LACOS_USE_EXCHANGE_SESSION',
    defaultValue: false,
  );

  /// Nome sanitizado da estratégia ativa (para logs / telemetria).
  static String get authStrategyLabel =>
      useExchangeSession ? 'exchange' : 'legacy';
}
