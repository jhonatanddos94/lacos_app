import 'package:lacos_app/features/working_hours/domain/entities/professional_working_hours.dart';

abstract interface class ProfessionalWorkingHoursRepository {
  Future<List<ProfessionalWorkingHours>> findWeek({
    required String salonId,
    required String professionalId,
  });

  Future<List<ProfessionalWorkingHours>> saveWeek({
    required String salonId,
    required String professionalId,
    required List<ProfessionalWorkingHours> week,
  });
}
