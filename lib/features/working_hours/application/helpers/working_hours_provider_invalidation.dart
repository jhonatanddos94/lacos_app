import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lacos_app/features/working_hours/application/providers/working_hours_providers.dart';

void invalidateWorkingHoursSources(WidgetRef ref) {
  ref.invalidate(professionalWorkingHoursProvider);
  ref.invalidate(professionalWorkingHoursWeekProvider);
}
