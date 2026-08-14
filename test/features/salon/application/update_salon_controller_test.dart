import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lacos_app/core/config/app_strings.dart';
import 'package:lacos_app/core/config/app_validation_messages.dart';
import 'package:lacos_app/features/appointments/domain/entities/appointment.dart';
import 'package:lacos_app/features/appointments/domain/enums/appointment_status.dart';
import 'package:lacos_app/features/professional/domain/entities/professional.dart';
import 'package:lacos_app/features/salon/application/controllers/update_salon_controller.dart';
import 'package:lacos_app/features/salon/domain/entities/salon.dart';

import '../../../helpers/in_memory_salon_repository.dart';

void main() {
  final createdAt = DateTime(2026, 8, 13);

  Salon salon() => Salon(
    id: 'salon-1',
    name: 'Studio Aurora',
    responsibleName: 'Leticia',
    phone: '67999999999',
    address: 'Rua A, 10',
    city: 'Campo Grande',
    state: 'MS',
    isActive: true,
    createdAt: createdAt,
    updatedAt: createdAt,
  );

  test('F–I/N/P/Q: salva campos, trim e preserva identidade', () async {
    final repository = InMemorySalonRepository(current: salon());
    final controller = UpdateSalonController(repository);

    final updated = await controller.updateSalon(
      salonId: ' salon-1 ',
      name: '  Studio Leticia  ',
      phone: '(67) 98888-7777',
      address: '  Rua B, 20  ',
      city: '  Dourados ',
      stateCode: ' ms ',
    );

    expect(updated?.name, 'Studio Leticia');
    expect(updated?.phone, '67988887777');
    expect(updated?.address, 'Rua B, 20');
    expect(updated?.city, 'Dourados');
    expect(updated?.state, 'MS');
    expect(updated?.id, 'salon-1');
    expect(updated?.responsibleName, 'Leticia');
    expect(updated?.isActive, isTrue);
    expect(updated?.createdAt, createdAt);
    expect(repository.updateCalls, 1);
    expect(repository.createCalls, 0);
  });

  test('J: nome inválido bloqueia save', () async {
    final repository = InMemorySalonRepository(current: salon());
    final controller = UpdateSalonController(repository);

    final result = await controller.updateSalon(
      salonId: 'salon-1',
      name: '   ',
    );

    expect(result, isNull);
    expect(repository.updateCalls, 0);
    expect(
      (controller.state.error as FormatException).message,
      AppValidationMessages.salonNameRequired,
    );
  });

  test('K: loading bloqueia duplo submit', () async {
    final repository = InMemorySalonRepository(current: salon());
    final controller = UpdateSalonController(repository)
      ..state = const AsyncLoading();

    expect(
      await controller.updateSalon(salonId: 'salon-1', name: 'Novo'),
      isNull,
    );
    expect(repository.updateCalls, 0);
  });

  test('L/M: erro é sanitizado e permite retry', () async {
    final repository = InMemorySalonRepository(current: salon())
      ..updateError = Exception('ParseException secret-token');
    final controller = UpdateSalonController(repository);

    expect(
      await controller.updateSalon(salonId: 'salon-1', name: 'Novo'),
      isNull,
    );
    expect(
      (controller.state.error as FormatException).message,
      AppStrings.salonUpdateError,
    );

    repository.updateError = null;
    expect(
      await controller.updateSalon(salonId: 'salon-1', name: 'Novo'),
      isNotNull,
    );
  });

  test(
    'R/S/AB/AC: não altera Professional, Appointment ou outro Salon',
    () async {
      final professional = Professional(
        id: 'pro-1',
        name: 'Leticia',
        isActive: true,
        createdAt: createdAt,
        updatedAt: createdAt,
      );
      final appointment = Appointment(
        id: 'appointment-1',
        salonId: 'salon-1',
        ownerId: 'owner-1',
        clientId: 'client-1',
        professionalId: professional.id,
        startAt: DateTime(2026, 8, 14, 14),
        endAt: DateTime(2026, 8, 14, 15),
        status: AppointmentStatus.pending,
        isActive: true,
        createdAt: createdAt,
        updatedAt: createdAt,
      );
      final repository = InMemorySalonRepository(current: salon());
      final controller = UpdateSalonController(repository);

      expect(
        await controller.updateSalon(salonId: 'salon-alheio', name: 'Invasão'),
        isNull,
      );
      expect(repository.current?.name, 'Studio Aurora');
      expect(professional.name, 'Leticia');
      expect(appointment.salonId, 'salon-1');
      expect(appointment.professionalId, 'pro-1');
      expect(repository.createCalls, 0);
    },
  );
}
