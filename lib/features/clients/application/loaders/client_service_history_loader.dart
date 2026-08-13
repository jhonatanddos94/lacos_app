import 'package:lacos_app/core/config/app_strings.dart';
import 'package:lacos_app/core/formatters/appointment_display_formatters.dart';
import 'package:lacos_app/features/appointments/domain/entities/appointment.dart';
import 'package:lacos_app/features/appointments/domain/entities/appointment_service.dart';
import 'package:lacos_app/features/appointments/domain/repositories/appointment_repository.dart';
import 'package:lacos_app/features/appointments/domain/repositories/appointment_service_repository.dart';
import 'package:lacos_app/features/clients/application/models/client_service_history_item.dart';
import 'package:lacos_app/features/clients/application/models/client_service_history_kind.dart';
import 'package:lacos_app/features/clients/application/services/client_service_history_formatters.dart';
import 'package:lacos_app/features/professional/domain/entities/professional.dart';
import 'package:lacos_app/features/professional/domain/repositories/professional_repository.dart';
import 'package:lacos_app/features/service_records/domain/entities/service_record.dart';
import 'package:lacos_app/features/service_records/domain/entities/service_record_service.dart';
import 'package:lacos_app/features/service_records/domain/repositories/service_record_repository.dart';
import 'package:lacos_app/features/service_records/domain/repositories/service_record_service_repository.dart';
import 'package:lacos_app/features/services/domain/entities/service.dart';
import 'package:lacos_app/features/services/domain/repositories/service_repository.dart';

/// Carrega histórico unificado: ServiceRecords concluídos + Appointments cancelados.
///
/// Leitura completed: prioriza snapshots (`procedureSummary`, `finalAmount`);
/// catálogo atual só como fallback legado de nomes (nunca de preços).
/// Profissional: nome atual (decisão de produto). Cancelados: nomes via catálogo
/// (risco documentado — sem snapshot de nome nesta sprint).
class ClientServiceHistoryLoader {
  const ClientServiceHistoryLoader({
    required ServiceRecordRepository serviceRecordRepository,
    required ServiceRecordServiceRepository serviceRecordServiceRepository,
    required AppointmentRepository appointmentRepository,
    required AppointmentServiceRepository appointmentServiceRepository,
    required ProfessionalRepository professionalRepository,
    required ServiceRepository serviceRepository,
  }) : _serviceRecordRepository = serviceRecordRepository,
       _serviceRecordServiceRepository = serviceRecordServiceRepository,
       _appointmentRepository = appointmentRepository,
       _appointmentServiceRepository = appointmentServiceRepository,
       _professionalRepository = professionalRepository,
       _serviceRepository = serviceRepository;

  final ServiceRecordRepository _serviceRecordRepository;
  final ServiceRecordServiceRepository _serviceRecordServiceRepository;
  final AppointmentRepository _appointmentRepository;
  final AppointmentServiceRepository _appointmentServiceRepository;
  final ProfessionalRepository _professionalRepository;
  final ServiceRepository _serviceRepository;

  Future<List<ClientServiceHistoryItem>> load({required String clientId}) async {
    final trimmedClientId = clientId.trim();
    if (trimmedClientId.isEmpty) {
      return const [];
    }

    final (records, canceledAppointments) = await (
      _serviceRecordRepository.findByClientId(trimmedClientId),
      _appointmentRepository.findCanceledByClientId(trimmedClientId),
    ).wait;

    if (records.isEmpty && canceledAppointments.isEmpty) {
      return const [];
    }

    final appointmentIds = canceledAppointments
        .map((appointment) => appointment.id)
        .toList(growable: false);
    final recordIds = records.map((record) => record.id).toList(growable: false);

    final (professionals, catalogServices, recordServices, appointmentServices) =
        await (
          _professionalRepository.findAll(),
          _serviceRepository.findAll(),
          recordIds.isEmpty
              ? Future.value(const <ServiceRecordService>[])
              : _serviceRecordServiceRepository.findByServiceRecordIds(recordIds),
          appointmentIds.isEmpty
              ? Future.value(const <AppointmentService>[])
              : _appointmentServiceRepository.findByAppointments(appointmentIds),
        ).wait;

    final professionalById = {
      for (final professional in professionals) professional.id: professional,
    };
    final serviceById = {
      for (final service in catalogServices) service.id: service,
    };

    final servicesByRecordId = <String, List<ServiceRecordService>>{};
    for (final line in recordServices) {
      servicesByRecordId
          .putIfAbsent(line.serviceRecordId, () => <ServiceRecordService>[])
          .add(line);
    }

    final servicesByAppointmentId = <String, List<AppointmentService>>{};
    for (final line in appointmentServices) {
      servicesByAppointmentId
          .putIfAbsent(line.appointmentId, () => <AppointmentService>[])
          .add(line);
    }

    final items = <ClientServiceHistoryItem>[
      for (final record in records)
        _mapRecord(
          record: record,
          lines: servicesByRecordId[record.id] ?? const [],
          professionalById: professionalById,
          serviceById: serviceById,
        ),
      for (final appointment in canceledAppointments)
        _mapCanceledAppointment(
          appointment: appointment,
          lines: servicesByAppointmentId[appointment.id] ?? const [],
          professionalById: professionalById,
          serviceById: serviceById,
        ),
    ]..sort((a, b) => b.occurredAt.compareTo(a.occurredAt));

    return List<ClientServiceHistoryItem>.unmodifiable(items);
  }

