import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lacos_app/core/config/app_strings.dart';
import 'package:lacos_app/features/appointments/application/models/appointment_details.dart';
import 'package:lacos_app/features/appointments/application/providers/appointment_providers.dart';
import 'package:lacos_app/features/appointments/application/use_cases/create_appointment_use_case.dart';
import 'package:lacos_app/features/appointments/application/use_cases/update_appointment_use_case.dart';
import 'package:lacos_app/features/appointments/domain/entities/appointment.dart';
import 'package:lacos_app/features/appointments/domain/entities/appointment_service.dart';
import 'package:lacos_app/features/appointments/domain/enums/appointment_canceled_by.dart';
import 'package:lacos_app/features/appointments/domain/enums/appointment_status.dart';
import 'package:lacos_app/features/appointments/domain/repositories/appointment_repository.dart';
import 'package:lacos_app/features/appointments/domain/repositories/appointment_service_repository.dart';
import 'package:lacos_app/features/appointments/domain/services/availability_engine.dart';
import 'package:lacos_app/features/appointments/presentation/appointment_form_mode.dart';
import 'package:lacos_app/features/appointments/presentation/bottom_sheets/appointment_form_bottom_sheet.dart';
import 'package:lacos_app/features/appointments/presentation/widgets/appointment_professional_section.dart';
import 'package:lacos_app/features/clients/domain/entities/client.dart';
import 'package:lacos_app/features/professional/application/providers/professional_providers.dart';
import 'package:lacos_app/features/professional/domain/entities/professional.dart';
import 'package:lacos_app/features/professional/domain/repositories/professional_repository.dart';
import 'package:lacos_app/features/services/application/providers/service_providers.dart';
import 'package:lacos_app/features/services/domain/entities/service.dart';
import 'package:lacos_app/shared/widgets/buttons/app_button.dart';

