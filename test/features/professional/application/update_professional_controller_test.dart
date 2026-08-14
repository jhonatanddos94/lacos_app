import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lacos_app/core/config/app_strings.dart';
import 'package:lacos_app/features/appointments/domain/entities/appointment.dart';
import 'package:lacos_app/features/appointments/domain/enums/appointment_status.dart';
import 'package:lacos_app/features/professional/application/controllers/update_professional_controller.dart';
import 'package:lacos_app/features/professional/domain/entities/professional.dart';

import '../../../helpers/in_memory_professional_repository.dart';

void main() {
  Professional professional({
    String id = 'pro-1',
    String name = 'Leticia',
    String? specialties = 'Cabeleireira',
    String? role = 'owner',
  }) {
    final now = DateTime(2026, 8, 13);
    return Professional(
      id: id,
      name: name,
      specialties: specialties,
      role: role,
      isActive: true,
      createdAt: now,
      updatedAt: now,
    );
  }

  test('G/H/I: trim e persiste nome e especialidade', () async {
    final repository = InMemoryProfessionalRepository(current: professional());
    final controller = UpdateProfessionalController(repository);

    final updated = await controller.updateProfessional(
      professionalId: 'pro-1',
      name: '  Leticia Souza  ',
      specialties: '  Colorista  ',
    );

    expect(updated?.name, 'Leticia Souza');
    expect(updated?.specialties, 'Colorista');
    expect(repository.updateCalls, 1);
  });

  test('J: nome vazio bloqueia save', () async {
    final repository = InMemoryProfessionalRepository(current: professional());
    final controller = UpdateProfessionalController(repository);

    final updated = await controller.updateProfessional(
      professionalId: 'pro-1',
      name: '   ',
      specialties: 'Colorista',
    );

    expect(updated, isNull);
    expect(repository.updateCalls, 0);
    expect(controller.state.hasError, isTrue);
    expect(
      (controller.state.error as FormatException).message,
      AppStrings.professionalProfileNameRequired,
    );
  });

  test('K: loading impede segundo submit', () async {
    final repository = InMemoryProfessionalRepository(current: professional());
    final controller = UpdateProfessionalController(repository);
    controller.state = const AsyncLoading();

    final updated = await controller.updateProfessional(
      professionalId: 'pro-1',
      name: 'Ana',
    );

    expect(updated, isNull);
    expect(repository.updateCalls, 0);
  });

  test('M: erro desconhecido é sanitizado', () async {
    final repository = InMemoryProfessionalRepository(current: professional())
      ..updateError = Exception('ParseException boom token');
    final controller = UpdateProfessionalController(repository);

    final updated = await controller.updateProfessional(
      professionalId: 'pro-1',
      name: 'Ana',
    );

    expect(updated, isNull);
    expect(
      (controller.state.error as FormatException).message,
      AppStrings.professionalProfileUpdateError,
    );
    expect(
      (controller.state.error as FormatException).message.contains('token'),
      isFalse,
    );
  });

  test('Q/R: preserva id, role e isActive', () async {
    final repository = InMemoryProfessionalRepository(current: professional());
    final controller = UpdateProfessionalController(repository);

    final updated = await controller.updateProfessional(
      professionalId: 'pro-1',
      name: 'Leticia Souza',
      specialties: 'Colorista',
    );

    expect(updated?.id, 'pro-1');
    expect(updated?.role, 'owner');
    expect(updated?.isActive, isTrue);
    expect(updated?.createdAt, DateTime(2026, 8, 13));
  });

  test('não atualiza Professional de outro id', () async {
    final repository = InMemoryProfessionalRepository(current: professional());
    final controller = UpdateProfessionalController(repository);

    final updated = await controller.updateProfessional(
      professionalId: 'other-salon-pro',
      name: 'Ana',
    );

    expect(updated, isNull);
    expect(repository.current?.id, 'pro-1');
    expect(repository.current?.name, 'Leticia');
  });

  test('Z: rename não altera Appointment.professionalId', () async {
    final appointment = Appointment(
      id: 'appointment-1',
      salonId: 'salon-1',
      ownerId: 'owner-1',
      clientId: 'client-1',
      professionalId: 'pro-1',
      startAt: DateTime(2026, 8, 13, 14),
      endAt: DateTime(2026, 8, 13, 15),
      status: AppointmentStatus.pending,
      isActive: true,
      createdAt: DateTime(2026, 8, 13),
      updatedAt: DateTime(2026, 8, 13),
    );
    final repository = InMemoryProfessionalRepository(current: professional());
    final controller = UpdateProfessionalController(repository);

    await controller.updateProfessional(
      professionalId: 'pro-1',
      name: 'Leticia Souza',
    );

    expect(appointment.professionalId, 'pro-1');
    expect(repository.current?.id, 'pro-1');
    expect(repository.current?.name, 'Leticia Souza');
  });
}
