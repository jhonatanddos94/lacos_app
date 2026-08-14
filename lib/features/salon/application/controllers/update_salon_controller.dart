import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lacos_app/core/config/app_strings.dart';
import 'package:lacos_app/core/config/app_validation_messages.dart';
import 'package:lacos_app/core/formatters/client_form_formatters.dart';
import 'package:lacos_app/features/salon/domain/entities/salon.dart';
import 'package:lacos_app/features/salon/domain/repositories/salon_repository.dart';

class UpdateSalonController extends StateNotifier<AsyncValue<Salon?>> {
  UpdateSalonController(this._repository) : super(const AsyncData(null));

  final SalonRepository _repository;

  void reset() => state = const AsyncData(null);

  Future<Salon?> updateSalon({
    required String salonId,
    required String name,
    String? phone,
    String? address,
    String? city,
    String? stateCode,
  }) async {
    if (state.isLoading) return null;

    final trimmedId = salonId.trim();
    final trimmedName = name.trim();
    final normalizedPhone = digitsOnly(phone ?? '');
    final trimmedAddress = _nullableTrim(address);
    final trimmedCity = _nullableTrim(city);
    final normalizedState = _nullableTrim(stateCode)?.toUpperCase();

    if (trimmedId.isEmpty) {
      return _fail(AppStrings.salonUpdateError);
    }
    if (trimmedName.isEmpty) {
      return _fail(AppValidationMessages.salonNameRequired);
    }
    if (normalizedPhone.isNotEmpty &&
        (normalizedPhone.length < 10 || normalizedPhone.length > 11)) {
      return _fail(AppValidationMessages.clientPhoneInvalid);
    }

    state = const AsyncLoading();
    try {
      final salon = await _repository.update(
        salonId: trimmedId,
        name: trimmedName,
        phone: normalizedPhone.isEmpty ? null : normalizedPhone,
        address: trimmedAddress,
        city: trimmedCity,
        state: normalizedState,
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

String? _nullableTrim(String? value) {
  final trimmed = value?.trim();
  return trimmed == null || trimmed.isEmpty ? null : trimmed;
}

String _resolveErrorMessage(Object error) {
  return switch (error) {
    FormatException(message: final message) => message,
    StateError(message: final message) when message.contains('sessão') =>
      message,
    _ => AppStrings.salonUpdateError,
  };
}
