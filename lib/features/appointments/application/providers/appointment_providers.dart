import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lacos_app/features/agenda/application/agenda_day.dart';
import 'package:lacos_app/features/appointments/application/controllers/create_appointment_controller.dart';
import 'package:lacos_app/features/appointments/application/models/created_appointment.dart';
import 'package:lacos_app/features/appointments/application/use_cases/create_appointment_use_case.dart';
import 'package:lacos_app/features/appointments/domain/entities/appointment.dart';
import 'package:lacos_app/features/appointments/domain/entities/appointment_service.dart';
import 'package:lacos_app/features/appointments/domain/repositories/appointment_repository.dart';
import 'package:lacos_app/features/appointments/domain/repositories/appointment_service_repository.dart';
import 'package:lacos_app/features/appointments/domain/services/availability_engine.dart';
import 'package:lacos_app/features/appointments/infrastructure/repositories/parse_appointment_repository.dart';
import 'package:lacos_app/features/appointments/infrastructure/repositories/parse_appointment_service_repository.dart';
import 'package:lacos_app/features/salon/application/providers/salon_providers.dart';

final availabilityEngineProvider = Provider<AvailabilityEngine>((ref) {
  return const AvailabilityEngine();
});

final createAppointmentUseCaseProvider = Provider<CreateAppointmentUseCase>((
  ref,
) {
  return CreateAppointmentUseCase(
    appointmentRepository: ref.watch(appointmentRepositoryProvider),
    appointmentServiceRepository: ref.watch(appointmentServiceRepositoryProvider),
    availabilityEngine: ref.watch(availabilityEngineProvider),
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
    FutureProvider.family<List<AppointmentService>, String>((ref, appointmentId) {
      final repository = ref.watch(appointmentServiceRepositoryProvider);
      return repository.findByAppointment(appointmentId);
    });
