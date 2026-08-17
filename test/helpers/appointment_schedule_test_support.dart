import 'package:lacos_app/features/appointments/application/services/appointment_schedule_validator.dart';
import 'package:lacos_app/features/appointments/domain/services/availability_engine.dart';
import 'package:lacos_app/features/professional/domain/entities/professional.dart';
import 'package:lacos_app/features/salon/domain/entities/salon.dart';
import 'package:lacos_app/features/salon/domain/repositories/salon_repository.dart';
import 'package:lacos_app/features/working_hours/domain/entities/professional_working_hours.dart';
import 'package:lacos_app/features/working_hours/domain/repositories/professional_working_hours_repository.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lacos_app/core/workspace/application/providers/workspace_providers.dart';
import 'package:lacos_app/core/workspace/domain/entities/workspace.dart';
import 'package:lacos_app/features/auth/domain/entities/authenticated_user.dart';
import 'package:lacos_app/features/working_hours/application/providers/working_hours_providers.dart';

const appointmentTestSalonId = 'salon-1';
const appointmentTestProfessionalId = 'professional-1';

Salon appointmentTestSalon({DateTime? now}) {
  final timestamp = now ?? DateTime(2026, 1, 1);
  return Salon(
    id: appointmentTestSalonId,
    name: 'Studio Teste',
    responsibleName: 'Leticia',
    isActive: true,
    createdAt: timestamp,
    updatedAt: timestamp,
  );
}

Professional appointmentTestProfessional({DateTime? now}) {
  final timestamp = now ?? DateTime(2026, 1, 1);
  return Professional(
    id: appointmentTestProfessionalId,
    name: 'Leticia',
    isActive: true,
    createdAt: timestamp,
    updatedAt: timestamp,
  );
}

AppointmentScheduleValidator buildAppointmentScheduleValidator({
  List<ProfessionalWorkingHours> configuredWeek = const [],
  Salon? salon,
  Professional? professional,
}) {
  return AppointmentScheduleValidator(
    salonRepository: _FakeSalonRepository(salon ?? appointmentTestSalon()),
    workingHoursRepository: _FakeWorkingHoursRepository(
      configuredWeek: configuredWeek,
      salonId: (salon ?? appointmentTestSalon()).id,
      professionalId: (professional ?? appointmentTestProfessional()).id,
    ),
    availabilityEngine: const AvailabilityEngine(),
  );
}

Override appointmentFormWorkspaceOverride({
  Salon? salon,
  Professional? professional,
}) {
  final resolvedSalon = salon ?? appointmentTestSalon();
  final resolvedProfessional = professional ?? appointmentTestProfessional();

  return workspaceProvider.overrideWith(
    (ref) async => Workspace(
      user: const AuthenticatedUser(
        id: 'user-test',
        email: 'test@lacos.app',
        isEmailVerified: true,
      ),
      salon: resolvedSalon,
      professional: resolvedProfessional,
    ),
  );
}

Override appointmentFormWorkingHoursOverride({
  List<ProfessionalWorkingHours> week = const [],
}) {
  return professionalWorkingHoursWeekProvider.overrideWith(
    (ref, key) async => week,
  );
}

List<ProfessionalWorkingHours> workingWeek({
  required String salonId,
  required String professionalId,
  required int weekday,
  required bool isWorking,
  int startMinutes = 7 * 60,
  int endMinutes = 20 * 60,
  DateTime? now,
}) {
  final timestamp = now ?? DateTime(2026, 1, 1);
  return [
    ProfessionalWorkingHours(
      id: 'hours-$weekday',
      salonId: salonId,
      professionalId: professionalId,
      weekday: weekday,
      isWorking: isWorking,
      startMinutes: startMinutes,
      endMinutes: endMinutes,
      createdAt: timestamp,
      updatedAt: timestamp,
    ),
  ];
}

class _FakeSalonRepository implements SalonRepository {
  _FakeSalonRepository(this.salon);

  final Salon salon;

  @override
  Future<Salon> create({
    required String name,
    required String responsibleName,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<Salon?> getCurrentSalon() async => salon;

  @override
  Future<Salon> update({
    required String salonId,
    required String name,
    String? phone,
    String? address,
    String? city,
    String? state,
  }) {
    throw UnimplementedError();
  }
}

class _FakeWorkingHoursRepository implements ProfessionalWorkingHoursRepository {
  _FakeWorkingHoursRepository({
    required List<ProfessionalWorkingHours> configuredWeek,
    required this.salonId,
    required this.professionalId,
  }) : _week = List<ProfessionalWorkingHours>.from(configuredWeek);

  final String salonId;
  final String professionalId;
  final List<ProfessionalWorkingHours> _week;

  @override
  Future<List<ProfessionalWorkingHours>> findWeek({
    required String salonId,
    required String professionalId,
  }) async {
    if (salonId != this.salonId || professionalId != this.professionalId) {
      return const [];
    }
    return List<ProfessionalWorkingHours>.from(_week);
  }

  @override
  Future<List<ProfessionalWorkingHours>> saveWeek({
    required String salonId,
    required String professionalId,
    required List<ProfessionalWorkingHours> week,
  }) async {
    throw UnimplementedError();
  }
}
