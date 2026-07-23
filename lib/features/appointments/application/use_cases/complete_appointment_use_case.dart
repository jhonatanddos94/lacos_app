import 'package:flutter/foundation.dart';

import 'package:lacos_app/features/appointments/application/models/complete_appointment_params.dart';
import 'package:lacos_app/features/appointments/domain/entities/appointment.dart';
import 'package:lacos_app/features/appointments/domain/enums/appointment_status.dart';
import 'package:lacos_app/features/appointments/domain/exceptions/appointment_exceptions.dart';
import 'package:lacos_app/features/appointments/domain/repositories/appointment_repository.dart';
import 'package:lacos_app/features/memories/domain/repositories/client_memory_repository.dart';
import 'package:lacos_app/features/service_records/domain/entities/service_record.dart';
import 'package:lacos_app/features/service_records/domain/entities/service_record_service.dart';
import 'package:lacos_app/features/service_records/domain/repositories/service_record_repository.dart';
import 'package:lacos_app/features/service_records/domain/repositories/service_record_service_repository.dart';

class CompleteAppointmentUseCase {
  const CompleteAppointmentUseCase({
    required AppointmentRepository appointmentRepository,
    required ServiceRecordRepository serviceRecordRepository,
    required ServiceRecordServiceRepository serviceRecordServiceRepository,
    required ClientMemoryRepository clientMemoryRepository,
  }) : _appointmentRepository = appointmentRepository,
       _serviceRecordRepository = serviceRecordRepository,
       _serviceRecordServiceRepository = serviceRecordServiceRepository,
       _clientMemoryRepository = clientMemoryRepository;

  final AppointmentRepository _appointmentRepository;
  final ServiceRecordRepository _serviceRecordRepository;
  final ServiceRecordServiceRepository _serviceRecordServiceRepository;
  final ClientMemoryRepository _clientMemoryRepository;

  Future<ServiceRecord> call(CompleteAppointmentParams params) async {
    debugPrint('[AppointmentComplete] usecase start');

    final appointment = await _findAppointment(params.appointmentId);
    _validateAppointmentForCompletion(appointment, params);

    final serviceRecord = await _resolveServiceRecord(
      appointment: appointment,
      params: params,
    );

    await _ensureServiceRecordServices(
      serviceRecord: serviceRecord,
      params: params,
    );

    await _completeAppointmentIfNeeded(
      appointment: appointment,
      appointmentId: params.appointmentId,
    );

    await _markMentionedMemories(params.mentionedMemoryIds);

    debugPrint('[AppointmentComplete] success');
    return serviceRecord;
  }

  void _validateAppointmentForCompletion(
    Appointment appointment,
    CompleteAppointmentParams params,
  ) {
    if (!appointment.isActive) {
      throw const AppointmentCannotCompleteException();
    }

    if (appointment.status == AppointmentStatus.canceled) {
      throw const AppointmentCannotCompleteException();
    }

    if (appointment.status != AppointmentStatus.completed &&
        !appointment.status.canBeCompleted) {
      throw const AppointmentCannotCompleteException();
    }

    if (appointment.clientId.trim().isEmpty ||
        appointment.professionalId.trim().isEmpty) {
      throw const AppointmentCannotCompleteException();
    }

    if (params.services.isEmpty) {
      throw const AppointmentCannotCompleteException();
    }

    for (final service in params.services) {
      if (service.serviceId.trim().isEmpty) {
        throw const AppointmentCannotCompleteException();
      }
    }
  }

  Future<ServiceRecord> _resolveServiceRecord({
    required Appointment appointment,
    required CompleteAppointmentParams params,
  }) async {
    final existingRecord = await _serviceRecordRepository.findByAppointmentId(
      appointment.id,
    );
    if (existingRecord != null) {
      debugPrint('[AppointmentComplete] service record already exists');
      return existingRecord;
    }

    debugPrint('[AppointmentComplete] service record create start');
    final serviceRecordDraft = _buildServiceRecord(
      appointment: appointment,
      params: params,
    );

    try {
      return await _serviceRecordRepository.create(
        serviceRecordDraft,
        legacyPrimaryServiceId: _legacyPrimaryServiceId(params),
      );
    } on FormatException {
      final recoveredRecord = await _serviceRecordRepository
          .findByAppointmentId(appointment.id);
      if (recoveredRecord != null) {
        debugPrint(
          '[AppointmentComplete] service record recovered after create',
        );
        return recoveredRecord;
      }
      rethrow;
    }
  }

