import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lacos_app/core/config/app_strings.dart';
import 'package:lacos_app/features/appointments/application/models/appointment_details.dart';
import 'package:lacos_app/features/appointments/application/providers/appointment_details_providers.dart';
import 'package:lacos_app/features/appointments/domain/entities/appointment.dart';
import 'package:lacos_app/features/appointments/domain/enums/appointment_status.dart';
import 'package:lacos_app/features/appointments/presentation/bottom_sheets/appointment_details_bottom_sheet.dart';
import 'package:lacos_app/features/clients/domain/entities/client.dart';
import 'package:lacos_app/features/professional/domain/entities/professional.dart';
import 'package:lacos_app/features/services/domain/entities/service.dart';

void main() {
  group('AppointmentDetailsBottomSheet overdue', () {
    Future<void> pumpBottomSheet(
      WidgetTester tester, {
      required AppointmentDetails details,
    }) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appointmentDetailsProvider.overrideWith(
              (ref, query) async => details,
            ),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: AppointmentDetailsBottomSheet(
                appointmentId: details.appointment.id,
                day: details.appointment.startAt,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
    }

    testWidgets('mostra aviso operacional apenas para overdue', (tester) async {
      final now = DateTime.now();
      final overdueDetails = _details(
        startAt: now.subtract(const Duration(hours: 2)),
        endAt: now.subtract(const Duration(hours: 1)),
        status: AppointmentStatus.pending,
      );

      await pumpBottomSheet(tester, details: overdueDetails);

      expect(
        find.text(AppStrings.appointmentOperationalOverdueDetailsMessage),
        findsOneWidget,
      );
      expect(find.textContaining('há 1h'), findsOneWidget);
      expect(find.text('Pendente'), findsNothing);
      expect(
        find.text(AppStrings.appointmentOperationalStateOverdueLabel),
        findsOneWidget,
      );
    });

    testWidgets('não mostra aviso operacional para upcoming', (tester) async {
      final now = DateTime.now();
      final upcomingDetails = _details(
        startAt: now.add(const Duration(hours: 1)),
        endAt: now.add(const Duration(hours: 2)),
        status: AppointmentStatus.pending,
      );

      await pumpBottomSheet(tester, details: upcomingDetails);

      expect(
        find.text(AppStrings.appointmentOperationalOverdueDetailsMessage),
        findsNothing,
      );
    });
  });
}

AppointmentDetails _details({
  required DateTime startAt,
  required DateTime endAt,
  required AppointmentStatus status,
}) {
  final createdAt = DateTime(2026, 7, 8, 8);

  return AppointmentDetails(
    appointment: Appointment(
      id: 'appointment-1',
      salonId: 'salon-1',
      ownerId: 'owner-1',
      clientId: 'client-1',
      professionalId: 'professional-1',
      startAt: startAt,
      endAt: endAt,
      status: status,
      isActive: true,
      createdAt: createdAt,
      updatedAt: createdAt,
    ),
    client: Client(
      id: 'client-1',
      name: 'Maria Silva',
      phone: '11999999999',
      isActive: true,
      createdAt: createdAt,
      updatedAt: createdAt,
    ),
    professional: Professional(
      id: 'professional-1',
      name: 'Ana Profissional',
      isActive: true,
      createdAt: createdAt,
      updatedAt: createdAt,
    ),
    services: [
      Service(
        id: 'service-1',
        name: 'Corte',
        durationMinutes: 60,
        price: 80,
        isActive: true,
        createdAt: createdAt,
        updatedAt: createdAt,
      ),
    ],
  );
}