  ClientServiceHistoryItem _mapRecord({
    required ServiceRecord record,
    required List<ServiceRecordService> lines,
    required Map<String, Professional> professionalById,
    required Map<String, Service> serviceById,
  }) {
    final serviceNames = _resolveRecordServiceNames(
      record: record,
      lines: lines,
      serviceById: serviceById,
    );

    return ClientServiceHistoryItem(
      uniqueId: 'sr:${record.id}',
      serviceRecordId: record.id,
      appointmentId: record.appointmentId,
      clientId: record.clientId,
      occurredAt: record.serviceDate ?? record.createdAt,
      kind: ClientServiceHistoryKind.completed,
      serviceNames: serviceNames,
      servicesSummary: ClientServiceHistoryServicesLabel.fromNames(serviceNames),
      professionalName: professionalById[record.professionalId]?.name,
      totalAmount: _resolveTotalAmount(record: record, lines: lines),
    );
  }

  ClientServiceHistoryItem _mapCanceledAppointment({
    required Appointment appointment,
    required List<AppointmentService> lines,
    required Map<String, Professional> professionalById,
    required Map<String, Service> serviceById,
  }) {
    final sortedLines = [...lines]
      ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
    final serviceNames = _resolveAppointmentServiceNames(
      lines: sortedLines,
      serviceById: serviceById,
    );

    return ClientServiceHistoryItem(
      uniqueId: 'appt:${appointment.id}',
      appointmentId: appointment.id,
      clientId: appointment.clientId,
      occurredAt: appointment.startAt,
      kind: ClientServiceHistoryKind.canceled,
      serviceNames: serviceNames,
      servicesSummary: ClientServiceHistoryServicesLabel.fromNames(serviceNames),
      professionalName: professionalById[appointment.professionalId]?.name,
      totalAmount: null,
      cancellationReasonPreview: _resolveCancellationPreview(appointment),
    );
  }

  String _resolveCancellationPreview(Appointment appointment) {
    final reason = appointment.cancellationReason?.trim();
    if (reason != null && reason.isNotEmpty) {
      return reason;
    }

    final byLabel = formatAppointmentCanceledByLabel(appointment.canceledBy);
    if (byLabel != null && byLabel.isNotEmpty) {
      return byLabel;
    }

    return AppStrings.appointmentCancellationReasonNotProvided;
  }

  List<String> _resolveRecordServiceNames({
    required ServiceRecord record,
    required List<ServiceRecordService> lines,
    required Map<String, Service> serviceById,
  }) {
    final summary = record.procedureSummary?.trim();
    if (summary != null && summary.isNotEmpty) {
      return summary
          .split(RegExp(r'\s*[+•,|/]\s*'))
          .map((part) => part.trim())
          .where((part) => part.isNotEmpty)
          .toList(growable: false);
    }

    final names = lines
        .map((line) => serviceById[line.serviceId]?.name)
        .whereType<String>()
        .map((name) => name.trim())
        .where((name) => name.isNotEmpty)
        .toList(growable: false);

    if (names.isNotEmpty) {
      return names;
    }

    if (lines.isEmpty) {
      return const [];
    }

    return [
      lines.length == 1
          ? AppStrings.clientNextAppointmentSingleService
          : AppStrings.clientNextAppointmentMultipleServices(lines.length),
    ];
  }

  List<String> _resolveAppointmentServiceNames({
    required List<AppointmentService> lines,
    required Map<String, Service> serviceById,
  }) {
    final names = lines
        .map((line) => serviceById[line.serviceId]?.name)
        .whereType<String>()
        .map((name) => name.trim())
        .where((name) => name.isNotEmpty)
        .toList(growable: false);

    if (names.isNotEmpty) {
      return names;
    }

    if (lines.isEmpty) {
      return const [];
    }

    return [
      lines.length == 1
          ? AppStrings.clientNextAppointmentSingleService
          : AppStrings.clientNextAppointmentMultipleServices(lines.length),
    ];
  }

  double? _resolveTotalAmount({
    required ServiceRecord record,
    required List<ServiceRecordService> lines,
  }) {
    if (record.finalAmount != null) {
      return record.finalAmount;
    }

    final lineAmounts = lines
        .map((line) => line.finalAmount)
        .whereType<double>()
        .toList(growable: false);

    if (lineAmounts.isEmpty) {
      return null;
    }

    if (lineAmounts.length != lines.length) {
      return null;
    }

    return lineAmounts.fold<double>(0, (sum, amount) => sum + amount);
  }
}
