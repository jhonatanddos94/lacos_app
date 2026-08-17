import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lacos_app/features/agenda/application/agenda_day.dart';
import 'package:lacos_app/features/appointments/application/controllers/cancel_appointment_controller.dart';
import 'package:lacos_app/features/appointments/application/controllers/complete_appointment_controller.dart';
import 'package:lacos_app/features/appointments/application/controllers/create_appointment_controller.dart';
import 'package:lacos_app/features/appointments/application/controllers/update_appointment_controller.dart';
import 'package:lacos_app/features/appointments/presentation/controllers/appointment_memory_usage_controller.dart';
import 'package:lacos_app/features/memories/application/memory_providers.dart';
import 'package:lacos_app/features/appointments/application/models/cancel_appointment_state.dart';
import 'package:lacos_app/features/appointments/application/models/complete_appointment_state.dart';
import 'package:lacos_app/features/appointments/application/models/created_appointment.dart';
import 'package:lacos_app/features/appointments/application/models/updated_appointment.dart';
import 'package:lacos_app/features/appointments/application/services/appointment_schedule_validator.dart';
import 'package:lacos_app/features/appointments/application/use_cases/cancel_appointment_use_case.dart';
import 'package:lacos_app/features/appointments/application/use_cases/complete_appointment_use_case.dart';
import 'package:lacos_app/features/appointments/application/use_cases/create_appointment_use_case.dart';
import 'package:lacos_app/features/appointments/application/use_cases/update_appointment_use_case.dart';
import 'package:lacos_app/features/appointments/domain/entities/appointment.dart';
import 'package:lacos_app/features/appointments/domain/entities/appointment_service.dart';
import 'package:lacos_app/features/appointments/domain/repositories/appointment_repository.dart';
import 'package:lacos_app/features/appointments/domain/repositories/appointment_service_repository.dart';
import 'package:lacos_app/features/appointments/domain/services/availability_engine.dart';
import 'package:lacos_app/features/appointments/infrastructure/repositories/parse_appointment_repository.dart';
import 'package:lacos_app/features/appointments/infrastructure/repositories/parse_appointment_service_repository.dart';
import 'package:lacos_app/features/salon/application/providers/salon_providers.dart';
import 'package:lacos_app/features/service_records/application/providers/service_record_providers.dart';
import 'package:lacos_app/features/service_records/application/providers/service_record_service_providers.dart';
import 'package:lacos_app/features/services/application/providers/service_providers.dart';
import 'package:lacos_app/features/working_hours/application/providers/working_hours_providers.dart';

final availabilityEngineProvider = Provider<AvailabilityEngine>((ref) {
  return const AvailabilityEngine();
});

final appointmentScheduleValidatorProvider =
    Provider<AppointmentScheduleValidator>((ref) {
      return AppointmentScheduleValidator(
        salonRepository: ref.watch(salonRepositoryProvider),
        workingHoursRepository: ref.watch(
          professionalWorkingHoursRepositoryProvider,
        ),
        availabilityEngine: ref.watch(availabilityEngineProvider),
      );
    });

final createAppointmentUseCaseProvider = Provider<CreateAppointmentUseCase>((
  ref,
) {
  return CreateAppointmentUseCase(
    appointmentRepository: ref.watch(appointmentRepositoryProvider),
    appointmentServiceRepository: ref.watch(
      appointmentServiceRepositoryProvider,
    ),
    scheduleValidator: ref.watch(appointmentScheduleValidatorProvider),
  );
});

final createAppointmentControllerProvider =
    StateNotifierProvider<
      CreateAppointmentController,
      AsyncValue<CreatedAppointment?>
    >((ref) {
      final useCase = ref.watch(createAppointmentUseCaseProvider);
      return CreateAppointmentController(useCase);
    });

final updateAppointmentUseCaseProvider = Provider<UpdateAppointmentUseCase>((
  ref,
) {
  return UpdateAppointmentUseCase(
    appointmentRepository: ref.watch(appointmentRepositoryProvider),
    appointmentServiceRepository: ref.watch(
      appointmentServiceRepositoryProvider,
    ),
    scheduleValidator: ref.watch(appointmentScheduleValidatorProvider),
  );
});

final updateAppointmentControllerProvider =
    StateNotifierProvider<
      UpdateAppointmentController,
      AsyncValue<UpdatedAppointment?>
    >((ref) {
      final useCase = ref.watch(updateAppointmentUseCaseProvider);
      return UpdateAppointmentController(useCase);
    });

final cancelAppointmentUseCaseProvider = Provider<CancelAppointmentUseCase>((
  ref,
) {
  return CancelAppointmentUseCase(
    appointmentRepository: ref.watch(appointmentRepositoryProvider),
  );
});

final completeAppointmentUseCaseProvider = Provider<CompleteAppointmentUseCase>(
  (ref) {
    return CompleteAppointmentUseCase(
      appointmentRepository: ref.watch(appointmentRepositoryProvider),
      appointmentServiceRepository: ref.watch(
        appointmentServiceRepositoryProvider,
      ),
      serviceRepository: ref.watch(serviceRepositoryProvider),
      serviceRecordRepository: ref.watch(serviceRecordRepositoryProvider),
      serviceRecordServiceRepository: ref.watch(
        serviceRecordServiceRepositoryProvider,
      ),
      clientMemoryRepository: ref.watch(clientMemoryRepositoryProvider),
    );
  },
);

final appointmentMemoryUsageProvider = StateNotifierProvider.autoDispose
    .family<
      AppointmentMemoryUsageController,
      AppointmentMemoryUsageState,
      String
    >((ref, appointmentId) => AppointmentMemoryUsageController());

final completeAppointmentControllerProvider =
    StateNotifierProvider<
      CompleteAppointmentController,
      CompleteAppointmentState
    >((ref) {
      final useCase = ref.watch(completeAppointmentUseCaseProvider);
      return CompleteAppointmentController(useCase);
    });

final cancelAppointmentControllerProvider =
    StateNotifierProvider<CancelAppointmentController, CancelAppointmentState>((
      ref,
    ) {
      final useCase = ref.watch(cancelAppointmentUseCaseProvider);
      return CancelAppointmentController(useCase);
    });

final appointmentRepositoryProvider = Provider<AppointmentRepository>((ref) {
  final salonRepository = ref.watch(salonRepositoryProvider);
  return ParseAppointmentRepository(salonRepository);
});

final appointmentServiceRepositoryProvider =
    Provider<AppointmentServiceRepository>((ref) {
      final salonRepository = ref.watch(salonRepositoryProvider);
      return ParseAppointmentServiceRepository(salonRepository);
    });

final appointmentsByDayProvider =
    FutureProvider.family<List<Appointment>, AgendaDay>((ref, day) {
      final repository = ref.watch(appointmentRepositoryProvider);
      return repository.findByDay(day.toDateTime());
    });

final appointmentServicesByAppointmentProvider =
    FutureProvider.family<List<AppointmentService>, String>((
      ref,
      appointmentId,
    ) {
      final repository = ref.watch(appointmentServiceRepositoryProvider);
      return repository.findByAppointment(appointmentId);
    });
