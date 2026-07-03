class PasswordValidator {
  const PasswordValidator();

  static const minimumLength = 6;

  String? call(String? value) {
    if (value == null || value.isEmpty) {
      return 'Informe sua senha.';
    }

    if (value.length < minimumLength) {
      return 'A senha deve possuir pelo menos 6 caracteres.';
    }

    return null;
  }
}
