enum AppointmentOperationalState {
  upcoming,
  current,
  overdue,
  completed,
  canceled;

  bool get isTerminal => switch (this) {
    AppointmentOperationalState.completed ||
    AppointmentOperationalState.canceled => true,
    _ => false,
  };

  int get agendaSortPriority => switch (this) {
    AppointmentOperationalState.overdue => 0,
    AppointmentOperationalState.current => 1,
    AppointmentOperationalState.upcoming => 2,
    AppointmentOperationalState.completed => 3,
    AppointmentOperationalState.canceled => 4,
  };
}
