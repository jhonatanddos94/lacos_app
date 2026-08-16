/// Constrói deep links `https://wa.me/<numero>?text=<mensagem>`.
///
/// A normalização existe apenas para o link: nada aqui altera o telefone
/// persistido da cliente ou da configuração de suporte.
abstract final class WhatsAppUriBuilder {
  static const _host = 'wa.me';
  static const _brazilCountryCode = '55';

  /// Menor número nacional aceito: DDD + 8 dígitos.
  static const _minNationalLength = 10;

  /// Maior número nacional aceito: DDD + 9 dígitos.
  static const _maxNationalLength = 11;

  /// Limite de dígitos de um número E.164.
  static const _maxInternationalLength = 15;

  /// Devolve o número somente com dígitos e com DDI, ou `null` se for curto
  /// ou longo demais para ser um telefone real.
  static String? normalizePhone(String phone) {
    var digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('00')) digits = digits.substring(2);

    if (digits.length < _minNationalLength) return null;
    if (digits.length <= _maxNationalLength) {
      return '$_brazilCountryCode$digits';
    }
    if (digits.length > _maxInternationalLength) return null;

    return digits;
  }

  static bool isValidPhone(String phone) => normalizePhone(phone) != null;

  static Uri build({required String phone, required String message}) {
    final normalizedPhone = normalizePhone(phone);
    if (normalizedPhone == null) {
      throw ArgumentError.value(phone, 'phone', 'Informe um número válido.');
    }

    return Uri.https(_host, '/$normalizedPhone', {'text': message});
  }
}
