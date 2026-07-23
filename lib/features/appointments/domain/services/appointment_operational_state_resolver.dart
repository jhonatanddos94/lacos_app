import 'package:lacos_app/features/appointments/domain/enums/appointment_operational_state.dart';
import 'package:lacos_app/features/appointments/domain/enums/appointment_status.dart';

class AppointmentOperationalStateResolver {
  const AppointmentOperationalStateResolver();

  AppointmentOperationalState resolve({
    required AppointmentStatus status,
    required DateTime startAt,
    required DateTime endAt,
    required DateTime now,
  }) {
    return switch (status) {
      AppointmentStatus.completed => AppointmentOperationalState.completed,
      AppointmentStatus.canceled => AppointmentOperationalState.canceled,
      AppointmentStatus.pending || AppointmentStatus.confirmed =>
        _resolveActiveState(
          startAt: startAt,
          endAt: endAt,
          now: now,
        ),
    };
  }

  AppointmentOperationalState _resolveActiveState({
    required DateTime startAt,
    required DateTime endAt,
    required DateTime now,
  }) {
    if (now.isBefore(startAt)) {
      return AppointmentOperationalState.upcoming;
    }

    if (now.isBefore(endAt)) {
      return AppointmentOperationalState.current;
    }

    return AppointmentOperationalState.overdue;
  }
}
