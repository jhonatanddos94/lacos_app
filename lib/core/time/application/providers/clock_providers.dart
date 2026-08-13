import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lacos_app/core/time/app_clock.dart';

final appClockProvider = Provider<AppClock>((ref) {
  return const SystemAppClock();
});
