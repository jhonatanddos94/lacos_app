abstract final class AppValidationMessages {
  static const String requiredField = 'Campo obrigatório.';
  static const String unexpectedError = 'Ocorreu um erro inesperado.';
  static const String tryAgain = 'Tente novamente.';

  static const String clientNameRequired = 'Informe o nome da cliente.';
  static const String clientPhoneRequired = 'Informe o telefone da cliente.';
  static const String clientPhoneInvalid = 'Informe um telefone válido.';
  static const String clientBirthDateInvalid =
      'Informe uma data de nascimento válida.';
  static const String clientInstagramInvalid = 'Informe um Instagram válido.';
  static const String clientPhotoPickerUnavailable =
      'Não foi possível abrir a câmera ou galeria. Feche e abra o app novamente.';
  static const String clientPhotoUploadFailed =
      'Não foi possível salvar a foto. Tente novamente.';

  static const String salonNameRequired = 'Informe o nome do salão.';
  static const String ownerNameRequired = 'Informe o nome da proprietária.';

  static const String professionalNameRequired =
      'Informe o nome da profissional.';

  static const String serviceNameRequired = 'Informe o nome do serviço.';
  static const String serviceDurationRequired = 'Informe a duração do serviço.';

  static const String memoryTitleRequired = 'Informe um título para a memória.';

  static const String workingHoursInvalidWeekday = 'Dia da semana inválido.';
  static const String workingHoursInvalidGranularity =
      'Use horários em intervalos de 15 minutos.';
  static const String workingHoursOutOfRange =
      'Informe horários entre 00:00 e 23:59.';
  static const String workingHoursInvalidRange =
      'O horário inicial deve ser anterior ao final.';
  static const String workingHoursDurationTooShort =
      'A janela de atendimento deve ter pelo menos 15 minutos.';
  static const String workingHoursIncompleteWeek =
      'Informe todos os dias da semana.';
  static const String workingHoursDuplicateWeekday =
      'Há dias da semana duplicados.';
}
