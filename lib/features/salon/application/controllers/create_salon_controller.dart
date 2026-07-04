import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lacos_app/features/salon/domain/entities/salon.dart';
import 'package:lacos_app/features/salon/domain/repositories/salon_repository.dart';

class CreateSalonController extends StateNotifier<AsyncValue<Salon?>> {
  CreateSalonController(this._repository) : super(const AsyncData(null));

  final SalonRepository _repository;

  Future<Salon?> createSalon({
    required String name,
    required String responsibleName,
  }) async {
    if (state.isLoading) return null;

    final salonName = name.trim();
    final professionalName = responsibleName.trim();

    if (salonName.isEmpty) {
      return _fail('Informe o nome do salão.');
    }

    if (professionalName.isEmpty) {
      return _fail('Informe o nome da profissional responsável.');
    }

    state = const AsyncLoading();

    try {
      final salon = await _repository.create(
        name: salonName,
        responsibleName: professionalName,
      );
      state = AsyncData(salon);
      return salon;
    } on Object catch (error, stackTrace) {
      final friendlyError = FormatException(_resolveErrorMessage(error));
      state = AsyncError(friendlyError, stackTrace);
      return null;
    }
  }

  Salon? _fail(String message) {
    state = AsyncError(FormatException(message), StackTrace.current);
    return null;
  }
}

String _resolveErrorMessage(Object error) {
  return switch (error) {
    FormatException(message: final message) => message,
    StateError(message: final message) => message,
    _ => 'Não foi possível criar seu salão. Tente novamente.',
  };
}
