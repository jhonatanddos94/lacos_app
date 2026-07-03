class EmailValidator {
  const EmailValidator();

  static final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  String? call(String? value) {
    final email = value?.trim() ?? '';

    if (email.isEmpty) {
      return 'Informe seu e-mail.';
    }

    if (!_emailPattern.hasMatch(email)) {
      return 'Digite um e-mail válido.';
    }

    return null;
  }
}
