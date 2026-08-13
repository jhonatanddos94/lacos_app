import 'package:lacos_app/features/appointments/application/models/complete_appointment_params.dart';
import 'package:lacos_app/features/appointments/domain/entities/appointment_service.dart';
import 'package:lacos_app/features/clients/application/services/client_service_history_formatters.dart';
import 'package:lacos_app/features/services/domain/entities/service.dart';

/// Monta snapshots históricos no momento da conclusão.
///
/// Não depende da UI: usa catálogo e [AppointmentService] (price/duration at booking)
/// disponíveis na conclusão.
class CompleteAppointmentHistoricalSnapshot {
  const CompleteAppointmentHistoricalSnapshot._();

  /// Enriquece params com `procedureSummary` e valores quando ausentes.
  static CompleteAppointmentParams enrich({
    required CompleteAppointmentParams params,
    required List<AppointmentService> appointmentServices,
    required List<Service> catalogServices,
  }) {
    final serviceById = {
      for (final service in catalogServices) service.id: service,
    };
    final bookingByServiceId = {
      for (final line in appointmentServices) line.serviceId: line,
    };

    final enrichedServices = params.services
        .map((service) {
          final booking = bookingByServiceId[service.serviceId];
          return CompletedServiceParams(
            serviceId: service.serviceId,
            finalAmount: service.finalAmount ?? booking?.priceAtBooking,
            notes: service.notes,
          );
        })
        .toList(growable: false);

    final procedureSummary =
        _normalizeOptionalText(params.procedureSummary) ??
        _buildProcedureSummary(
          serviceIds: enrichedServices.map((s) => s.serviceId),
          serviceById: serviceById,
        );

    final finalAmount =
        params.finalAmount ?? _sumLineAmounts(enrichedServices);

    return CompleteAppointmentParams(
      appointmentId: params.appointmentId,
      services: enrichedServices,
      procedureSummary: procedureSummary,
      technicalNotes: params.technicalNotes,
      result: params.result,
      productsUsed: params.productsUsed,
      finalAmount: finalAmount,
      mentionedMemoryIds: params.mentionedMemoryIds,
    );
  }

  static String? _buildProcedureSummary({
    required Iterable<String> serviceIds,
    required Map<String, Service> serviceById,
  }) {
    final names = serviceIds
        .map((id) => serviceById[id]?.name.trim())
        .whereType<String>()
        .where((name) => name.isNotEmpty)
        .toList(growable: false);

    if (names.isEmpty) {
      return null;
    }

    return ClientServiceHistoryServicesLabel.fromNames(names);
  }

  static double? _sumLineAmounts(List<CompletedServiceParams> services) {
    if (services.isEmpty) {
      return null;
    }

    final amounts = services
        .map((service) => service.finalAmount)
        .whereType<double>()
        .toList(growable: false);

    if (amounts.length != services.length) {
      return null;
    }

    return amounts.fold<double>(0, (sum, amount) => sum + amount);
  }

  static String? _normalizeOptionalText(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }
    return trimmed;
  }
}
