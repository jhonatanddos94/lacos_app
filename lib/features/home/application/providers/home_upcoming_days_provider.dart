import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lacos_app/features/agenda/application/providers/calendar_today_providers.dart';
import 'package:lacos_app/features/appointments/application/providers/appointment_providers.dart';
import 'package:lacos_app/features/home/application/loaders/home_upcoming_days_loader.dart';
import 'package:lacos_app/features/home/application/models/home_upcoming_day.dart';

final homeUpcomingDaysLoaderProvider = Provider<HomeUpcomingDaysLoader>((ref) {
  return HomeUpcomingDaysLoader(
    appointmentRepository: ref.watch(appointmentRepositoryProvider),
  );
});

/// Carga futura resumida da Home (D+1..D+7), independente do bloco HOJE.
final homeUpcomingDaysProvider = FutureProvider<List<HomeUpcomingDay>>((ref) {
  final today = ref.watch(calendarTodayProvider).toDateTime();
  final loader = ref.watch(homeUpcomingDaysLoaderProvider);
  return loader.load(today: today);
});
