import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lacos_app/core/config/app_strings.dart';
import 'package:lacos_app/features/appointments/application/providers/appointment_providers.dart';
import 'package:lacos_app/features/appointments/application/use_cases/cancel_appointment_use_case.dart';
import 'package:lacos_app/features/appointments/domain/entities/appointment.dart';
import 'package:lacos_app/features/appointments/domain/enums/appointment_canceled_by.dart';
import 'package:lacos_app/features/appointments/domain/enums/appointment_status.dart';
import 'package:lacos_app/features/appointments/domain/repositories/appointment_repository.dart';
import 'package:lacos_app/features/appointments/presentation/dialogs/appointment_cancel_dialog.dart';

void main() {
  group('AppointmentCancelDialog', () {
    late _FakeAppointmentRepository repository;
    late CancelAppointmentUseCase useCase;

    setUp(() {
      repository = _FakeAppointmentRepository();
      useCase = CancelAppointmentUseCase(appointmentRepository: repository);
    });

    Future<void> pumpDialog(WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            cancelAppointmentUseCaseProvider.overrideWithValue(useCase),
          ],
          child: MaterialApp(
            home: Builder(
              builder: (context) {
                return Scaffold(
                  body: Center(
                    child: ElevatedButton(
                      onPressed: () {
                        showDialog<void>(
                          context: context,
                          builder: (context) => const AppointmentCancelDialog(
                            appointmentId: 'appointment-1',
                            clientName: 'Maria Silva',
                          ),
                        );
                      },
                      child: const Text('open'),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
    }

    testWidgets('exibe cliente e opções de quem cancelou', (tester) async {
      await pumpDialog(tester);

      expect(find.text(AppStrings.appointmentCancelTitle), findsOneWidget);
      expect(find.text('Maria Silva'), findsOneWidget);
      expect(find.text(AppStrings.appointmentCancelByClient), findsOneWidget);
      expect(find.text(AppStrings.appointmentCancelBySalon), findsOneWidget);
      expect(find.text(AppStrings.appointmentCancelMessage), findsOneWidget);
    });

    testWidgets('confirmar exige seleção Cliente/Salão', (tester) async {
      await pumpDialog(tester);

      final confirmButton = find.widgetWithText(
        FilledButton,
        AppStrings.appointmentCancelConfirm,
      );
      final button = tester.widget<FilledButton>(confirmButton);
      expect(button.onPressed, isNull);
    });

    testWidgets('envia motivo opcional e fecha com sucesso', (tester) async {
      repository.appointment = _appointment();
      await pumpDialog(tester);

      await tester.tap(find.text(AppStrings.appointmentCancelByClient));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Cliente desistiu');
      await tester.tap(find.text(AppStrings.appointmentCancelConfirm));
      await tester.pumpAndSettle();

      expect(find.byType(AppointmentCancelDialog), findsNothing);
      expect(repository.lastCancellationReason, 'Cliente desistiu');
      expect(repository.lastCanceledBy, AppointmentCanceledBy.client);
    });

    testWidgets('erro inline mantém dialog aberto', (tester) async {
      repository.appointment = _appointment(
        status: AppointmentStatus.completed,
      );
      await pumpDialog(tester);

      await tester.tap(find.text(AppStrings.appointmentCancelBySalon));
      await tester.pumpAndSettle();
      await tester.tap(find.text(AppStrings.appointmentCancelConfirm));
      await tester.pumpAndSettle();

      expect(find.byType(AppointmentCancelDialog), findsOneWidget);
      expect(
        find.text(AppStrings.appointmentCannotCancelCompleted),
        findsOneWidget,
      );
    });
  });
}

Appointment _appointment({
  AppointmentStatus status = AppointmentStatus.pending,
}) {
  final now = DateTime(2026, 7, 7, 10);

  return Appointment(
    id: 'appointment-1',
    salonId: 'salon-1',
    ownerId: 'owner-1',
    clientId: 'client-1',
    professionalId: 'professional-1',
    startAt: now,
    endAt: now.add(const Duration(hours: 1)),
    status: status,
    isActive: true,
    createdAt: now,
    updatedAt: now,
  );
}

class _FakeAppointmentRepository implements AppointmentRepository {
  Appointment? appointment;
  AppointmentCanceledBy? lastCanceledBy;
  String? lastCancellationReason;

  @override
  Future<Appointment> cancel({
    required String appointmentId,
    required AppointmentCanceledBy canceledBy,
    String? cancellationReason,
  }) async {
    lastCanceledBy = canceledBy;
    lastCancellationReason = cancellationReason;
    return _appointment(status: AppointmentStatus.canceled);
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
  Future<List<Appointment>> findByDay(DateTime day) {
    throw UnimplementedError();
  }

  @override
  Future<Set<DateTime>> findActiveAppointmentDaysInRange({
    required DateTime start,
    required DateTime end,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<Appointment> findById(String appointmentId) async {
    final current = appointment;
    if (current == null) {
      throw StateError('Agendamento não encontrado.');
    }
    return current;
  }

  @override
  Future<Appointment> update(Appointment appointment) {
    throw UnimplementedError();
  }
}
