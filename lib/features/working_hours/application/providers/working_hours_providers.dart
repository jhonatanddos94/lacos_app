import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lacos_app/core/workspace/application/providers/workspace_providers.dart';
import 'package:lacos_app/features/professional/application/providers/professional_providers.dart';
import 'package:lacos_app/features/salon/application/providers/salon_providers.dart';
import 'package:lacos_app/features/working_hours/application/controllers/save_working_hours_controller.dart';
import 'package:lacos_app/features/working_hours/domain/entities/professional_working_hours.dart';
import 'package:lacos_app/features/working_hours/domain/repositories/professional_working_hours_repository.dart';
import 'package:lacos_app/features/working_hours/infrastructure/repositories/parse_professional_working_hours_repository.dart';

typedef WorkingHoursScope = ({String salonId, String professionalId});

final professionalWorkingHoursRepositoryProvider =
    Provider<ProfessionalWorkingHoursRepository>((ref) {
      return ParseProfessionalWorkingHoursRepository(
        ref.watch(salonRepositoryProvider),
        ref.watch(professionalRepositoryProvider),
      );
    });

final workingHoursScopeProvider = Provider<WorkingHoursScope?>((ref) {
  final workspace = ref.watch(workspaceProvider).valueOrNull;
  final salon = workspace?.salon;
  final professional = workspace?.professional;
  if (salon == null || professional == null) {
    return null;
  }

  return (salonId: salon.id, professionalId: professional.id);
});

typedef ProfessionalWorkingHoursKey = ({String salonId, String professionalId});

final professionalWorkingHoursWeekProvider = FutureProvider.family<
    List<ProfessionalWorkingHours>,
    ProfessionalWorkingHoursKey>((ref, key) {
  return ref
      .watch(professionalWorkingHoursRepositoryProvider)
      .findWeek(
        salonId: key.salonId,
        professionalId: key.professionalId,
      );
});

final professionalWorkingHoursProvider =
    FutureProvider<List<ProfessionalWorkingHours>>((ref) async {
      final scope = ref.watch(workingHoursScopeProvider);
      if (scope == null) {
        return const [];
      }

      return ref.watch(
        professionalWorkingHoursWeekProvider(scope).future,
      );
    });

final saveWorkingHoursControllerProvider =
    StateNotifierProvider<
      SaveWorkingHoursController,
      AsyncValue<List<ProfessionalWorkingHours>?>
    >((ref) {
      return SaveWorkingHoursController(
        ref.watch(professionalWorkingHoursRepositoryProvider),
      );
    });
