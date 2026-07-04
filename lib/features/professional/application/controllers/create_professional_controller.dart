import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lacos_app/features/professional/domain/entities/professional.dart';
import 'package:lacos_app/features/professional/domain/repositories/professional_repository.dart';

class CreateProfessionalController
    extends StateNotifier<AsyncValue<Professional?>> {
  CreateProfessionalController(this._repository) : super(const AsyncData(null));

  final ProfessionalRepository _repository;

  Future<Professional?> createProfessional({
    required String name,
    String? specialties,
  }) async {
    if (state.isLoading) return null;

    final professionalName = name.trim();
    final professionalSpecialties = specialties?.trim();

    if (professionalName.isEmpty) {
      return _fail('Informe seu nome profissional.');
    }

    state = const AsyncLoading();

    try {
      final professional = await _repository.create(
        name: professionalName,
        specialties: professionalSpecialties?.isEmpty == true
            ? null
            : professionalSpecialties,
      );
      state = AsyncData(professional);
      return professional;
    } on Object catch (error, stackTrace) {
      final friendlyError = FormatException(_resolveErrorMessage(error));
      state = AsyncError(friendlyError, stackTrace);
      return null;
    }
  }

  Professional? _fail(String message) {
    state = AsyncError(FormatException(message), StackTrace.current);
    return null;
  }
}

String _resolveErrorMessage(Object error) {
  return switch (error) {
    FormatException(message: final message) => message,
    StateError(message: final message) => message,
    _ => 'Não foi possível concluir seu perfil. Tente novamente.',
  };
}
