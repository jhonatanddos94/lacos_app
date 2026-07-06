import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lacos_app/features/appointments/domain/entities/appointment.dart';
import 'package:lacos_app/features/appointments/domain/entities/appointment_service.dart';
import 'package:lacos_app/features/appointments/domain/repositories/appointment_repository.dart';
import 'package:lacos_app/features/appointments/domain/repositories/appointment_service_repository.dart';
import 'package:lacos_app/features/appointments/infrastructure/repositories/parse_appointment_repository.dart';
import 'package:lacos_app/features/appointments/infrastructure/repositories/parse_appointment_service_repository.dart';
import 'package:lacos_app/features/salon/application/providers/salon_providers.dart';

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
    FutureProvider.family<List<Appointment>, DateTime>((ref, day) {
      final repository = ref.watch(appointmentRepositoryProvider);
      return repository.findByDay(day);
    });

final appointmentServicesByAppointmentProvider =
    FutureProvider.family<List<AppointmentService>, String>((ref, appointmentId) {
      final repository = ref.watch(appointmentServiceRepositoryProvider);
      return repository.findByAppointment(appointmentId);
    });
