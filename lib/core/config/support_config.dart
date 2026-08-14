class SupportConfig {
  const SupportConfig({
    required this.whatsappPhone,
    required this.whatsappInitialMessage,
  });

  static const current = SupportConfig(
    whatsappPhone: '5567999351830',
    whatsappInitialMessage: 'Olá! Preciso de ajuda com o aplicativo Laços.',
  );

  /// Número internacional somente com dígitos.
  final String whatsappPhone;
  final String whatsappInitialMessage;
}
