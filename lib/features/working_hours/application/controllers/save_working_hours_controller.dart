import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lacos_app/core/config/app_strings.dart';
import 'package:lacos_app/features/working_hours/application/models/working_hours_day_draft.dart';
import 'package:lacos_app/features/working_hours/domain/entities/professional_working_hours.dart';
import 'package:lacos_app/features/working_hours/domain/repositories/professional_working_hours_repository.dart';

class SaveWorkingHoursController
    extends StateNotifier<AsyncValue<List<ProfessionalWorkingHours>?>> {
  SaveWorkingHoursController(this._repository)
    : super(const AsyncData(null));

  final ProfessionalWorkingHoursRepository _repository;

  void reset() => state = const AsyncData(null);

  Future<List<ProfessionalWorkingHours>?> saveWeek({
    required String salonId,
    required String professionalId,
    required List<WorkingHoursDayDraft> drafts,
  }) async {
    if (state.isLoading) return null;

    state = const AsyncLoading();
    try {
      final now = DateTime.now();
      final week = WorkingHoursWeekFactory.toDomain(
        salonId: salonId,
        professionalId: professionalId,
        drafts: drafts,
        now: now,
      );

      final saved = await _repository.saveWeek(
        salonId: salonId,
        professionalId: professionalId,
        week: week,
      );
      state = AsyncData(saved);
      return saved;
    } on Object catch (error, stackTrace) {
      final friendlyError = FormatException(_resolveErrorMessage(error));
      state = AsyncError(friendlyError, stackTrace);
      return null;
    }
  }
}

String _resolveErrorMessage(Object error) {
  return switch (error) {
    FormatException(message: final message) => message,
    StateError(message: final message) when message.contains('sessão') =>
      message,
    StateError(message: final message) => message,
    _ => AppStrings.workingHoursSaveError,
  };
}
