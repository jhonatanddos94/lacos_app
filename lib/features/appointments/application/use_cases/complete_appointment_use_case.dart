import 'package:flutter/foundation.dart';

import 'package:lacos_app/features/appointments/application/models/complete_appointment_params.dart';
import 'package:lacos_app/features/appointments/domain/entities/appointment.dart';
import 'package:lacos_app/features/appointments/domain/enums/appointment_status.dart';
import 'package:lacos_app/features/appointments/domain/exceptions/appointment_exceptions.dart';
import 'package:lacos_app/features/appointments/domain/repositories/appointment_repository.dart';
import 'package:lacos_app/features/service_records/domain/entities/service_record.dart';
import 'package:lacos_app/features/service_records/domain/entities/service_record_service.dart';
import 'package:lacos_app/features/service_records/domain/repositories/service_record_repository.dart';
import 'package:lacos_app/features/service_records/domain/repositories/service_record_service_repository.dart';

class CompleteAppointmentUseCase {
  const CompleteAppointmentUseCase({
    required AppointmentRepository appointmentRepository,
    required ServiceRecordRepository serviceRecordRepository,
    required ServiceRecordServiceRepository serviceRecordServiceRepository,
  }) : _appointmentRepository = appointmentRepository,
       _serviceRecordRepository = serviceRecordRepository,
       _serviceRecordServiceRepository = serviceRecordServiceRepository;

  final AppointmentRepository _appointmentRepository;
  final ServiceRecordRepository _serviceRecordRepository;
  final ServiceRecordServiceRepository _serviceRecordServiceRepository;

  Future<ServiceRecord> call(CompleteAppointmentParams params) async {
    debugPrint('[AppointmentComplete] usecase start');

    final appointment = await _findAppointment(params.appointmentId);
    final completedAppointment = await _resolveCompletedAppointment(
      appointment: appointment,
      appointmentId: params.appointmentId,
    );

    final existingRecord = await _serviceRecordRepository.findByAppointmentId(
      params.appointmentId,
    );
    if (existingRecord != null) {
      debugPrint('[AppointmentComplete] service record already exists');
      await _ensureServiceRecordServices(
        serviceRecord: existingRecord,
        params: params,
      );
      debugPrint('[AppointmentComplete] success');
      return existingRecord;
    }

    debugPrint('[AppointmentComplete] service record create start');
    final serviceRecordDraft = _buildServiceRecord(
      appointment: completedAppointment,
      params: params,
    );

    final createdServiceRecord = await _serviceRecordRepository.create(
      serviceRecordDraft,
      legacyPrimaryServiceId: _legacyPrimaryServiceId(params),
    );

    await _ensureServiceRecordServices(
      serviceRecord: createdServiceRecord,
      params: params,
    );

    debugPrint('[AppointmentComplete] success');
    return createdServiceRecord;
  }

  Future<Appointment> _resolveCompletedAppointment({
    required Appointment appointment,
    required String appointmentId,
  }) async {
    if (appointment.status == AppointmentStatus.completed) {
      return appointment;
    }

    if (!appointment.status.canBeCompleted) {
      throw const AppointmentCannotCompleteException();
    }

    // TODO:
    // Quando houver suporte transacional,
    // concluir Appointment e criar ServiceRecord
    // dentro de uma única transação.
    debugPrint('[AppointmentComplete] repository complete start');
    final completedAppointment = await _appointmentRepository.complete(
      appointmentId,
    );
    debugPrint('[AppointmentComplete] repository complete saved');
    return completedAppointment;
  }

  Future<void> _ensureServiceRecordServices({
    required ServiceRecord serviceRecord,
    required CompleteAppointmentParams params,
  }) async {
    final serviceRecordServices = _buildServiceRecordServices(
      serviceRecord: serviceRecord,
      params: params,
    );

    if (serviceRecordServices.isEmpty) {
      return;
    }

    debugPrint('[AppointmentComplete] service record services create start');
    await _serviceRecordServiceRepository.createMany(
      serviceRecordId: serviceRecord.id,
      services: serviceRecordServices,
    );
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
