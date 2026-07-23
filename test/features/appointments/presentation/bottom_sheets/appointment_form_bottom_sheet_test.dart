import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lacos_app/core/config/app_strings.dart';
import 'package:lacos_app/core/formatters/appointment_display_formatters.dart';
import 'package:lacos_app/features/appointments/application/models/appointment_details.dart';
import 'package:lacos_app/features/appointments/application/providers/appointment_providers.dart';
import 'package:lacos_app/features/appointments/application/models/updated_appointment.dart';
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
import 'package:lacos_app/features/clients/domain/entities/client.dart';
import 'package:lacos_app/features/professional/domain/entities/professional.dart';
import 'package:lacos_app/features/services/domain/entities/service.dart';

void main() {
  group('AppointmentFormBottomSheet initialDate', () {
    late CreateAppointmentUseCase useCase;

    setUp(() {
      useCase = CreateAppointmentUseCase(
        appointmentRepository: _FakeAppointmentRepository(),
        appointmentServiceRepository: _FakeAppointmentServiceRepository(),
        availabilityEngine: const AvailabilityEngine(),
      );
    });

    Future<void> pumpForm(
      WidgetTester tester, {
      DateTime? initialDate,
      AppointmentFormMode mode = AppointmentFormMode.create,
      AppointmentDetails? initialData,
    }) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            createAppointmentUseCaseProvider.overrideWithValue(useCase),
            appointmentsByDayProvider.overrideWith(
              (ref, day) async => const [],
            ),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: SizedBox(
                height: 900,
                width: 420,
                child: AppointmentFormBottomSheet(
                  mode: mode,
                  initialDate: initialDate,
                  initialData: initialData,
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pump();
    }

    testWidgets('create com initialDate exibe a data selecionada', (
      WidgetTester tester,
    ) async {
      final initialDate = DateTime(2026, 7, 10);

      await pumpForm(tester, initialDate: initialDate);

      expect(
        find.text(formatAppointmentDateLabel(initialDate)),
        findsOneWidget,
      );
      expect(find.text(AppStrings.appointmentChooseDatePrompt), findsNothing);
    });

    testWidgets('create sem initialDate mantém prompt de data', (
      WidgetTester tester,
    ) async {
      await pumpForm(tester);

      expect(find.text(AppStrings.appointmentChooseDatePrompt), findsOneWidget);
    });

    testWidgets('edit ignora initialDate e exibe data do appointment', (
      WidgetTester tester,
    ) async {
      final appointmentDate = DateTime(2026, 7, 12, 14);
      final agendaDate = DateTime(2026, 7, 10);

      await pumpForm(
        tester,
        mode: AppointmentFormMode.edit,
        initialDate: agendaDate,
        initialData: _appointmentDetails(startAt: appointmentDate),
      );

      expect(
        find.text(formatAppointmentDateLabel(appointmentDate)),
        findsOneWidget,
      );
      expect(find.text(formatAppointmentDateLabel(agendaDate)), findsNothing);
    });
  });

  group('AppointmentFormBottomSheet edit reopen', () {
    late UpdateAppointmentUseCase updateUseCase;
    late _FakeUpdateAppointmentRepository updateRepository;

    setUp(() {
      updateRepository = _FakeUpdateAppointmentRepository();
      updateUseCase = UpdateAppointmentUseCase(
        appointmentRepository: updateRepository,
        appointmentServiceRepository: _FakeAppointmentServiceRepository(),
        availabilityEngine: const AvailabilityEngine(),
      );
    });

    List<Override> buildOverrides() => [
      updateAppointmentUseCaseProvider.overrideWithValue(updateUseCase),
      appointmentsByDayProvider.overrideWith((ref, day) async => const []),
    ];

    Future<void> mountEditForm(
      WidgetTester tester,
      AppointmentDetails details, {
      int formKey = 0,
    }) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: buildOverrides(),
          child: MaterialApp(
            home: Scaffold(
              body: SizedBox(
                height: 1200,
                width: 420,
                child: AppointmentFormBottomSheet(
                  key: ValueKey(formKey),
                  mode: AppointmentFormMode.edit,
                  initialData: details,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();
    }

    Future<void> unmountForm(WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: buildOverrides(),
          child: const MaterialApp(home: SizedBox.shrink()),
        ),
      );
      await tester.pump();
    }

    testWidgets('reabrir form edit não lança erro de modificação de provider', (
      WidgetTester tester,
    ) async {
      final details = _appointmentDetails(startAt: DateTime(2026, 7, 12, 14));

      await mountEditForm(tester, details, formKey: 1);
      expect(find.text('Maria Silva'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await unmountForm(tester);

      await mountEditForm(tester, details, formKey: 2);
      expect(find.text('Maria Silva'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('submit continua funcionando na segunda abertura', (
      WidgetTester tester,
    ) async {
      final details = _appointmentDetails(startAt: DateTime(2026, 7, 12, 14));
      updateRepository.appointment = details.appointment;
      updateRepository.dayAppointments = [details.appointment];

      UpdatedAppointment? savedResult;

      await tester.pumpWidget(
        ProviderScope(
          overrides: buildOverrides(),
          child: MaterialApp(
            home: _EditFormRouteHarness(
              details: details,
              onSaved: (result) => savedResult = result,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Abrir edição'));
      await tester.pump();
      await tester.pump();

      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Abrir edição'));
      await tester.pump();
      await tester.pump();

      await tester.ensureVisible(
        find.text(AppStrings.appointmentFormEditAction),
      );
      await tester.tap(find.text(AppStrings.appointmentFormEditAction));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(savedResult, isNotNull);
      expect(savedResult!.appointment.id, details.appointment.id);
    });
  });
}

class _EditFormRouteHarness extends StatelessWidget {
  const _EditFormRouteHarness({required this.details, required this.onSaved});

  final AppointmentDetails details;
  final ValueChanged<UpdatedAppointment?> onSaved;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: TextButton(
        onPressed: () async {
          final result = await Navigator.of(context).push<UpdatedAppointment>(
            MaterialPageRoute(
              builder: (context) => SizedBox(
                height: 1200,
                width: 420,
                child: AppointmentFormBottomSheet(
                  mode: AppointmentFormMode.edit,
                  initialData: details,
                ),
              ),
            ),
          );
          onSaved(result);
        },
        child: const Text('Abrir edição'),
      ),
    );
  }
}

AppointmentDetails _appointmentDetails({required DateTime startAt}) {
  final now = DateTime(2026, 7, 7, 10);
  final endAt = startAt.add(const Duration(hours: 1));

  return AppointmentDetails(
    appointment: Appointment(
      id: 'appointment-1',
      salonId: 'salon-1',
      ownerId: 'owner-1',
      clientId: 'client-1',
      professionalId: 'professional-1',
      startAt: startAt,
      endAt: endAt,
      status: AppointmentStatus.pending,
      isActive: true,
      createdAt: now,
      updatedAt: now,
    ),
    client: Client(
      id: 'client-1',
      name: 'Maria Silva',
      phone: '11999999999',
      isActive: true,
      createdAt: now,
      updatedAt: now,
    ),
    professional: Professional(
      id: 'professional-1',
      name: 'Ana Profissional',
      isActive: true,
      createdAt: now,
      updatedAt: now,
    ),
    services: [
      Service(
        id: 'service-1',
        name: 'Corte',
        durationMinutes: 60,
        price: 80,
        isActive: true,
        createdAt: now,
        updatedAt: now,
      ),
    ],
  );
}

class _FakeAppointmentRepository implements AppointmentRepository {
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
  Future<Appointment> create(Appointment appointment) {
    throw UnimplementedError();
  }

  @override
  Future<void> delete(String appointmentId) {
    throw UnimplementedError();
  }

  @override
  Future<List<Appointment>> findByDay(DateTime day) async => const [];

  @override
  Future<Set<DateTime>> findActiveAppointmentDaysInRange({
    required DateTime start,
    required DateTime end,
  }) async => const {};

  @override
  Future<Appointment> findById(String appointmentId) {
    throw UnimplementedError();
  }

  @override
  Future<Appointment> update(Appointment appointment) {
    throw UnimplementedError();
  }
}

class _FakeAppointmentServiceRepository
    implements AppointmentServiceRepository {
  @override
  Future<List<AppointmentService>> createMany({
    required String appointmentId,
    required List<AppointmentService> services,
  }) async {
    final now = DateTime(2026, 7, 7, 10);
    return services
        .map(
          (service) => AppointmentService(
            id: 'line-${service.displayOrder}',
            appointmentId: appointmentId,
            serviceId: service.serviceId,
            salonId: service.salonId,
            ownerId: service.ownerId,
            priceAtBooking: service.priceAtBooking,
            durationMinutesAtBooking: service.durationMinutesAtBooking,
            displayOrder: service.displayOrder,
            isActive: true,
            createdAt: now,
            updatedAt: now,
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<void> deleteByAppointment(String appointmentId) async {}

  @override
  Future<List<AppointmentService>> findByAppointment(String appointmentId) {
    return Future.value(const []);
  }

  @override
  Future<List<AppointmentService>> findByAppointments(
    List<String> appointmentIds,
  ) {
    return Future.value(const []);
  }
}

class _FakeUpdateAppointmentRepository implements AppointmentRepository {
  Appointment? appointment;
  List<Appointment> dayAppointments = const [];

  @override
  Future<Appointment> findById(String appointmentId) async => appointment!;

  @override
  Future<List<Appointment>> findByDay(DateTime day) async => dayAppointments;

  @override
  Future<Appointment> update(Appointment appointment) async {
    this.appointment = appointment;
    return appointment;
  }

  @override
  Future<Set<DateTime>> findActiveAppointmentDaysInRange({
    required DateTime start,
    required DateTime end,
  }) async => const {};

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
  Future<Appointment> create(Appointment appointment) {
    throw UnimplementedError();
  }

  @override
  Future<void> delete(String appointmentId) {
    throw UnimplementedError();
  }
}
