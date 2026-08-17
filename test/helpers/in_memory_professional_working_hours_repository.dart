import 'dart:async';

import 'package:lacos_app/features/working_hours/domain/entities/professional_working_hours.dart';
import 'package:lacos_app/features/working_hours/domain/repositories/professional_working_hours_repository.dart';
import 'package:lacos_app/features/working_hours/domain/services/working_hours_validator.dart';

class InMemoryProfessionalWorkingHoursRepository
    implements ProfessionalWorkingHoursRepository {
  InMemoryProfessionalWorkingHoursRepository();

  final Map<String, List<ProfessionalWorkingHours>> _weeksByScope = {};
  var findWeekCalls = 0;
  var saveWeekCalls = 0;
  Object? saveError;
  Completer<void>? saveGate;

  String _scopeKey(String salonId, String professionalId) {
    return '$salonId::$professionalId';
  }

  @override
  Future<List<ProfessionalWorkingHours>> findWeek({
    required String salonId,
    required String professionalId,
  }) async {
    findWeekCalls++;
    return List<ProfessionalWorkingHours>.from(
      _weeksByScope[_scopeKey(salonId, professionalId)] ?? const [],
    );
  }

  @override
  Future<List<ProfessionalWorkingHours>> saveWeek({
    required String salonId,
    required String professionalId,
    required List<ProfessionalWorkingHours> week,
  }) async {
    saveWeekCalls++;
    if (saveGate != null) {
      await saveGate!.future;
    }
    if (saveError != null) {
      throw saveError!;
    }

    final validationError = WorkingHoursValidator.validateWeek(week);
    if (validationError != null) {
      throw FormatException(validationError);
    }

    final now = DateTime.now();
    final saved = week
        .map(
          (day) => day.copyWith(
            id: day.id.isEmpty ? 'saved-${day.weekday}' : day.id,
            salonId: salonId,
            professionalId: professionalId,
            updatedAt: now,
            createdAt: day.createdAt,
          ),
        )
        .toList(growable: false);

    _weeksByScope[_scopeKey(salonId, professionalId)] = saved;
    return saved;
  }
}