void main() {
  final leticia = _professional(id: 'pro-leticia', name: 'Leticia');
  final ana = _professional(id: 'pro-ana', name: 'Ana');
  final client = _client();
  final service = _service();
  final futureDay = DateTime(2026, 12, 1);

  Future<void> pumpForm(
    WidgetTester tester, {
    required List<Override> extraOverrides,
    AppointmentFormMode mode = AppointmentFormMode.create,
    AppointmentDetails? initialData,
    DateTime? initialDate,
    Client? initialClient,
  }) async {
    await tester.binding.setSurfaceSize(const Size(420, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          createAppointmentUseCaseProvider.overrideWithValue(
            CreateAppointmentUseCase(
              appointmentRepository: _FakeAppointmentRepository(),
              appointmentServiceRepository: _FakeAppointmentServiceRepository(),
              availabilityEngine: const AvailabilityEngine(),
            ),
          ),
          updateAppointmentUseCaseProvider.overrideWithValue(
            UpdateAppointmentUseCase(
              appointmentRepository: _FakeAppointmentRepository(),
              appointmentServiceRepository: _FakeAppointmentServiceRepository(),
              availabilityEngine: const AvailabilityEngine(),
            ),
          ),
          appointmentsByDayProvider.overrideWith((ref, day) async => const []),
          servicesProvider.overrideWith((ref) async => [service]),
          ...extraOverrides,
        ],
        child: MaterialApp(
          home: Scaffold(
            body: AppointmentFormBottomSheet(
              mode: mode,
              initialData: initialData,
              initialDate: initialDate,
              initialClient: initialClient ?? client,
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
  }

  testWidgets('A: create + 0 Professional bloqueia submit', (tester) async {
    await pumpForm(
      tester,
      extraOverrides: [
        professionalsProvider.overrideWith((ref) async => const []),
      ],
    );

    expect(find.byKey(AppointmentProfessionalSection.incompleteKey), findsOneWidget);
    expect(find.text(AppStrings.appointmentProfessionalNotConfigured), findsOneWidget);
    expect(find.text(AppStrings.professionalPickerNewProfessionalComingSoon), findsNothing);
    expect(
      tester
          .widget<AppButton>(
            find.widgetWithText(AppButton, AppStrings.appointmentFormCreateAction),
          )
          .onPressed,
      isNull,
    );
  });

  testWidgets('B/C/D/T: create + 1 Professional auto-select read-only sem picker', (
    tester,
  ) async {
    final repository = _CountingProfessionalRepository(professionals: [leticia]);

    await pumpForm(
      tester,
      extraOverrides: [
        professionalRepositoryProvider.overrideWithValue(repository),
      ],
    );

    expect(find.byKey(AppointmentProfessionalSection.readOnlyKey), findsOneWidget);
    expect(find.text('Leticia'), findsOneWidget);
    expect(find.byKey(AppointmentProfessionalSection.selectableKey), findsNothing);
    expect(find.text(AppStrings.appointmentChooseProfessionalPrompt), findsNothing);
    expect(find.text(AppStrings.professionalPickerTitle), findsNothing);
    expect(
      find.descendant(
        of: find.byKey(AppointmentProfessionalSection.readOnlyKey),
        matching: find.byIcon(Icons.chevron_right_rounded),
      ),
      findsNothing,
    );

    await tester.ensureVisible(find.text('Leticia'));
    await tester.tap(find.text('Leticia'));
    await tester.pump();
    expect(find.text(AppStrings.professionalPickerTitle), findsNothing);
    expect(repository.findAllCalls, 1);
  });

  testWidgets('E: 1 Professional calcula slots sem escolher profissional', (
    tester,
  ) async {
    await pumpForm(
      tester,
      initialDate: futureDay,
      extraOverrides: [
        professionalsProvider.overrideWith((ref) async => [leticia]),
      ],
    );

    await tester.ensureVisible(find.text(AppStrings.appointmentAddServicePrompt));
    await tester.tap(find.text(AppStrings.appointmentAddServicePrompt));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Corte'));
    await tester.pumpAndSettle();

    expect(find.text('09:00'), findsOneWidget);
    expect(find.text(AppStrings.professionalPickerTitle), findsNothing);
  });

  testWidgets('F/G: create + 2 Professionals não auto-seleciona e abre picker', (
    tester,
  ) async {
    await pumpForm(
      tester,
      extraOverrides: [
        professionalsProvider.overrideWith((ref) async => [leticia, ana]),
      ],
    );

    expect(find.text(AppStrings.appointmentChooseProfessionalPrompt), findsOneWidget);
    expect(find.text('Leticia'), findsNothing);
    expect(find.byKey(AppointmentProfessionalSection.selectableKey), findsOneWidget);
    expect(find.byKey(AppointmentProfessionalSection.readOnlyKey), findsNothing);

    final professionalPrompt = find.text(
      AppStrings.appointmentChooseProfessionalPrompt,
    );
    await tester.ensureVisible(professionalPrompt);
    await tester.tap(professionalPrompt);
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.professionalPickerTitle), findsOneWidget);
    expect(find.text('Leticia'), findsOneWidget);
    expect(find.text('Ana'), findsOneWidget);
  });

  testWidgets('H: 2 Professionals escolher uma funciona', (tester) async {
    await pumpForm(
      tester,
      extraOverrides: [
        professionalsProvider.overrideWith((ref) async => [leticia, ana]),
      ],
    );

    await tester.ensureVisible(
      find.text(AppStrings.appointmentChooseProfessionalPrompt),
    );
    await tester.tap(find.text(AppStrings.appointmentChooseProfessionalPrompt));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Ana'));
    await tester.tap(find.text('Ana'));
    await tester.pumpAndSettle();

    expect(find.text('Ana'), findsOneWidget);
    expect(find.text(AppStrings.professionalPickerTitle), findsNothing);
  });

  testWidgets('I: edit preserva Professional original', (tester) async {
    await pumpForm(
      tester,
      mode: AppointmentFormMode.edit,
      initialData: _details(professional: leticia, startAt: futureDay),
      extraOverrides: [
        professionalsProvider.overrideWith((ref) async => [leticia]),
      ],
    );

    expect(find.text('Leticia'), findsOneWidget);
    expect(find.byKey(AppointmentProfessionalSection.readOnlyKey), findsOneWidget);
  });

  testWidgets(
    'J: edit + 1 ativa diferente da histórica NÃO substitui professionalId',
    (tester) async {
      await pumpForm(
        tester,
        mode: AppointmentFormMode.edit,
        initialData: _details(professional: leticia, startAt: futureDay),
        extraOverrides: [
          professionalsProvider.overrideWith((ref) async => [ana]),
        ],
      );

      expect(find.text('Leticia'), findsOneWidget);
      expect(find.text('Ana'), findsNothing);
      expect(find.byKey(AppointmentProfessionalSection.readOnlyKey), findsOneWidget);
    },
  );

  testWidgets('K: provider loading não submete sem professionalId', (
    tester,
  ) async {
    await pumpForm(
      tester,
      extraOverrides: [
        professionalsProvider.overrideWith(
          (ref) => Completer<List<Professional>>().future,
        ),
      ],
    );

    expect(find.byKey(AppointmentProfessionalSection.loadingKey), findsOneWidget);
    expect(
      tester
          .widget<AppButton>(
            find.widgetWithText(AppButton, AppStrings.appointmentFormCreateAction),
          )
          .onPressed,
      isNull,
    );
  });

  testWidgets('L: provider error mostra erro local sem crash', (tester) async {
    await pumpForm(
      tester,
      extraOverrides: [
        professionalsProvider.overrideWith(
          (ref) async => throw const FormatException('parse boom token'),
        ),
      ],
    );

    expect(find.byKey(AppointmentProfessionalSection.errorKey), findsOneWidget);
    expect(find.text(AppStrings.appointmentProfessionalLoadError), findsWidgets);
    expect(find.textContaining('token'), findsNothing);
    expect(find.textContaining('parse boom'), findsNothing);
    expect(tester.takeException(), isNull);
    expect(
      tester
          .widget<AppButton>(
            find.widgetWithText(AppButton, AppStrings.appointmentFormCreateAction),
          )
          .onPressed,
      isNull,
    );
  });
}

Professional _professional({required String id, required String name}) {
  final now = DateTime(2026, 8, 13);
  return Professional(
    id: id,
    name: name,
    isActive: true,
    createdAt: now,
    updatedAt: now,
  );
}

Client _client() {
  final now = DateTime(2026, 8, 13);
  return Client(
    id: 'client-1',
    name: 'Maria Silva',
    phone: '11999999999',
    isActive: true,
    createdAt: now,
    updatedAt: now,
  );
}

Service _service() {
  final now = DateTime(2026, 8, 13);
  return Service(
    id: 'service-1',
    name: 'Corte',
    durationMinutes: 60,
    price: 80,
    isActive: true,
    createdAt: now,
    updatedAt: now,
  );
}

AppointmentDetails _details({
  required Professional professional,
  required DateTime startAt,
}) {
  final now = DateTime(2026, 8, 13);
  return AppointmentDetails(
    appointment: Appointment(
      id: 'appointment-1',
      salonId: 'salon-1',
      ownerId: 'owner-1',
      clientId: 'client-1',
      professionalId: professional.id,
      startAt: startAt,
      endAt: startAt.add(const Duration(hours: 1)),
      status: AppointmentStatus.pending,
      isActive: true,
      createdAt: now,
      updatedAt: now,
    ),
    client: _client(),
    professional: professional,
    services: [_service()],
  );
}

class _CountingProfessionalRepository implements ProfessionalRepository {
  _CountingProfessionalRepository({required this.professionals});

  final List<Professional> professionals;
  int findAllCalls = 0;

  @override
  Future<List<Professional>> findAll() async {
    findAllCalls++;
    return professionals;
  }

  @override
  Future<Professional> create({required String name, String? specialties}) {
    throw UnimplementedError();
  }

  @override
  Future<Professional> update({
    required String professionalId,
    required String name,
    String? specialties,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<Professional?> getCurrentProfessional() async =>
      professionals.length == 1 ? professionals.single : null;
}

class _FakeAppointmentRepository implements AppointmentRepository {
  @override
  Future<Appointment> create(Appointment appointment) async => appointment;

  @override
  Future<Appointment> update(Appointment appointment) async => appointment;

  @override
  Future<Appointment> cancel({
    required String appointmentId,
    required AppointmentCanceledBy canceledBy,
    String? cancellationReason,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<Appointment> complete(String appointmentId) {
    throw UnimplementedError();
  }

  @override
  Future<Appointment?> findNextByClientId(
    String clientId, {
    required DateTime now,
  }) async => null;

  @override
  Future<List<Appointment>> findCanceledByClientId(String clientId) async =>
      const [];

  @override
  Future<List<Appointment>> findByDay(DateTime day) async => const [];

  @override
  Future<List<Appointment>> findByDateRange({
    required DateTime startInclusive,
    required DateTime endExclusive,
    Iterable<AppointmentStatus>? statuses,
  }) async => const [];

  @override
  Future<Set<DateTime>> findActiveAppointmentDaysInRange({
    required DateTime start,
    required DateTime end,
  }) async => const {};

  @override
  Future<Appointment> findById(String appointmentId) {
    throw UnimplementedError();
  }
}

class _FakeAppointmentServiceRepository implements AppointmentServiceRepository {
  @override
  Future<List<AppointmentService>> createMany({
    required String appointmentId,
    required List<AppointmentService> services,
  }) async => services;

  @override
  Future<void> deleteByAppointment(String appointmentId) async {}

  @override
  Future<List<AppointmentService>> findByAppointment(String appointmentId) async =>
      const [];

  @override
  Future<List<AppointmentService>> findByAppointments(
    List<String> appointmentIds,
  ) async => const [];
}
