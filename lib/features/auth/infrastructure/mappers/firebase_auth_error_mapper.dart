class FirebaseAuthErrorMapper {
  const FirebaseAuthErrorMapper();

  String toMessage(String code) {
    return switch (code) {
      'invalid-credential' => 'E-mail ou senha inválidos.',
      'user-not-found' => 'Nenhuma conta encontrada para este e-mail.',
      'wrong-password' => 'Senha incorreta.',
      'too-many-requests' =>
        'Muitas tentativas. Tente novamente em alguns minutos.',
      'network-request-failed' => 'Verifique sua conexão com a internet.',
      'user-disabled' => 'Esta conta foi desativada.',
      'email-already-in-use' => 'Este e-mail já está cadastrado.',
      'weak-password' => 'A senha deve possuir pelo menos 6 caracteres.',
      'requires-recent-login' => 'Sua sessão expirou. Entre novamente.',
      _ => 'Não foi possível entrar. Tente novamente.',
    };
  }
}
