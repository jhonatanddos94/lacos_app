import 'package:lacos_app/features/appointments/domain/enums/appointment_status.dart';
import 'package:lacos_app/features/clients/application/models/client_service_history_kind.dart';

/// Item de apresentação do histórico (não é entidade de domínio).
///
/// - [ClientServiceHistoryKind.completed] ← [ServiceRecord]
/// - [ClientServiceHistoryKind.canceled] ← [Appointment] cancelado
class ClientServiceHistoryItem {
  const ClientServiceHistoryItem({
    required this.uniqueId,
    required this.clientId,
    required this.occurredAt,
    required this.kind,
    required this.servicesSummary,
    required this.serviceNames,
    this.appointmentId,
    this.serviceRecordId,
    this.professionalName,
    this.totalAmount,
    this.cancellationReasonPreview,
  });

  /// Identificador estável na lista (`sr:<id>` ou `appt:<id>`).
  final String uniqueId;

  final String clientId;
  final String? appointmentId;
  final String? serviceRecordId;

  /// Data usada para ordenação/agrupamento.
  /// Completed: `serviceDate` (fallback `createdAt`).
  /// Canceled: `startAt` do agendamento original.
  final DateTime occurredAt;

  final ClientServiceHistoryKind kind;
  final String servicesSummary;
  final List<String> serviceNames;
  final String? professionalName;

  /// Valor cobrado/persistido — apenas completed. Cancelados omitem valor.
  final double? totalAmount;

  /// Preview discreto do motivo (cancelados).
  final String? cancellationReasonPreview;

  bool get canOpenDetails =>
      appointmentId != null && appointmentId!.trim().isNotEmpty;

  /// Status para o fluxo de detalhes da Agenda (sem misturar domínio).
  AppointmentStatus get openFlowStatus => switch (kind) {
    ClientServiceHistoryKind.completed => AppointmentStatus.completed,
    ClientServiceHistoryKind.canceled => AppointmentStatus.canceled,
  };
}
