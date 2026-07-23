import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lacos_app/features/appointments/application/loaders/appointment_details_loader.dart';
import 'package:lacos_app/features/appointments/application/models/appointment_details.dart';
import 'package:lacos_app/features/appointments/application/models/appointment_details_query.dart';
import 'package:lacos_app/features/appointments/application/providers/appointment_providers.dart';
import 'package:lacos_app/features/clients/application/providers/client_providers.dart';
import 'package:lacos_app/features/professional/application/providers/professional_providers.dart';
import 'package:lacos_app/features/services/application/providers/service_providers.dart';

final appointmentDetailsLoaderProvider = Provider<AppointmentDetailsLoader>((
  ref,
) {
  return AppointmentDetailsLoader(
    appointmentRepository: ref.watch(appointmentRepositoryProvider),
    clientRepository: ref.watch(clientRepositoryProvider),
    professionalRepository: ref.watch(professionalRepositoryProvider),
    appointmentServiceRepository: ref.watch(
      appointmentServiceRepositoryProvider,
    ),
    serviceRepository: ref.watch(serviceRepositoryProvider),
  );
});

final appointmentDetailsProvider = FutureProvider.autoDispose
    .family<AppointmentDetails, AppointmentDetailsQuery>((ref, query) {
      final loader = ref.watch(appointmentDetailsLoaderProvider);
      return loader.load(appointmentId: query.appointmentId, day: query.day);
    });