  Future<void> _ensureServiceRecordServices({
    required ServiceRecord serviceRecord,
    required CompleteAppointmentParams params,
  }) async {
    final expectedServices = _buildServiceRecordServices(
      serviceRecord: serviceRecord,
      params: params,
    );

    if (expectedServices.isEmpty) {
      return;
    }

    final existingServices = await _serviceRecordServiceRepository
        .findByServiceRecord(serviceRecord.id);
    final existingServiceIds = existingServices
        .map((service) => service.serviceId)
        .toSet();

    final missingServices = expectedServices
        .where((service) => !existingServiceIds.contains(service.serviceId))
        .toList(growable: false);

    if (missingServices.isEmpty) {
      return;
    }

    debugPrint('[AppointmentComplete] service record services create start');
    await _serviceRecordServiceRepository.createMany(
      serviceRecordId: serviceRecord.id,
      services: missingServices,
    );
  }

  Future<void> _completeAppointmentIfNeeded({
    required Appointment appointment,
    required String appointmentId,
  }) async {
    if (appointment.status == AppointmentStatus.completed) {
      return;
    }

    if (!appointment.status.canBeCompleted) {
      throw const AppointmentCannotCompleteException();
    }

    // TODO:
    // Quando houver suporte transacional,
    // concluir Appointment e criar ServiceRecord
    // dentro de uma única transação.
    debugPrint('[AppointmentComplete] repository complete start');
    await _appointmentRepository.complete(appointmentId);
    debugPrint('[AppointmentComplete] repository complete saved');
  }

  Future<void> _markMentionedMemories(List<String> memoryIds) async {
    if (memoryIds.isEmpty) {
      return;
    }

    try {
      await _clientMemoryRepository.touchMentioned(memoryIds: memoryIds);
    } on Object catch (error) {
      debugPrint('[AppointmentComplete] touchMentioned failed: $error');
    }
  }

  Future<Appointment> _findAppointment(String appointmentId) async {
    try {
      return await _appointmentRepository.findById(appointmentId);
    } on StateError {
      throw const AppointmentNotFoundException();
    } on FormatException {
      throw const AppointmentNotFoundException();
    }
  }

  ServiceRecord _buildServiceRecord({
    required Appointment appointment,
    required CompleteAppointmentParams params,
  }) {
    final now = DateTime.now();

    return ServiceRecord(
      id: '',
      appointmentId: appointment.id,
      clientId: appointment.clientId,
      professionalId: appointment.professionalId,
      salonId: appointment.salonId,
      ownerId: appointment.ownerId,
      serviceDate: appointment.completedAt ?? now,
      procedureSummary: _normalizeOptionalText(params.procedureSummary),
      technicalNotes: _normalizeOptionalText(params.technicalNotes),
      result: _normalizeOptionalText(params.result),
      productsUsed: _normalizeOptionalText(params.productsUsed),
      finalAmount: params.finalAmount,
      isActive: true,
      createdAt: now,
      updatedAt: now,
    );
  }

  List<ServiceRecordService> _buildServiceRecordServices({
    required ServiceRecord serviceRecord,
    required CompleteAppointmentParams params,
  }) {
    final now = DateTime.now();

    return params.services
        .map(
          (service) => ServiceRecordService(
            id: '',
            serviceRecordId: serviceRecord.id,
            serviceId: service.serviceId,
            salonId: serviceRecord.salonId,
            ownerId: serviceRecord.ownerId,
            finalAmount: service.finalAmount,
            notes: _normalizeOptionalText(service.notes),
            isActive: true,
            createdAt: now,
            updatedAt: now,
          ),
        )
        .toList(growable: false);
  }

  String? _legacyPrimaryServiceId(CompleteAppointmentParams params) {
    if (params.services.isEmpty) {
      return null;
    }

    final serviceId = params.services.first.serviceId.trim();
    if (serviceId.isEmpty) {
      return null;
    }

    return serviceId;
  }

  String? _normalizeOptionalText(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }

    return trimmed;
  }
}
