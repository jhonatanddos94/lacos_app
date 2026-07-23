import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lacos_app/core/config/app_strings.dart';
import 'package:lacos_app/core/config/app_validation_messages.dart';
import 'package:lacos_app/features/services/domain/entities/service.dart';
import 'package:lacos_app/features/services/domain/repositories/service_repository.dart';

class ServiceFormController extends StateNotifier<AsyncValue<Service?>> {
  ServiceFormController(this._repository) : super(const AsyncData(null));

  final ServiceRepository _repository;

  void reset() {
    state = const AsyncData(null);
  }

  Future<Service?> save({
    Service? initialService,
    required String name,
    required int? durationMinutes,
    String? category,
    double? price,
    String? description,
  }) async {
    if (state.isLoading) return null;

    final serviceName = name.trim();
    final normalizedCategory = category?.trim();
    final normalizedDescription = description?.trim();

    if (serviceName.isEmpty) {
      return _fail(AppValidationMessages.serviceNameRequired);
    }

    if (durationMinutes == null || durationMinutes <= 0) {
      return _fail(AppValidationMessages.serviceDurationRequired);
    }

    state = const AsyncLoading();

    try {
      final resolvedCategory = normalizedCategory?.isEmpty == true
          ? null
          : normalizedCategory;
      final resolvedDescription = normalizedDescription?.isEmpty == true
          ? null
          : normalizedDescription;

      if (initialService != null) {
        final updatedService = Service(
          id: initialService.id,
          name: serviceName,
          category: resolvedCategory,
          durationMinutes: durationMinutes,
          price: price,
          description: resolvedDescription,
          isActive: initialService.isActive,
          createdAt: initialService.createdAt,
          updatedAt: initialService.updatedAt,
        );
        final service = await _repository.update(updatedService);
        state = AsyncData(service);
        return service;
      }

      final service = await _repository.create(
        name: serviceName,
        durationMinutes: durationMinutes,
        category: resolvedCategory,
        price: price,
        description: resolvedDescription,
      );
      state = AsyncData(service);
      return service;
    } on Object catch (error, stackTrace) {
      final friendlyError = FormatException(
        _resolveSaveErrorMessage(error, isUpdate: initialService != null),
      );
      state = AsyncError(friendlyError, stackTrace);
      return null;
    }
  }

  Future<bool> delete(Service service) async {
    if (state.isLoading) return false;

    state = const AsyncLoading();

    try {
      await _repository.delete(service.id);
      state = const AsyncData(null);
      return true;
    } on Object catch (error, stackTrace) {
      final friendlyError = FormatException(_resolveDeleteErrorMessage(error));
      state = AsyncError(friendlyError, stackTrace);
      return false;
    }
  }

  Service? _fail(String message) {
    state = AsyncError(FormatException(message), StackTrace.current);
    return null;
  }
}

String _resolveSaveErrorMessage(Object error, {required bool isUpdate}) {
  return switch (error) {
    FormatException(message: final message) => message,
    StateError(message: final message) => message,
    _ => isUpdate ? AppStrings.serviceUpdateError : AppStrings.serviceSaveError,
  };
}

String _resolveDeleteErrorMessage(Object error) {
  return switch (error) {
    FormatException(message: final message) => message,
    StateError(message: final message) => message,
    _ => AppStrings.serviceDeleteError,
  };
}
