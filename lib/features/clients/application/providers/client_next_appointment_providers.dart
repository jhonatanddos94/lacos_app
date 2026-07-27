import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lacos_app/features/appointments/application/providers/appointment_providers.dart';
import 'package:lacos_app/features/clients/application/loaders/client_next_appointment_loader.dart';
import 'package:lacos_app/features/clients/application/models/client_next_appointment_preview.dart';
import 'package:lacos_app/features/clients/application/providers/client_providers.dart';
import 'package:lacos_app/features/professional/application/providers/professional_providers.dart';
import 'package:lacos_app/features/services/application/providers/service_providers.dart';

final clientNextAppointmentLoaderProvider =
    Provider<ClientNextAppointmentLoader>((ref) {
      return ClientNextAppointmentLoader(
        appointmentRepository: ref.watch(appointmentRepositoryProvider),
        appointmentServiceRepository: ref.watch(
          appointmentServiceRepositoryProvider,
        ),
        clientRepository: ref.watch(clientRepositoryProvider),
        professionalRepository: ref.watch(professionalRepositoryProvider),
        serviceRepository: ref.watch(serviceRepositoryProvider),
      );
    });

final clientNextAppointmentProvider = FutureProvider.autoDispose
    .family<ClientNextAppointmentPreview?, String>((ref, clientId) {
      if (clientId.trim().isEmpty) {
        return Future.value(null);
      }

      final loader = ref.watch(clientNextAppointmentLoaderProvider);
      return loader.load(clientId: clientId, now: DateTime.now());
    });
