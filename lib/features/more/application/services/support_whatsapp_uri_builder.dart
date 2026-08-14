abstract final class SupportWhatsAppUriBuilder {
  static Uri build({required String phone, required String message}) {
    final sanitizedPhone = phone.replaceAll(RegExp(r'\D'), '');
    if (sanitizedPhone.isEmpty) {
      throw ArgumentError.value(phone, 'phone', 'Informe um número válido.');
    }

    return Uri.https('wa.me', '/$sanitizedPhone', {'text': message});
  }
}
