class AgendaOperationalSummary {
  const AgendaOperationalSummary({
    this.upcomingCount = 0,
    this.currentCount = 0,
    this.overdueCount = 0,
    this.completedCount = 0,
    this.canceledCount = 0,
  });

  final int upcomingCount;
  final int currentCount;
  final int overdueCount;
  final int completedCount;
  final int canceledCount;

  bool get isEmpty =>
      upcomingCount == 0 &&
      currentCount == 0 &&
      overdueCount == 0 &&
      completedCount == 0 &&
      canceledCount == 0;

  bool get hasActiveOperationalItems =>
      upcomingCount > 0 || currentCount > 0 || overdueCount > 0;
}
