import 'package:lacos_app/core/time/app_clock.dart';
import 'package:lacos_app/core/workspace/domain/entities/workspace.dart';
import 'package:lacos_app/features/agenda/application/models/agenda_appointment_display.dart';
import 'package:lacos_app/features/appointments/domain/enums/appointment_status.dart';
import 'package:lacos_app/features/auth/domain/entities/authenticated_user.dart';
import 'package:lacos_app/features/professional/domain/entities/professional.dart';
import 'package:lacos_app/features/salon/domain/entities/salon.dart';

class FakeAppClock implements AppClock {
  FakeAppClock(this._now);

  DateTime _now;

  @override
  DateTime now() => _now;

  void setNow(DateTime value) {
    _now = value;
  }
}

final homeTestNow = DateTime(2026, 8, 13, 14, 0);

Workspace homeTestWorkspace({
  String professionalName = 'Maria Santos',
  String salonName = 'Studio Aurora',
}) {
  return Workspace(
    user: const AuthenticatedUser(
      id: 'user-1',
      email: 'maria@lacos.app',
      isEmailVerified: true,
    ),
    salon: Salon(
      id: 'salon-1',
      name: salonName,
      responsibleName: professionalName,
      isActive: true,
      createdAt: homeTestNow,
      updatedAt: homeTestNow,
    ),
    professional: Professional(
      id: 'professional-1',
      name: professionalName,
      isActive: true,
      createdAt: homeTestNow,
      updatedAt: homeTestNow,
    ),
  );
}

AgendaAppointmentDisplay homeTestAppointment({
  required String id,
  required String clientName,
  required DateTime startAt,
  Duration duration = const Duration(hours: 1),
  AppointmentStatus status = AppointmentStatus.pending,
  String servicesSummary = 'Hidratação',
  String? clientPhotoUrl,
}) {
  return AgendaAppointmentDisplay(
    appointmentId: id,
    clientId: 'client-$id',
    clientName: clientName,
    clientPhotoUrl: clientPhotoUrl,
    servicesSummary: servicesSummary,
    startAt: startAt,
    endAt: startAt.add(duration),
    status: status,
  );
}
