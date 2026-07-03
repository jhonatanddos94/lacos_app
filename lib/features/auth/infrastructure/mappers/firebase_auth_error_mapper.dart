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
      _ => 'Não foi possível entrar. Tente novamente.',
    };
  }
}
